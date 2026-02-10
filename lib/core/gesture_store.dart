import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/pose_utils.dart';

const _prefsKey = 'pose_gestures_v6_threshold';
const _presetCmdKey = 'preset_commands_map';
const _presetDurKey = 'preset_durations_map';
const _presetActiveKey = 'preset_active_map';
const _presetThrKey = 'preset_thresholds_map';

class PoseGesture {
  final String id;
  final String name;
  final String command;
  final int holdDuration;
  final bool isActive;
  final double threshold;
  final List<Offset> keypoints;
  final List<double>? angles;
  final String? thumbnailPath;
  final int timestamp;

  PoseGesture({
    required this.id,
    required this.name,
    required this.command,
    this.holdDuration = 1000,
    this.isActive = true,
    this.threshold = 0.25,
    required this.keypoints,
    this.angles,
    this.thumbnailPath,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'cmd': command,
        'dur': holdDuration,
        'active': isActive,
        'thr': threshold,
        'kps': keypoints.map((o) => {'x': o.dx, 'y': o.dy}).toList(),
        'ang': angles,
        'thumb': thumbnailPath,
        'ts': timestamp,
      };

  factory PoseGesture.fromMap(Map<String, dynamic> m) {
    List<Offset> pts = [];
    if (m['kps'] != null) {
      final rawList = m['kps'] as List;
      pts = rawList.map((e) {
        if (e is Map) {
          return Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble());
        } else if (e is List) {
          return Offset((e[0] as num).toDouble(), (e[1] as num).toDouble());
        }
        return Offset.zero;
      }).toList();
    }

    List<double>? loadedAngles;
    if (m['ang'] != null) {
      loadedAngles =
          (m['ang'] as List).cast<num>().map((e) => e.toDouble()).toList();
    }

    return PoseGesture(
      id: m['id'] as String,
      name: m['name'] as String? ?? "Unknown",
      command: m['cmd'] as String? ?? "CUSTOM",
      holdDuration: m['dur'] as int? ?? 1000,
      isActive: m['active'] as bool? ?? true,
      threshold: (m['thr'] as num?)?.toDouble() ?? 0.25,
      keypoints: pts,
      angles: loadedAngles,
      thumbnailPath: m['thumb'] as String?,
      timestamp: m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class GestureStore {
  static User? get _user => FirebaseAuth.instance.currentUser;

  static Future<List<PoseGesture>> loadAll() async {
    if (_user != null) {
      return _loadFromFirestore();
    } else {
      return _loadFromLocal();
    }
  }

  static Future<void> saveOne(PoseGesture g) async {
    if (_user != null) {
      await _saveToFirestore(g);
    } else {
      await _saveToLocal(g);
    }
  }

  static Future<void> delete(String id) async {
    if (_user != null) {
      await _deleteFromFirestore(id);
    } else {
      await _deleteFromLocal(id);
    }
  }

  // ---------------- Cloud Logic ----------------
  static CollectionReference get _userGesturesRef {
    if (_user == null) throw Exception("User not logged in");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('gestures');
  }

  static Future<List<PoseGesture>> _loadFromFirestore() async {
    try {
      final snapshot =
          await _userGesturesRef.orderBy('ts', descending: true).get();
      return snapshot.docs.map((doc) {
        return PoseGesture.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint("Firestore Load Error: $e");
      return [];
    }
  }

  static Future<void> _saveToFirestore(PoseGesture g) async {
    await _userGesturesRef.doc(g.id).set(g.toMap());
  }

  static Future<void> _deleteFromFirestore(String id) async {
    await _userGesturesRef.doc(id).delete();
  }

  // ---------------- Local Logic ----------------
  static Future<List<PoseGesture>> _loadFromLocal() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_prefsKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final out = list.map((m) => PoseGesture.fromMap(m)).toList();
      out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return out;
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveToLocal(PoseGesture g) async {
    final sp = await SharedPreferences.getInstance();
    final all = await _loadFromLocal();
    final i = all.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      all[i] = g;
    } else {
      all.add(g);
    }
    await sp.setString(
        _prefsKey, jsonEncode(all.map((e) => e.toMap()).toList()));
  }

  static Future<void> _deleteFromLocal(String id) async {
    final sp = await SharedPreferences.getInstance();
    final all = await _loadFromLocal();
    all.removeWhere((x) => x.id == id);
    await sp.setString(
        _prefsKey, jsonEncode(all.map((e) => e.toMap()).toList()));
  }

  static PoseGesture fromPoseForStore(
    Pose pose, {
    required String name,
    required String command,
    int holdDuration = 1000,
    double threshold = 0.25,
    String? thumbnailPath,
  }) {
    final rawPoints = poseToOffsets(pose);
    final normalized = normalizeByShoulder(rawPoints, pose.landmarks);
    final calculatedAngles = PoseUtils.getPoseAngles(pose.landmarks);

    return PoseGesture(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      command: command,
      holdDuration: holdDuration,
      threshold: threshold,
      isActive: true,
      keypoints: normalized,
      angles: calculatedAngles,
      thumbnailPath: thumbnailPath,
    );
  }

  // ==========================================
  // 👇 ส่วนนี้คือส่วนที่ "คงเดิม" (Preset Logic)
  // ==========================================

  static Future<String> getPresetCommand(String key, String defaultCmd) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetCmdKey);
    if (raw == null) return defaultCmd;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] ?? defaultCmd;
    } catch (_) {
      return defaultCmd;
    }
  }

  static Future<void> savePresetCommand(String key, String newCmd) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetCmdKey);
    Map<String, dynamic> map = {};
    if (raw != null)
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    map[key] = newCmd;
    await sp.setString(_presetCmdKey, jsonEncode(map));
  }

  static Future<int> getPresetDuration(String key, int defaultMs) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetDurKey);
    if (raw == null) return defaultMs;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] ?? defaultMs;
    } catch (_) {
      return defaultMs;
    }
  }

  static Future<void> savePresetDuration(String key, int newMs) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetDurKey);
    Map<String, dynamic> map = {};
    if (raw != null)
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    map[key] = newMs;
    await sp.setString(_presetDurKey, jsonEncode(map));
  }

  static Future<bool> getPresetActive(String key, bool defaultVal) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetActiveKey);
    if (raw == null) return defaultVal;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] ?? defaultVal;
    } catch (_) {
      return defaultVal;
    }
  }

  static Future<void> savePresetActive(String key, bool isActive) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetActiveKey);
    Map<String, dynamic> map = {};
    if (raw != null)
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    map[key] = isActive;
    await sp.setString(_presetActiveKey, jsonEncode(map));
  }

  static Future<double> getPresetThreshold(
      String key, double defaultVal) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetThrKey);
    if (raw == null) return defaultVal;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (map[key] as num?)?.toDouble() ?? defaultVal;
    } catch (_) {
      return defaultVal;
    }
  }

  static Future<void> savePresetThreshold(String key, double val) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetThrKey);
    Map<String, dynamic> map = {};
    if (raw != null)
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    map[key] = val;
    await sp.setString(_presetThrKey, jsonEncode(map));
  }

  // ---------------- Matching Logic (Hybrid) ----------------
  static ({PoseGesture? match, double score}) bestMatch(
    List<Offset> currentRaw,
    Map<PoseLandmarkType, PoseLandmark> currentLandmarks,
    List<PoseGesture> db, {
    // ❌ เอาค่า Default 0.4 ออกจากตรงนี้ เพราะเราจะคำนวณใหม่ข้างใน
    double? overrideMaxDiff,
  }) {
    if (db.isEmpty) return (match: null, score: double.infinity);

    final currentAngles = PoseUtils.getPoseAngles(currentLandmarks);

    PoseGesture? bestAngleMatch;
    double bestAngleScore = double.infinity;

    // 1. ลองเทียบด้วย Angles (แม่นยำกว่า)
    if (currentAngles.isNotEmpty) {
      for (final g in db) {
        if (!g.isActive || g.angles == null || g.angles!.isEmpty) continue;

        if (PoseUtils.isMatch(g.angles!, currentAngles, g.threshold)) {
          double totalErr = 0;
          for (int i = 0; i < currentAngles.length; i++) {
            totalErr += (currentAngles[i] - g.angles![i]).abs();
          }
          double score = totalErr / currentAngles.length;

          if (score < bestAngleScore) {
            bestAngleScore = score;
            bestAngleMatch = g;
          }
        }
      }
    }

    if (bestAngleMatch != null) {
      return (match: bestAngleMatch, score: bestAngleScore);
    }

    // 2. ถ้าไม่เจอ เทียบด้วย Points (Backup)
    final currentNorm = normalizeByShoulder(currentRaw, currentLandmarks);

    PoseGesture? best;
    double bestScore = double.infinity;
    final upperBodyIndices = [11, 12, 13, 14, 15, 16, 23, 24];

    for (final g in db) {
      if (!g.isActive) continue;

      double sumDist = 0;
      int count = 0;
      bool isReject = false;

      // 🔥 FIX: คำนวณเพดานการคัดออก (MaxDiff) ตาม Threshold ของท่านั้นๆ
      // สูตร: ยอมให้จุดเดียวเบี้ยวได้ไม่เกิน Threshold + 0.15 (เผื่อไว้นิดหน่อย)
      // แต่ต้องไม่น้อยกว่า 0.4 (ค่ามาตรฐาน)
      double dynamicMaxDiff = math.max(0.4, g.threshold + 0.15);

      for (final i in upperBodyIndices) {
        if (i < currentNorm.length && i < g.keypoints.length) {
          final p1 = currentNorm[i];
          final p2 = g.keypoints[i];
          if (p1 == Offset.zero || p2 == Offset.zero) continue;
          final dist = (p1 - p2).distance;

          // 🔥 ใช้ dynamicMaxDiff แทน 0.4
          if (dist > dynamicMaxDiff) {
            isReject = true;
            break;
          }
          sumDist += dist;
          count++;
        }
      }

      if (!isReject && count > 0) {
        final avgDist = sumDist / count;
        if (avgDist < g.threshold && avgDist < bestScore) {
          bestScore = avgDist;
          best = g;
        }
      }
    }
    return (match: best, score: bestScore);
  }
}

// ==========================================
// 👇 ส่วนนี้ก็ "คงเดิม" (Utilities)
// ==========================================

List<Offset> poseToOffsets(Pose pose) {
  final result = <Offset>[];
  for (final t in PoseLandmarkType.values) {
    final lm = pose.landmarks[t];
    result.add(
        lm != null ? Offset(lm.x.toDouble(), lm.y.toDouble()) : Offset.zero);
  }
  return result;
}

List<Offset> normalizeByShoulder(
    List<Offset> pts, Map<PoseLandmarkType, PoseLandmark> landmarks) {
  final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
  final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

  if (leftShoulder == null || rightShoulder == null) {
    return normalizeL2(pts);
  }

  final centerX = (leftShoulder.x + rightShoulder.x) / 2;
  final centerY = (leftShoulder.y + rightShoulder.y) / 2;

  double shoulderWidth = math.sqrt(
      math.pow(leftShoulder.x - rightShoulder.x, 2) +
          math.pow(leftShoulder.y - rightShoulder.y, 2));

  if (shoulderWidth < 10) shoulderWidth = 100;

  return pts.map((p) {
    if (p == Offset.zero) return p;
    return Offset(
        (p.dx - centerX) / shoulderWidth, (p.dy - centerY) / shoulderWidth);
  }).toList();
}

List<Offset> normalizeL2(List<Offset> pts) {
  if (pts.isEmpty) return pts;
  final mx = pts.fold<double>(0, (s, p) => s + p.dx) / pts.length;
  final my = pts.fold<double>(0, (s, p) => s + p.dy) / pts.length;
  final shifted = pts.map((p) => Offset(p.dx - mx, p.dy - my)).toList();
  final norm = math
      .sqrt(shifted.fold<double>(0, (s, p) => s + p.dx * p.dx + p.dy * p.dy));
  if (norm == 0) return shifted;
  return shifted.map((p) => Offset(p.dx / norm, p.dy / norm)).toList();
}
