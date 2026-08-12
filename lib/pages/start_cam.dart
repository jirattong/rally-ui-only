import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/pose_service.dart';
import '../core/gesture_store.dart';
import '../core/pose_utils.dart';

enum ActiveHand { none, right, left }

enum SwipeState { idle, phase1, phase2 }

class StartCamPage extends StatefulWidget {
  const StartCamPage({super.key});
  @override
  State<StartCamPage> createState() => _StartCamPageState();
}

class _StartCamPageState extends State<StartCamPage> {
  static const bg = Color(0xFFF9EFE6);

  List<CameraDescription> _cams = [];
  CameraController? _cam;
  PoseService? _poseService;

  List<Pose> _poses = [];
  String? _matchedName;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _bannerTimer;

  // รวมท่าทั้งหมดไว้ใช้กับ KNN
  List<PoseGesture> _allGestures = [];

  final Map<String, String> _presetCmds = {};
  final Map<String, int> _presetDurs = {};
  final Map<String, bool> _presetActive = {};
  final Map<String, double> _presetThresholds = {};

  bool _ready = false;
  bool _streaming = false;
  int _camIndex = 0;
  bool _isBusy = false;

  // UI Status
  String _statusMessage = "Stand in frame...";
  String _statusSubtext = "";
  Color _statusColor = Colors.white;

  // Swipe Variables
  SwipeState _swipeState = SwipeState.idle;
  ActiveHand _swipeHand = ActiveHand.none;
  DateTime _lastStateTime = DateTime.now();
  String _swipeDirection = "";

  DateTime _lastSwipeTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _readyHoldStart;

  final int cooldownMs = 2000;
  final Map<String, int> _startAt = {};
  final Map<String, int> _cooldownUntil = {};

  // Smoothing
  final List<Map<PoseLandmarkType, Offset>> _poseHistory = [];
  static const int _smoothWindow = 8;
  Map<PoseLandmarkType, Offset> _lastSmoothedPositions = {};

  bool _isStable = false;
  double _movementScore = 0.0;

  DateTime? _sessionStartTime;
  int _commandCount = 0;

  String _targetIp = "192.168.1.50";
  String _targetPort = "5000";

  final DatabaseReference _rtdbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _matchedName = null;
    _initAll();
    _loadData();
    _loadConnectionSettings();
  }

  Future<void> _loadConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetIp = prefs.getString('target_ip') ?? "192.168.1.50";
      _targetPort = prefs.getString('target_port') ?? "5000";
    });
  }

  Future<void> _loadData() async {
    final keys = [
      'SWIPE_RIGHT',
      'SWIPE_LEFT',
      'L_SWIPE_LEFT',
      'L_SWIPE_RIGHT',
      'RAISE_RIGHT',
      'RAISE_LEFT',
      'RAISE_BOTH'
    ];
    // โหลดค่า Settings ของแต่ละท่า (Command, Duration, Active, Threshold)
    for (var k in keys) {
      _presetCmds[k] = await GestureStore.getPresetCommand(k, k);
      _presetDurs[k] = await GestureStore.getPresetDuration(k, 1000);
      _presetActive[k] = await GestureStore.getPresetActive(k, true);
      _presetThresholds[k] = await GestureStore.getPresetThreshold(k, 0.25);
    }

    // โหลดท่า Custom และ Preset
    final customList = await GestureStore.loadAll();
    final presetList = GestureStore.getBuiltInPresets();

    final updatedPresets = <PoseGesture>[];
    for (var p in presetList) {
      String realCmd = p.command;
      bool isActive = true;
      int dur = 1000;
      double thr = p.threshold;

      // Map ค่าจาก Settings มาใส่ Preset ให้ KNN รู้จัก
      if (p.id == 'PRESET_RAISE_BOTH') {
        realCmd = _presetCmds['RAISE_BOTH'] ?? 'STOP';
        isActive = _presetActive['RAISE_BOTH'] ?? true;
        dur = _presetDurs['RAISE_BOTH'] ?? 1000;
        thr = _presetThresholds['RAISE_BOTH'] ?? 0.35;
      }
      if (p.id == 'PRESET_RAISE_RIGHT') {
        realCmd = _presetCmds['RAISE_RIGHT'] ?? 'RAISE_RIGHT';
        isActive = _presetActive['RAISE_RIGHT'] ?? true;
        dur = _presetDurs['RAISE_RIGHT'] ?? 1000;
        thr = _presetThresholds['RAISE_RIGHT'] ?? 0.35;
      }
      if (p.id == 'PRESET_RAISE_LEFT') {
        realCmd = _presetCmds['RAISE_LEFT'] ?? 'RAISE_LEFT';
        isActive = _presetActive['RAISE_LEFT'] ?? true;
        dur = _presetDurs['RAISE_LEFT'] ?? 1000;
        thr = _presetThresholds['RAISE_LEFT'] ?? 0.35;
      }

      updatedPresets.add(PoseGesture(
        id: p.id,
        name: p.name,
        command: realCmd,
        holdDuration: dur,
        isActive: isActive,
        threshold: thr, // ใช้ Threshold จาก Slider ที่โหลดมา
        keypoints: p.keypoints,
        angles: p.angles,
      ));
    }

    if (mounted) {
      setState(() {
        _allGestures = [...customList, ...updatedPresets];
      });
    }
  }

  Future<void> _initAll() async {
    await [Permission.camera].request();
    try {
      _cams = await availableCameras();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      return;
    }
    final backIdx =
        _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    _camIndex = backIdx >= 0 ? backIdx : 0;
    await _openCamera();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _openCamera() async {
    await _cam?.dispose();
    await _poseService?.dispose();
    if (_cams.isEmpty) return;

    _cam = CameraController(
      _cams[_camIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    try {
      await _cam!.initialize();
    } catch (e) {
      return;
    }

    _poseService = PoseService();
    await _poseService!.init(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    );
    _streaming = false;
    _isBusy = false;
  }

  InputImageRotation _rotationFor(CameraDescription d) {
    final rot = InputImageRotationValue.fromRawValue(d.sensorOrientation);
    return rot ?? InputImageRotation.rotation0deg;
  }

  Future<void> _toggleStream() async {
    if (_cam == null) return;
    if (_streaming) {
      setState(() => _streaming = false);
      await _cam!.stopImageStream();
      await _saveSessionData();
      if (mounted) {
        setState(() {
          _poses = [];
          _matchedName = null;
          _isBusy = false;
          _statusMessage = "Stopped";
          _statusSubtext = "";
          _swipeState = SwipeState.idle;
          _swipeHand = ActiveHand.none;
        });
      }
      return;
    }

    try {
      await _loadConnectionSettings();
      await _loadData();

      setState(() => _streaming = true);
      _sessionStartTime = DateTime.now();
      _commandCount = 0;
      _poseHistory.clear();
      _lastSmoothedPositions.clear();

      final rotation = _rotationFor(_cam!.description);
      await _cam!.startImageStream((image) async {
        if (_isBusy) return;
        _isBusy = true;
        try {
          final ps =
              await _poseService!.processCameraImage(image, rotation: rotation);
          if (!mounted || !_streaming) {
            _isBusy = false;
            return;
          }
          if (mounted) {
            _poses = ps;
            if (ps.isNotEmpty) {
              final pose = ps.first;
              _checkStability(pose);
              // เรียกใช้ KNN Logic
              _evaluateHoldGestures(pose);
              _checkForSwipe(pose);
            } else {
              _statusMessage = "No Person";
              _statusSubtext = "";
              _statusColor = Colors.red;
              _poseHistory.clear();
            }
            setState(() {});
          }
        } catch (e) {
          debugPrint("$e");
        } finally {
          _isBusy = false;
        }
      });
    } catch (e) {
      setState(() => _streaming = false);
    }
  }

  Map<PoseLandmarkType, Offset> _getSmoothedLandmarks(
      Map<PoseLandmarkType, Offset> current) {
    _poseHistory.add(current);
    if (_poseHistory.length > _smoothWindow) {
      _poseHistory.removeAt(0);
    }
    Map<PoseLandmarkType, Offset> smoothed = {};
    for (var type in current.keys) {
      double sumX = 0, sumY = 0;
      int count = 0;
      for (var frame in _poseHistory) {
        if (frame.containsKey(type)) {
          sumX += frame[type]!.dx;
          sumY += frame[type]!.dy;
          count++;
        }
      }
      if (count > 0) smoothed[type] = Offset(sumX / count, sumY / count);
    }
    return smoothed;
  }

  void _checkStability(Pose pose) {
    final List<PoseLandmarkType> targetLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];
    Map<PoseLandmarkType, Offset> rawPositions = {};
    for (var type in targetLandmarks) {
      final lm = pose.landmarks[type];
      if (lm != null) rawPositions[type] = Offset(lm.x, lm.y);
    }
    Map<PoseLandmarkType, Offset> currentSmoothed =
        _getSmoothedLandmarks(rawPositions);
    if (_lastSmoothedPositions.isEmpty) {
      _lastSmoothedPositions = currentSmoothed;
      return;
    }
    double totalDist = 0;
    int count = 0;
    for (var type in targetLandmarks) {
      if (currentSmoothed.containsKey(type) &&
          _lastSmoothedPositions.containsKey(type)) {
        totalDist +=
            (currentSmoothed[type]! - _lastSmoothedPositions[type]!).distance;
        count++;
      }
    }
    double avgDist = count > 0 ? totalDist / count : 0.0;
    _movementScore = avgDist;
    _isStable = avgDist < 5.0;
    _lastSmoothedPositions = currentSmoothed;
  }

  // ----------------------------------------------------------------------
  // [PURE KNN] Logic: ใช้เฉพาะ KNN
  // ----------------------------------------------------------------------
  void _evaluateHoldGestures(Pose pose) {
    if (DateTime.now().difference(_lastSwipeTime).inMilliseconds < 2000) return;
    if (_swipeState != SwipeState.idle) return;

    final rawPoints = poseToOffsets(pose);
    final currentLandmarks = pose.landmarks;

    // 1. เรียก KNN Matching (ใช้ Threshold จากที่โหลดมา)
    final matchResult =
        GestureStore.bestMatch(rawPoints, currentLandmarks, _allGestures);

    // 2. ถ้าเจอท่า (Error ต่ำกว่า Threshold)
    if (matchResult.match != null) {
      final g = matchResult.match!;

      // เช็ค Disable (Active Status)
      bool isActive = true;
      if (g.id.startsWith('PRESET_')) {
        String key = g.id.replaceFirst('PRESET_', '');
        isActive = _presetActive[key] ?? true;
      }

      // ถ้าปิดท่านี้อยู่ ให้ข้ามไปเลย (ไม่ทำอะไรต่อ)
      if (!isActive) {
        _startAt.remove("CUSTOM_${g.id}");
        _startAt.remove(g.id);
        // เคลียร์สถานะเป็นว่าง
        _statusMessage = "Scanning...";
        _statusSubtext = "Active: False";
        _statusColor = Colors.grey;
        return;
      }

      // ถ้าเปิดอยู่ -> แสดงชื่อท่า
      _statusMessage = g.name;
      _statusColor = Colors.greenAccent;
      _statusSubtext = _isStable
          ? "Holding... (Error: ${matchResult.score.toStringAsFixed(1)})"
          : "Stabilizing... (Move: ${_movementScore.toStringAsFixed(1)})";

      if (_isStable) {
        // ส่ง g.command ไปโชว์ใน Pop-up
        _checkHold(g.id, true, g.command, g.holdDuration, g.command);
      } else {
        _startAt.remove("CUSTOM_${g.id}");
        _startAt.remove(g.id);
      }
      return;
    }

    // 3. ถ้าไม่เจอท่าอะไรเลย (No Match)
    _statusMessage = _isStable ? "Scanning..." : "Moving...";
    _statusSubtext =
        _isStable ? "Ready" : "Score: ${_movementScore.toStringAsFixed(1)}";
    _statusColor = _isStable ? Colors.white : Colors.grey;
    _startAt.clear();
  }

  void _checkHold(String uniqueId, bool isDetected, String cmdToSend,
      int duration, String bannerText) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if ((_cooldownUntil[uniqueId] ?? 0) > nowMs) {
      _startAt.remove(uniqueId);
      return;
    }
    if (isDetected) {
      if (!_startAt.containsKey(uniqueId)) {
        _startAt[uniqueId] = nowMs;
      } else if (nowMs - _startAt[uniqueId]! >= duration) {
        // ส่ง command เป็น bannerText ไปแสดงผล
        _executeCommand(cmdToSend, displayText: bannerText);
        _cooldownUntil[uniqueId] = nowMs + cooldownMs;
        _startAt.remove(uniqueId);
      }
    } else {
      _startAt.remove(uniqueId);
    }
  }

  void _showBanner(String text) {
    final now = DateTime.now();
    if (now.difference(_lastShown).inMilliseconds > 1000) {
      setState(() => _matchedName = text);
      _lastShown = now;
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _matchedName = null);
      });
    }
  }

  Future<void> _executeCommand(String command, {String? displayText}) async {
    _commandCount++;
    _showBanner(displayText ?? command); // โชว์ Command สีเขียวกลางจอ
    print(
        " Command: $command (Show: ${displayText ?? command}) -> $_targetIp:$_targetPort");

    try {
      int port = int.tryParse(_targetPort) ?? 5000;
      Socket socket = await Socket.connect(_targetIp, port,
          timeout: const Duration(seconds: 1));
      socket.write(command);
      await socket.flush();
      await socket.close();
      print(" Sent TCP: $command");
    } catch (e) {
      print(" Socket Error: $e");
    }
    try {
      await _rtdbRef.child('iot_device').update({
        'command': command,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {}
  }

  void _checkForSwipe(Pose pose) {
    final lm = pose.landmarks;
    final rWrist = lm[PoseLandmarkType.rightWrist],
        rShoulder = lm[PoseLandmarkType.rightShoulder];
    final lWrist = lm[PoseLandmarkType.leftWrist],
        lShoulder = lm[PoseLandmarkType.leftShoulder];

    if (rWrist == null ||
        rShoulder == null ||
        lWrist == null ||
        lShoulder == null) return;
    double shoulderWidth = (lShoulder.x - rShoulder.x).abs();
    if (shoulderWidth < 10) return;

    double rRatio = (rWrist.x - rShoulder.x) / shoulderWidth;
    double lRatio = (lWrist.x - lShoulder.x) / shoulderWidth;
    double verticalLimit = shoulderWidth * 0.8;
    bool rVerticalOK = (rWrist.y - rShoulder.y).abs() < verticalLimit;
    bool lVerticalOK = (lWrist.y - lShoulder.y).abs() < verticalLimit;

    bool r_AtChest = rRatio > 0.3 && rVerticalOK,
        r_AtSide = rRatio < -0.8 && rVerticalOK;
    bool l_AtChest = lRatio < -0.3 && lVerticalOK,
        l_AtSide = lRatio > 0.8 && lVerticalOK;

    final now = DateTime.now();
    if (_swipeState != SwipeState.idle &&
        now.difference(_lastStateTime).inMilliseconds > 1500) {
      _swipeState = SwipeState.idle;
      _swipeHand = ActiveHand.none;
    }

    switch (_swipeState) {
      case SwipeState.idle:
        // เช็ค Disable ของท่าปัด
        bool canSwipeRight =
            r_AtChest && (_presetActive['SWIPE_RIGHT'] ?? true);
        bool canSwipeLeft = r_AtSide && (_presetActive['SWIPE_LEFT'] ?? true);
        bool canLSwipeLeft =
            l_AtChest && (_presetActive['L_SWIPE_LEFT'] ?? true);
        bool canLSwipeRight =
            l_AtSide && (_presetActive['L_SWIPE_RIGHT'] ?? true);

        if (canSwipeRight || canSwipeLeft || canLSwipeLeft || canLSwipeRight) {
          if (_readyHoldStart == null)
            _readyHoldStart = now;
          else if (now.difference(_readyHoldStart!).inMilliseconds > 200) {
            if (canSwipeRight)
              _startSwipe(ActiveHand.right, "OUT", "Right Ready (>>)");
            else if (canSwipeLeft)
              _startSwipe(ActiveHand.right, "IN", "Right Ready (<<)");
            else if (canLSwipeLeft)
              _startSwipe(ActiveHand.left, "OUT", "Left Ready (<<)");
            else if (canLSwipeRight)
              _startSwipe(ActiveHand.left, "IN", "Left Ready (>>)");
            _readyHoldStart = null;
          }
        } else
          _readyHoldStart = null;
        break;
      case SwipeState.phase1:
        if ((_swipeHand == ActiveHand.right && rRatio > -0.5 && rRatio < 0.5) ||
            (_swipeHand == ActiveHand.left && lRatio > -0.5 && lRatio < 0.5)) {
          _swipeState = SwipeState.phase2;
          _lastStateTime = now;
        }
        break;
      case SwipeState.phase2:
        if (_swipeHand == ActiveHand.right) {
          if (_swipeDirection == "OUT" && r_AtSide)
            _trigger("SWIPE_RIGHT");
          else if (_swipeDirection == "IN" && r_AtChest) _trigger("SWIPE_LEFT");
        } else if (_swipeHand == ActiveHand.left) {
          if (_swipeDirection == "OUT" && l_AtSide)
            _trigger("L_SWIPE_LEFT");
          else if (_swipeDirection == "IN" && l_AtChest)
            _trigger("L_SWIPE_RIGHT");
        }
        break;
    }
  }

  void _startSwipe(ActiveHand hand, String dir, String debugText) {
    _swipeState = SwipeState.phase1;
    _swipeHand = hand;
    _swipeDirection = dir;
    _lastStateTime = DateTime.now();
    _statusMessage = debugText;
    _statusSubtext = "Swipe in progress...";
    _statusColor = Colors.orangeAccent;
  }

  void _trigger(String key) {
    // ส่ง Command ไปโชว์
    final cmd = _presetCmds[key] ?? key;
    _executeCommand(cmd, displayText: cmd);
    _lastSwipeTime = DateTime.now();
    _swipeState = SwipeState.idle;
    _swipeHand = ActiveHand.none;
  }

  Future<void> _switchCamera() async {
    if (_cams.length < 2) return;
    if (_streaming) await _toggleStream();
    _camIndex = (_camIndex + 1) % _cams.length;
    await _openCamera();
    if (mounted) setState(() {});
  }

  Future<void> _saveSessionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionStartTime == null) return;
    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(_sessionStartTime!).inSeconds;
    if (durationSeconds < 5) return;
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'stats': {
          'sessions': FieldValue.increment(1),
          'total_minutes': FieldValue.increment(durationSeconds / 60.0),
        }
      }, SetOptions(merge: true));
      await userRef.collection('history').add({
        'started_at': _sessionStartTime,
        'ended_at': endTime,
        'duration': durationSeconds,
        'cmds': _commandCount,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_streaming) _saveSessionData();
    _cam?.dispose();
    _poseService?.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cam;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Start Detect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.black87),
            onPressed: _cams.length >= 2 ? _switchCamera : null,
          ),
        ],
      ),
      body: !_ready || controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller!),
                CustomPaint(
                  painter: PoseOverlayPainter(
                    _poses,
                    imageSize: controller.value.previewSize != null
                        ? Size(controller.value.previewSize!.height,
                            controller.value.previewSize!.width)
                        : null,
                    isFrontCamera: controller.description.lensDirection ==
                        CameraLensDirection.front,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("STATUS:",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(_statusMessage,
                            style: TextStyle(
                                color: _statusColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        if (_statusSubtext.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_statusSubtext,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_matchedName != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 50),
                          const SizedBox(height: 10),
                          Text("$_matchedName",
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _streaming ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _toggleStream,
                      child: Text(_streaming ? "STOP" : "START",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class PoseOverlayPainter extends CustomPainter {
  final List<Pose> _poses;
  final Size? imageSize;
  final bool isFrontCamera;
  PoseOverlayPainter(this._poses, {this.imageSize, this.isFrontCamera = false});
  @override
  void paint(Canvas canvas, Size size) {
    if (_poses.isEmpty || imageSize == null) return;
    final double scaleX = size.width / imageSize!.width;
    final double scaleY = size.height / imageSize!.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;
    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue;
    for (var pose in _poses) {
      pose.landmarks.forEach((_, lm) {
        double x = lm.x * scaleX;
        double y = lm.y * scaleY;
        if (isFrontCamera) x = size.width - x;
        canvas.drawCircle(Offset(x, y), 5, jointPaint);
      });
      void paintLine(PoseLandmarkType t1, PoseLandmarkType t2) {
        final j1 = pose.landmarks[t1];
        final j2 = pose.landmarks[t2];
        if (j1 != null && j2 != null) {
          double x1 = j1.x * scaleX;
          double y1 = j1.y * scaleY;
          double x2 = j2.x * scaleX;
          double y2 = j2.y * scaleY;
          if (isFrontCamera) {
            x1 = size.width - x1;
            x2 = size.width - x2;
          }
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }

      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter old) =>
      old._poses != _poses || old.imageSize != imageSize;
}
