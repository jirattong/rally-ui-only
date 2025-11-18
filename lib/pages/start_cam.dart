import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class StartCamPage extends StatefulWidget {
  const StartCamPage({super.key});
  @override
  State<StartCamPage> createState() => _StartCamPageState();
}

class _StartCamPageState extends State<StartCamPage> {
  static const bg = Color(0xFFF9EFE6);

  CameraController? _cam;
  Future<void>? _initCam;
  List<CameraDescription> _cams = [];
  int _camIndex = 0;
  bool _asking = false;

  bool _running = false;
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  int _sent = 0;
  String _motion = 'Smash Ready';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _asking = true);

    await [Permission.camera].request();

    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) throw 'No camera found';
      final back =
          _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _camIndex = back != -1 ? back : 0;

      _cam = CameraController(_cams[_camIndex], ResolutionPreset.medium);
      _initCam = _cam!.initialize();
      await _initCam;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เปิดกล้องไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อุปกรณ์นี้มีกล้องเดียว')));
      return;
    }
    setState(() => _asking = true);
    try {
      await _cam?.dispose();
      _camIndex = (_camIndex + 1) % _cams.length;
      _cam = CameraController(_cams[_camIndex], ResolutionPreset.medium);
      _initCam = _cam!.initialize();
      await _initCam;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('สลับกล้องไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  void dispose() {
    if (_running) _timer.cancel();
    _cam?.dispose();
    super.dispose();
  }

  void _start() {
    if (_cam == null || !_cam!.value.isInitialized) return;
    if (_running) return;
    setState(() {
      _running = true;
      _elapsed = Duration.zero;
      _sent = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _sent += 1;
      });
    });
  }

  void _stop() {
    if (!_running) return;
    _timer.cancel();
    setState(() => _running = false);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h hr $m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Start / Detect',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            tooltip: 'สลับกล้อง',
            onPressed: (_cam != null) ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFFFBD1B3),
                  child: _asking
                      ? const Center(child: CircularProgressIndicator())
                      : (_cam != null && _cam!.value.isInitialized)
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cam!),
                                if (_running)
                                  CustomPaint(painter: _SkeletonPainter()),
                              ],
                            )
                          : const Center(
                              child: Icon(Icons.photo_camera_outlined,
                                  size: 80, color: Colors.black38)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_running) ...[
                  Text('Motion : $_motion',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Time : ${_fmt(_elapsed)}'),
                  Text('Sent device : $_sent time'),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _running ? _stop : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: _running
                          ? const Color(0xFFFFCCB8)
                          : const Color(0xFFFF8A3D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(_running ? 'STOP' : 'START',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bone = Paint()
      ..color = const Color(0xFF32D74B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final joint = Paint()..color = const Color(0xFF32D74B);

    final norm = <String, Offset>{
      'head': const Offset(.5, .2),
      'neck': const Offset(.5, .28),
      'l_shoulder': const Offset(.42, .32),
      'r_shoulder': const Offset(.58, .32),
      'l_elbow': const Offset(.36, .42),
      'r_elbow': const Offset(.68, .42),
      'l_wrist': const Offset(.34, .54),
      'r_wrist': const Offset(.76, .36),
      'l_hip': const Offset(.46, .52),
      'r_hip': const Offset(.54, .52),
      'l_knee': const Offset(.44, .68),
      'r_knee': const Offset(.58, .68),
      'l_ankle': const Offset(.42, .86),
      'r_ankle': const Offset(.60, .86),
    };

    final pts = norm.map((k, v) => MapEntry(
          k,
          Offset(v.dx * size.width, v.dy * size.height),
        ));

    void link(String a, String b) => canvas.drawLine(pts[a]!, pts[b]!, bone);

    link('head', 'neck');
    link('neck', 'l_shoulder');
    link('neck', 'r_shoulder');
    link('l_shoulder', 'l_elbow');
    link('l_elbow', 'l_wrist');
    link('r_shoulder', 'r_elbow');
    link('r_elbow', 'r_wrist');
    link('neck', 'l_hip');
    link('neck', 'r_hip');
    link('l_hip', 'l_knee');
    link('l_knee', 'l_ankle');
    link('r_hip', 'r_knee');
    link('r_knee', 'r_ankle');

    for (final o in pts.values) {
      canvas.drawCircle(o, 4, joint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
