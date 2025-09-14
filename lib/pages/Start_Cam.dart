import 'package:flutter/material.dart';
import 'dart:math' as math;

class StartCamPage extends StatefulWidget {
  const StartCamPage({super.key});
  @override
  State<StartCamPage> createState() => _StartCamPageState();
}
class _StartCamPageState extends State<StartCamPage> {
  bool running = false;
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const peach = Color(0xFFFFC8A7);
    const dark = Color(0xFF3A5150);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.deepOrange), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth; final side = w*0.08; final double camH = (w*0.88).clamp(260.0, 420.0);
        return SingleChildScrollView(padding: EdgeInsets.fromLTRB(side, 0, side, w*0.06), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Start', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 4),
          const Center(child: Text('Detect', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark))),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(22), child: Container(height: camH, color: peach, child: Stack(fit: StackFit.expand, children: [
            if (!running) Center(child: Icon(Icons.photo_camera_outlined, size: math.max(72.0, w*0.18), color: Color(0xFFED9F75))) else CustomPaint(painter: _PosePainter()),
          ]))),
          const SizedBox(height: 18),
          if (running) const _MetricsBlock() else const SizedBox.shrink(),
          const SizedBox(height: 12),
          SizedBox(height: 56, child: FilledButton.tonal(
            onPressed: () => setState(() => running = !running),
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFFFE0CC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            child: Text(running ? 'STOP' : 'START', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
          )),
        ]));
      })),
    );
  }
}

class _MetricsBlock extends StatelessWidget {
  const _MetricsBlock();
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left:8,right:8,top:6,bottom:8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        SizedBox(height: 6),
        Text('Motion : Smash Ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Time : 05 : 56 min', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Sent device : 15 time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFFDF7F2);
    canvas.drawRect(Offset.zero & size, bg);
    final imgRect = Rect.fromLTWH(size.width*0.12, size.height*0.08, size.width*0.62, size.height*0.78);
    final img = Paint()..color = const Color(0xFFE9E2DC);
    canvas.drawRRect(RRect.fromRectAndRadius(imgRect, const Radius.circular(18)), img);
    final jointPaint = Paint()..color = const Color(0xFF00FF4B)..style = PaintingStyle.fill;
    final bonePaint = Paint()..color = const Color(0xFF00FF4B)..strokeWidth = 3.0..style = PaintingStyle.stroke;
    Offset p(double x, double y) => Offset(imgRect.left + x*imgRect.width, imgRect.top + y*imgRect.height);
    final joints = {'head':p(0.60,0.12),'neck':p(0.60,0.22),'rShoulder':p(0.46,0.28),'rElbow':p(0.36,0.43),'rWrist':p(0.28,0.60),
      'lShoulder':p(0.72,0.28),'lElbow':p(0.82,0.42),'lWrist':p(0.88,0.30),'hip':p(0.60,0.50),'rKnee':p(0.54,0.72),'rAnkle':p(0.52,0.90),'lKnee':p(0.66,0.72),'lAnkle':p(0.68,0.92)};
    void bone(String a, String b) => canvas.drawLine(joints[a]!, joints[b]!, bonePaint);
    bone('head','neck'); bone('neck','rShoulder'); bone('neck','lShoulder'); bone('rShoulder','rElbow'); bone('rElbow','rWrist');
    bone('lShoulder','lElbow'); bone('lElbow','lWrist'); bone('neck','hip'); bone('hip','rKnee'); bone('rKnee','rAnkle');
    bone('hip','lKnee'); bone('lKnee','lAnkle'); for (final pt in joints.values) { canvas.drawCircle(pt, 6, jointPaint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
