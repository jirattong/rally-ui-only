import 'dart:async';
// import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Import Auth เพิ่ม
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Import Firestore เพิ่ม

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

  List<PoseGesture> _customGestures = [];

  final Map<String, String> _presetCmds = {};
  final Map<String, int> _presetDurs = {};
  final Map<String, bool> _presetActive = {};
  final Map<String, double> _presetThresholds = {};

  bool _ready = false;
  bool _streaming = false;
  int _camIndex = 0;
  bool _isBusy = false;

  String _debugInfo = "Stand in frame...";
  Color _debugColor = Colors.white;

  SwipeState _swipeState = SwipeState.idle;
  ActiveHand _swipeHand = ActiveHand.none;
  DateTime _lastStateTime = DateTime.now();
  String _swipeDirection = "";

  final int cooldownMs = 2000;
  final Map<String, int> _startAt = {};
  final Map<String, int> _cooldownUntil = {};

  List<double> _lastFrameAngles = [];
  bool _isStable = false;
  double _movementScore = 0.0;

  // 🔥 ตัวแปรสำหรับเก็บสถิติ (เพิ่มใหม่) 🔥
  DateTime? _sessionStartTime; // เวลาที่กดปุ่ม START
  int _commandCount = 0; // นับจำนวนคำสั่งที่ส่งไป

  @override
  void initState() {
    super.initState();
    _matchedName = null;
    _initAll();
    _loadData();
  }

  // ... (ฟังก์ชัน Load Data และ Init คงเดิม) ...
  Future<void> _loadData() async {
    _customGestures = await GestureStore.loadAll();

    final keys = [
      'SWIPE_RIGHT',
      'SWIPE_LEFT',
      'L_SWIPE_LEFT',
      'L_SWIPE_RIGHT',
      'RAISE_RIGHT',
      'RAISE_LEFT',
      'RAISE_BOTH'
    ];
    for (var k in keys) {
      _presetCmds[k] =
          await GestureStore.getPresetCommand(k, _getDefaultCmd(k));
      _presetDurs[k] = await GestureStore.getPresetDuration(k, 1000);
      _presetActive[k] = await GestureStore.getPresetActive(k, true);
      _presetThresholds[k] = await GestureStore.getPresetThreshold(k, 0.25);
    }
  }

  String _getDefaultCmd(String key) {
    switch (key) {
      case 'SWIPE_RIGHT':
        return 'NEXT';
      case 'SWIPE_LEFT':
        return 'PREV';
      case 'L_SWIPE_LEFT':
        return 'VOL_DOWN';
      case 'L_SWIPE_RIGHT':
        return 'VOL_UP';
      case 'RAISE_RIGHT':
        return 'ON';
      case 'RAISE_LEFT':
        return 'OFF';
      case 'RAISE_BOTH':
        return 'STOP';
      default:
        return 'CMD';
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
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _openCamera() async {
    await _cam?.dispose();
    await _poseService?.dispose();

    if (_cams.isEmpty) return;

    final camDesc = _cams[_camIndex];
    _cam = CameraController(
      camDesc,
      ResolutionPreset.low,
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
      // 🛑 กรณี: สั่งหยุด (STOP)
      setState(() => _streaming = false);
      await _cam!.stopImageStream();

      // 🔥 บันทึกข้อมูล Session ลง Firebase ทันทีที่หยุด
      await _saveSessionData();

      if (mounted) {
        setState(() {
          _poses = [];
          _matchedName = null;
          _isBusy = false;
          _debugInfo = "Stopped";
          _swipeState = SwipeState.idle;
          _swipeHand = ActiveHand.none;
        });
      }
      return;
    }

    try {
      // ▶️ กรณี: เริ่มทำงาน (START)
      setState(() => _streaming = true);

      // 🔥 เริ่มจับเวลา และ รีเซ็ตตัวนับคำสั่ง
      _sessionStartTime = DateTime.now();
      _commandCount = 0;

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

              if (_isStable) {
                _evaluateHoldGestures(pose);
              } else {
                _startAt.clear();
                if (_swipeState == SwipeState.idle) {
                  _debugInfo = "Move: Too fast";
                  _debugColor = Colors.grey;
                }
              }

              _checkForSwipe(pose);
            } else {
              _debugInfo = "No Person";
              _debugColor = Colors.red;
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

  // ... (ฟังก์ชัน Stability Check และ Banner คงเดิม) ...
  void _checkStability(Pose pose) {
    final currentAngles = PoseUtils.getPoseAngles(pose.landmarks);
    if (currentAngles.isEmpty) {
      _isStable = false;
      return;
    }
    if (_lastFrameAngles.isEmpty) {
      _lastFrameAngles = currentAngles;
      return;
    }
    double totalDiff = 0;
    for (int i = 0; i < currentAngles.length; i++) {
      totalDiff += (currentAngles[i] - _lastFrameAngles[i]).abs();
    }
    double avgDiff = totalDiff / currentAngles.length;
    _movementScore = avgDiff;
    _isStable = avgDiff < 3.0;
    _lastFrameAngles = currentAngles;
  }

  void _showBanner(String text) {
    final now = DateTime.now();
    if (now.difference(_lastShown).inMilliseconds > 1000) {
      setState(() {
        _matchedName = text;
      });
      _lastShown = now;
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _matchedName = null;
          });
      });
    }
  }

  void _sendIoTCommandStr(String command) {
    print("⚡ Sending to Firebase: $command");
    // ✅ ส่งไปที่ 'command' (ตามที่คุณเปลี่ยนชื่อใน Firebase)
    FirebaseDatabase.instance.ref().child('iot_device/command').set(command);

    // 🔥 นับจำนวนคำสั่งที่ส่งไป
    _commandCount++;
  }

  // ... (Swipe Logic คงเดิม) ...
  void _checkForSwipe(Pose pose) {
    final lm = pose.landmarks;
    final rWrist = lm[PoseLandmarkType.rightWrist];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final lWrist = lm[PoseLandmarkType.leftWrist];
    final lShoulder = lm[PoseLandmarkType.leftShoulder];

    if (rWrist == null ||
        rShoulder == null ||
        lWrist == null ||
        lShoulder == null) return;

    double shoulderWidth = (lShoulder.x - rShoulder.x).abs();
    if (shoulderWidth < 10) return;

    double rRatio = (rWrist.x - rShoulder.x) / shoulderWidth;
    double lRatio = (lWrist.x - lShoulder.x) / shoulderWidth;

    double verticalLimit = shoulderWidth * 0.6;
    bool rVerticalOK = (rWrist.y - rShoulder.y).abs() < verticalLimit;
    bool lVerticalOK = (lWrist.y - lShoulder.y).abs() < verticalLimit;

    bool r_FoldIn = rRatio > 0.8 && rVerticalOK;
    bool r_ExtendOut = rRatio < -0.9 && rVerticalOK;

    bool l_FoldIn = lRatio < -0.8 && lVerticalOK;
    bool l_ExtendOut = lRatio > 0.9 && lVerticalOK;

    final now = DateTime.now();
    int timeoutLimit = 1500;

    if (_swipeState != SwipeState.idle &&
        now.difference(_lastStateTime).inMilliseconds > timeoutLimit) {
      _swipeState = SwipeState.idle;
      _swipeHand = ActiveHand.none;
      _debugInfo = "Swipe Reset (Too slow)";
    }

    switch (_swipeState) {
      case SwipeState.idle:
        if ((_presetActive['SWIPE_RIGHT'] ?? true) && r_FoldIn) {
          _startSwipe(ActiveHand.right, "OUT", "Ready Swipe Right >");
        } else if ((_presetActive['SWIPE_LEFT'] ?? true) && r_ExtendOut) {
          _startSwipe(ActiveHand.right, "IN", "< Ready Swipe Left");
        } else if ((_presetActive['L_SWIPE_LEFT'] ?? true) && l_FoldIn) {
          _startSwipe(ActiveHand.left, "OUT", "< Ready L-Swipe Left");
        } else if ((_presetActive['L_SWIPE_RIGHT'] ?? true) && l_ExtendOut) {
          _startSwipe(ActiveHand.left, "IN", "Ready L-Swipe Right >");
        }
        break;

      case SwipeState.phase1:
        if (_swipeHand == ActiveHand.right) {
          if (rRatio > -0.3 && rRatio < 0.3) {
            _swipeState = SwipeState.phase2;
            _lastStateTime = now;
          }
        } else if (_swipeHand == ActiveHand.left) {
          if (lRatio > -0.3 && lRatio < 0.3) {
            _swipeState = SwipeState.phase2;
            _lastStateTime = now;
          }
        }
        break;

      case SwipeState.phase2:
        if (_swipeHand == ActiveHand.right) {
          if (_swipeDirection == "OUT" && r_ExtendOut) _trigger("SWIPE_RIGHT");
          if (_swipeDirection == "IN" && r_FoldIn) _trigger("SWIPE_LEFT");
        } else if (_swipeHand == ActiveHand.left) {
          if (_swipeDirection == "OUT" && l_ExtendOut) _trigger("L_SWIPE_LEFT");
          if (_swipeDirection == "IN" && l_FoldIn) _trigger("L_SWIPE_RIGHT");
        }
        break;
    }
  }

  void _startSwipe(ActiveHand hand, String dir, String debugText) {
    _swipeState = SwipeState.phase1;
    _swipeHand = hand;
    _swipeDirection = dir;
    _lastStateTime = DateTime.now();
    _debugInfo = debugText;
    _debugColor = Colors.orange;
  }

  void _trigger(String key) {
    final cmd = _presetCmds[key] ?? "CMD";
    _sendIoTCommandStr(cmd);
    _showBanner("$key ($cmd)");
    _swipeState = SwipeState.idle;
    _swipeHand = ActiveHand.none;
  }

  // ... (Evaluate Hold Gestures คงเดิม) ...
  void _evaluateHoldGestures(Pose pose) {
    if (_swipeState != SwipeState.idle) return;

    final currentAngles = PoseUtils.getPoseAngles(pose.landmarks);
    if (currentAngles.isEmpty) return;

    // Custom Gestures logic
    final rawPoints = poseToOffsets(pose);
    final matchResult = GestureStore.bestMatch(
      rawPoints,
      pose.landmarks,
      _customGestures,
    );

    if (matchResult.match != null) {
      final g = matchResult.match!;
      _checkHold("CUSTOM_${g.id}", true, g.command, g.holdDuration,
          "Match: ${g.name}");

      if (_swipeState == SwipeState.idle) {
        _debugInfo = "Hold: ${g.name}";
        _debugColor = Colors.purpleAccent;
      }
      return;
    }

    // Static Presets Logic
    final lm = pose.landmarks;
    if (!lm.containsKey(PoseLandmarkType.leftWrist) ||
        !lm.containsKey(PoseLandmarkType.rightWrist) ||
        !lm.containsKey(PoseLandmarkType.nose) ||
        !lm.containsKey(PoseLandmarkType.leftShoulder)) return;

    final rightWrist = lm[PoseLandmarkType.rightWrist]!;
    final leftWrist = lm[PoseLandmarkType.leftWrist]!;
    final nose = lm[PoseLandmarkType.nose]!;
    final shoulder = lm[PoseLandmarkType.rightShoulder]!;

    bool checkHeight(PoseLandmark wrist, String key) {
      double thr = _presetThresholds[key] ?? 0.25;
      double targetY = nose.y;

      if (thr <= 0.2) {
        if (lm.containsKey(PoseLandmarkType.rightEye)) {
          targetY = lm[PoseLandmarkType.rightEye]!.y;
        } else {
          targetY = nose.y - 40;
        }
      } else if (thr >= 0.4) {
        targetY = shoulder.y - 20;
      } else {
        targetY = nose.y;
      }
      return wrist.y < targetY;
    }

    bool isRightHigh = checkHeight(rightWrist, 'RAISE_RIGHT');
    bool isLeftHigh = checkHeight(leftWrist, 'RAISE_LEFT');
    bool isRightBoth = checkHeight(rightWrist, 'RAISE_BOTH');
    bool isLeftBoth = checkHeight(leftWrist, 'RAISE_BOTH');

    bool raiseBoth = isRightBoth && isLeftBoth;

    if ((_presetActive['RAISE_BOTH'] ?? true) && raiseBoth) {
      _checkHold(
          "PRESET_BOTH",
          true,
          _presetCmds['RAISE_BOTH'] ?? 'STOP',
          _presetDurs['RAISE_BOTH'] ?? 1000,
          "Both Hands (${_presetCmds['RAISE_BOTH']})");

      _debugInfo = "Raising BOTH";
      _debugColor = Colors.cyan;
      return;
    } else {
      _checkHold("PRESET_BOTH", false, "", 0, "");
    }

    if (_presetActive['RAISE_RIGHT'] ?? true) {
      _checkHold(
          "PRESET_ON",
          isRightHigh,
          _presetCmds['RAISE_RIGHT'] ?? 'ON',
          _presetDurs['RAISE_RIGHT'] ?? 1000,
          "Right Hand (${_presetCmds['RAISE_RIGHT']})");
    }

    if (_presetActive['RAISE_LEFT'] ?? true) {
      _checkHold(
          "PRESET_OFF",
          isLeftHigh,
          _presetCmds['RAISE_LEFT'] ?? 'OFF',
          _presetDurs['RAISE_LEFT'] ?? 1000,
          "Left Hand (${_presetCmds['RAISE_LEFT']})");
    }

    if (matchResult.match == null && _swipeState == SwipeState.idle) {
      if (isRightHigh) {
        _debugInfo = "Raising RIGHT";
        _debugColor = Colors.green;
      } else if (isLeftHigh) {
        _debugInfo = "Raising LEFT";
        _debugColor = Colors.green;
      } else {
        _debugInfo = "Stable (Waiting)";
        _debugColor = Colors.white;
      }
    }
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
        _sendIoTCommandStr(cmdToSend);
        _showBanner(bannerText);

        _cooldownUntil[uniqueId] = nowMs + cooldownMs;
        _startAt.remove(uniqueId);
      }
    } else {
      _startAt.remove(uniqueId);
    }
  }

  Future<void> _switchCamera() async {
    if (_cams.length < 2) return;
    final wasStreaming = _streaming;
    if (wasStreaming) {
      // ถ้าสตรีมอยู่ ต้องหยุดก่อน (ซึ่งมันจะเซฟ Session ให้อัตโนมัติในฟังก์ชัน _toggleStream)
      await _toggleStream();
    }
    _camIndex = (_camIndex + 1) % _cams.length;
    await _openCamera();

    if (mounted) setState(() {});
  }

  // 🔥 หัวใจสำคัญ: ฟังก์ชันบันทึกข้อมูล Session ลง Firestore 🔥
  Future<void> _saveSessionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionStartTime == null) return;

    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(_sessionStartTime!).inSeconds;

    // ถ้าเล่นน้อยกว่า 5 วินาที ไม่ต้องบันทึก (กันคนกดผิด)
    if (durationSeconds < 5) return;

    // 1. คำนวณเป็นนาที (สำหรับ Profile Stats)
    final double minutesPlayed = durationSeconds / 60.0;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // ✅ อัปเดต Stats รวม (บวกเพิ่มเข้าไป)
      await userRef.set({
        'stats': {
          'sessions': FieldValue.increment(1), // บวกจำนวนครั้ง +1
          'total_minutes': FieldValue.increment(minutesPlayed), // บวกเวลาเพิ่ม
        }
      }, SetOptions(merge: true));

      // ✅ สร้างประวัติใหม่ใน Sub-collection 'history'
      await userRef.collection('history').add({
        'started_at': _sessionStartTime,
        'ended_at': endTime,
        'duration_seconds': durationSeconds,
        'commands_count': _commandCount, // จำนวนคำสั่งที่ส่งไป
      });

      debugPrint(
          "✅ Session Saved: ${minutesPlayed.toStringAsFixed(1)} mins, $_commandCount commands");
    } catch (e) {
      debugPrint("❌ Error Saving Session: $e");
    }
  }

  @override
  void dispose() {
    // 🔥 ถ้ากด Back ออกหน้านี้โดยที่ยังสตรีมอยู่ ให้หยุดและบันทึกด้วย
    if (_streaming) {
      _saveSessionData();
    }
    _cam?.dispose();
    _poseService?.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (ส่วน UI เหมือนเดิมทุกประการ) ...
    // ก๊อปปี้ส่วน UI มาให้ครบเพื่อให้ไฟล์สมบูรณ์ครับ
    final controller = _cam;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Start Detect'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
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
                        Text(_debugInfo,
                            style: TextStyle(
                                color: _debugColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("Stable: ${_isStable ? 'YES' : 'NO'}",
                            style: TextStyle(
                                color: _isStable
                                    ? Colors.greenAccent
                                    : Colors.redAccent)),
                        Text("Score: ${_movementScore.toStringAsFixed(1)}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10)),
                        // โชว์จำนวนคำสั่งที่ส่งไป
                        if (_streaming && _sessionStartTime != null) ...[
                          const SizedBox(height: 4),
                          Text("Cmds: $_commandCount",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ]
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
      pose.landmarks.forEach((_, landmark) {
        double x = landmark.x * scaleX;
        double y = landmark.y * scaleY;

        if (isFrontCamera) {
          x = size.width - x;
        }

        canvas.drawCircle(Offset(x, y), 5, jointPaint);
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          double x1 = joint1.x * scaleX;
          double y1 = joint1.y * scaleY;
          double x2 = joint2.x * scaleX;
          double y2 = joint2.y * scaleY;

          if (isFrontCamera) {
            x1 = size.width - x1;
            x2 = size.width - x2;
          }

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintType);
        }
      }

      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, paint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, paint);
      paintLine(
          PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, paint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, paint);
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate._poses != _poses || oldDelegate.imageSize != imageSize;
  }
}
