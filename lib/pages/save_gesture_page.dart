import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Image, decodeImageFromList;
import 'dart:math' as math; // ✅ เพิ่ม Import นี้สำหรับการกลับด้านรูป

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/gesture_store.dart';
import '../core/pose_service.dart';

enum SaveMode { capture, upload }

class SaveGestureArgs {
  final SaveMode mode;
  const SaveGestureArgs({required this.mode});
}

class SaveGesturePage extends StatefulWidget {
  final SaveMode mode;
  const SaveGesturePage({super.key, required this.mode});

  static Widget fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is SaveGestureArgs) return SaveGesturePage(mode: args.mode);
    return const SaveGesturePage(mode: SaveMode.upload);
  }

  @override
  State<SaveGesturePage> createState() => _SaveGesturePageState();
}

class _SaveGesturePageState extends State<SaveGesturePage> {
  static const bg = Color(0xFFF9EFE6);

  final _nameCtrl = TextEditingController(text: '');
  final _cmdCtrl = TextEditingController(text: 'MY_COMMAND');

  PoseService? _poseSingle;
  File? _selectedImage;
  List<Pose> _poses = [];
  Size? _srcImageSize;

  List<CameraDescription> _cams = [];
  CameraController? _cam;
  int _camIndex = 0;
  bool _capturing = false;
  bool _ready = false;

  Timer? _timer;
  int _countdown = 3;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _initPoseAndCamera();
  }

  Future<void> _initPoseAndCamera() async {
    _poseSingle = PoseService();
    await _poseSingle!.init(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.single,
    );

    if (widget.mode == SaveMode.capture) {
      await _prepCamera();
    } else {
      _pick();
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _prepCamera() async {
    await [Permission.camera, Permission.photos, Permission.storage].request();
    try {
      _cams = await availableCameras();
      final frontIdx =
          _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _camIndex = frontIdx >= 0 ? frontIdx : 0;
      await _initCamController();
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _initCamController() async {
    if (_cams.isEmpty) return;
    _cam = CameraController(
      _cams[_camIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _cam!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cams.length < 2 || _cam == null) return;
    _camIndex = (_camIndex + 1) % _cams.length;
    await _cam!.dispose();
    await _initCamController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cam?.dispose();
    _poseSingle?.dispose();
    _nameCtrl.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSingleImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    try {
      final ps = await _poseSingle!.processImage(inputImage);
      if (!mounted) return;
      setState(() => _poses = ps);

      final bytes = await File(path).readAsBytes();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        _srcImageSize = Size(img.width.toDouble(), img.height.toDouble());
        img.dispose();
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint("Detect Error: $e");
    }
  }

  void _startTimerCapture() {
    if (_isCountingDown || _capturing) return;

    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _countdown--);

      if (_countdown <= 0) {
        timer.cancel();
        setState(() => _isCountingDown = false);
        _capture();
      }
    });
  }

  Future<void> _capture() async {
    if (_cam == null || !_cam!.value.isInitialized || _capturing) return;
    try {
      setState(() => _capturing = true);
      final img = await _cam!.takePicture();
      setState(() => _selectedImage = File(img.path));
      await _runSingleImage(img.path);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) {
      if (widget.mode == SaveMode.upload) Navigator.pop(context);
      return;
    }
    setState(() => _selectedImage = File(img.path));
    await _runSingleImage(img.path);
  }

  Future<void> _saveCurrentPoseGesture() async {
    if (_poses.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No person detected')));
      return;
    }

    final cmdText = _cmdCtrl.text.trim().isEmpty
        ? 'CUSTOM_CMD'
        : _cmdCtrl.text.trim().toUpperCase();
    final nameText =
        _nameCtrl.text.trim().isEmpty ? 'My Pose' : _nameCtrl.text.trim();

    final g = GestureStore.fromPoseForStore(
      _poses.first,
      name: nameText,
      command: cmdText,
      holdDuration: 1000,
      thumbnailPath: _selectedImage?.path,
    );

    await GestureStore.saveOne(g);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$nameText" (Cross-Device Ready!)')));
    Navigator.pop(context);
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFFFE9DA),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC9CED4))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC9CED4), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCapture = widget.mode == SaveMode.capture;
    final hasImage = _selectedImage != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(isCapture ? 'Capture Gesture' : 'Upload Gesture',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (isCapture && !hasImage && _cams.length >= 2)
            IconButton(
                icon: const Icon(Icons.cameraswitch_rounded,
                    color: Colors.black87),
                onPressed: _switchCamera),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(fit: StackFit.expand, children: [
                if (hasImage)
                  // 🔥🔥 แก้ไข: ใช้ Transform กลับด้านรูป ถ้าเป็นกล้องหน้า 🔥🔥
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(
                      isCapture &&
                              _cam != null &&
                              _cams[_camIndex].lensDirection ==
                                  CameraLensDirection.front
                          ? math.pi // กลับด้าน 180 องศา
                          : 0, // ไม่ต้องกลับด้าน
                    ),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(_selectedImage!, fit: BoxFit.cover),
                      CustomPaint(
                        painter: PoseOverlayImagePainter(
                          poses: _poses,
                          srcImageSize: _srcImageSize,
                        ),
                      ),
                    ]),
                  )
                else if (isCapture && _cam != null && _cam!.value.isInitialized)
                  CameraPreview(_cam!)
                else
                  Container(
                    color: const Color(0xFFE0D4C5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_search,
                            size: 80, color: Colors.black26),
                        SizedBox(height: 10),
                        Text("No image selected",
                            style: TextStyle(color: Colors.black38)),
                      ],
                    ),
                  ),

                // 🔥 เอา CustomPaint ตัวนอกออก เพราะย้ายไปอยู่ใน Transform แล้ว
                // เพื่อให้เส้น Skeleton ถูกกลับด้านไปพร้อมกับรูป

                if (_isCountingDown)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Text(
                        "$_countdown",
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black)
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_capturing && !_isCountingDown)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ]),
            ),
          ),

          const SizedBox(height: 14),

          // --- Input Section ---
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: _inputDecor('Name', Icons.tag_faces),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cmdCtrl,
                  decoration: _inputDecor('IoT Command', Icons.send),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // --- Buttons ---
          if (!hasImage) ...[
            if (isCapture)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _GradientButton(
                      icon: Icons.camera,
                      label: 'Capture',
                      onTap: _capture,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _LightButton(
                      icon: Icons.timer,
                      label: '3s',
                      onTap: _startTimerCapture,
                    ),
                  ),
                ],
              )
            else
              _LightButton(
                icon: Icons.photo_library,
                label: 'Select from Gallery',
                onTap: _pick,
              ),
          ] else ...[
            Row(children: [
              Expanded(
                child: _LightButton(
                  icon: isCapture ? Icons.refresh : Icons.image,
                  label: isCapture ? 'Retake' : 'Reselect',
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _poses = [];
                      _srcImageSize = null;
                    });
                    if (!isCapture) _pick();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAF66),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveCurrentPoseGesture,
                    child: const Text('Save',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ---------------- Helper Widgets ----------------

class _GradientButton extends StatelessWidget {
  const _GradientButton(
      {required this.label, required this.onTap, required this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A3D), Color(0xFFFFAF66)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 10),
            Text(label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton(
      {required this.label, required this.onTap, required this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFFFE0CC),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
          ]),
        ),
      ),
    );
  }
}

class PoseOverlayImagePainter extends CustomPainter {
  final List<Pose> poses;
  final Size? srcImageSize;

  PoseOverlayImagePainter({required this.poses, required this.srcImageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty || srcImageSize == null) return;

    final srcW = srcImageSize!.width;
    final srcH = srcImageSize!.height;

    final scale = (size.width / srcW)
                .clamp(0.0, double.infinity)
                .compareTo(size.height / srcH) <
            0
        ? (size.height / srcH)
        : (size.width / srcW);
    final drawW = srcW * scale;
    final drawH = srcH * scale;
    final dx = (size.width - drawW) / 2.0;
    final dy = (size.height - drawH) / 2.0;

    Offset map(double x, double y) => Offset(dx + x * scale, dy + y * scale);

    final joint = Paint()
      ..color = const Color(0xFF00FF4B)
      ..style = PaintingStyle.fill;
    final bone = Paint()
      ..color = const Color(0xFF00FF4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final p in poses) {
      final connections = [
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      ];

      for (final pair in connections) {
        if (p.landmarks[pair[0]] != null && p.landmarks[pair[1]] != null) {
          final lm1 = p.landmarks[pair[0]]!;
          final lm2 = p.landmarks[pair[1]]!;
          canvas.drawLine(map(lm1.x, lm1.y), map(lm2.x, lm2.y), bone);
        }
      }

      for (final lm in p.landmarks.values) {
        canvas.drawCircle(map(lm.x, lm.y), 5, joint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayImagePainter oldDelegate) =>
      oldDelegate.poses != poses || oldDelegate.srcImageSize != srcImageSize;
}
