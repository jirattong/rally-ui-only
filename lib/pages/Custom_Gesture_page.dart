import 'package:flutter/material.dart';

/// /Custom_Gesture (list) -> /Custom_Gesture/add (choose) -> /Custom_Gesture/save (preview+name+save)
class CustomGesturePage extends StatelessWidget {
  const CustomGesturePage({super.key});
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        title: const Text('Custom Gestures', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.deepOrange), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16,8,16,16), children: [
        _AddGestureTile(onTap: () => Navigator.pushNamed(context, '/Custom_Gesture/add')),
        const SizedBox(height: 12),
        _GestureItem(title: 'Smash Ready', onEdit: () => Navigator.pushNamed(context, '/Custom_Gesture/save', arguments: const SaveGestureArgs(mode: SaveMode.upload)), onDelete: () {}),
        const SizedBox(height: 12),
        _GestureItem(title: 'Double Hand Life', onEdit: () => Navigator.pushNamed(context, '/Custom_Gesture/save', arguments: const SaveGestureArgs(mode: SaveMode.upload)), onDelete: () {}),
      ]),
    );
  }
}

class _AddGestureTile extends StatelessWidget {
  const _AddGestureTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Ink(
      height: 84, decoration: BoxDecoration(color: Color(0xFFFBE0CC), borderRadius: BorderRadius.circular(18)),
      child: Row(children: const [
        SizedBox(width: 18), Icon(Icons.add, size: 28, color: Colors.black87), SizedBox(width: 12),
        Text('Add Gesture', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    ));
  }
}

class _GestureItem extends StatelessWidget {
  const _GestureItem({required this.title, required this.onEdit, required this.onDelete});
  final String title; final VoidCallback onEdit; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Ink(decoration: BoxDecoration(color: Color(0xFFFBE0CC), borderRadius: BorderRadius.circular(18)), child: Padding(
      padding: const EdgeInsets.all(12), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(width: 46, height: 46, color: Colors.black12, child: const Icon(Icons.person, color: Colors.black45))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6), Container(height: 4, width: 72, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
        ])),
        const SizedBox(width: 12),
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Colors.black87)),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.black87)),
      ]),
    ));
  }
}

// ---------------------- Add chooser ----------------------
class AddGestureChooserPage extends StatelessWidget {
  const AddGestureChooserPage({super.key});
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        title: const Text('Save Gesture', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.deepOrange), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16,8,16,16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(child: Center(child: Icon(Icons.sports_tennis, size: 120, color: Colors.amber))),
            const SizedBox(height: 16),
            _GradientButton(icon: Icons.photo_camera_rounded, label: 'Capture Pose',
              onTap: () => Navigator.pushNamed(context, '/Custom_Gesture/save', arguments: const SaveGestureArgs(mode: SaveMode.capture))),
            const SizedBox(height: 12),
            const Center(child: Text('Or', style: TextStyle(fontSize: 16, color: Colors.black87))),
            const SizedBox(height: 12),
            _LightButton(icon: Icons.photo_library_rounded, label: 'Upload Image',
              onTap: () => Navigator.pushNamed(context, '/Custom_Gesture/save', arguments: const SaveGestureArgs(mode: SaveMode.upload))),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap, required this.icon});
  final String label; final VoidCallback onTap; final IconData icon;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Ink(
      height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(
        colors: [Color(0xFFFF8A3D), Color(0xFFFFAF66)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.black87), const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ])),
    ));
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton({required this.label, required this.onTap, required this.icon});
  final String label; final VoidCallback onTap; final IconData icon;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Ink(
      height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Color(0xFFFFE0CC)),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.black87), const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
      ])),
    ));
  }
}

// ---------------------- Save page ----------------------
enum SaveMode { capture, upload }
class SaveGestureArgs { final SaveMode mode; const SaveGestureArgs({required this.mode}); }

class SaveGesturePage extends StatefulWidget {
  final SaveMode mode;
  const SaveGesturePage({super.key, required this.mode});
  static Widget fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is SaveGestureArgs) return SaveGesturePage(mode: args.mode);
    return const SaveGesturePage(mode: SaveMode.upload);
  }
  @override State<SaveGesturePage> createState() => _SaveGesturePageState();
}

class _SaveGesturePageState extends State<SaveGesturePage> {
  final nameCtrl = TextEditingController(text: 'Smash Ready');
  @override void dispose() { nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6); const dark = Color(0xFF3A5150);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, title: const Text('Save Gesture', style: TextStyle(fontWeight: FontWeight.w800, color: dark)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.deepOrange), onPressed: () => Navigator.pop(context))),
      body: Padding(padding: const EdgeInsets.fromLTRB(16,8,16,20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(color: Color(0xFF1C1C1C),
          child: CustomPaint(painter: widget.mode == SaveMode.capture ? _PosePainter() : _UploadMockPainter(), child: const SizedBox.expand())))),
        const SizedBox(height: 14),
        SizedBox(height: 54, child: TextField(controller: nameCtrl, decoration: InputDecoration(
          hintText: 'Gesture command name', contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true, fillColor: Color(0xFFFFE9DA),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC9CED4))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC9CED4), width: 1.5)),
        ))),
        const SizedBox(height: 12),
        InkWell(onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (stub)'))); },
          borderRadius: BorderRadius.circular(14), child: Ink(height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFFFAF66)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: const Center(child: Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))))),
      ])),
    );
  }
}

class _PosePainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF141414); canvas.drawRect(Offset.zero & size, bg);
    final rect = Rect.fromLTWH(size.width*0.12, size.height*0.08, size.width*0.76, size.height*0.80);
    final img = Paint()..color = const Color(0xFF222222); canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), img);
    final joint = Paint()..color = const Color(0xFF00FF4B)..style = PaintingStyle.fill;
    final bone = Paint()..color = const Color(0xFF00FF4B)..strokeWidth = 3.0..style = PaintingStyle.stroke;
    Offset p(double x, double y) => Offset(rect.left + x*rect.width, rect.top + y*rect.height);
    final a=p(0.30,0.15), b=p(0.38,0.28), c=p(0.50,0.35), d=p(0.62,0.28), e=p(0.72,0.15); final hip=p(0.50,0.55);
    final rw=p(0.28,0.58), lw=p(0.72,0.35); final rk=p(0.44,0.75), ra=p(0.42,0.92); final lk=p(0.58,0.75), la=p(0.60,0.92);
    for (final pair in [(a,b),(b,c),(c,d),(d,e),(c,hip),(b,rw),(d,lw),(hip,rk),(rk,ra),(hip,lk),(lk,la)]) {
      canvas.drawLine(pair.$1, pair.$2, bone); }
    for (final pt in [a,b,c,d,e,hip,rw,lw,rk,ra,lk,la]) { canvas.drawCircle(pt, 6, joint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UploadMockPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF111111); canvas.drawRect(Offset.zero & size, bg);
    final joint = Paint()..color = const Color(0xFF00FF4B)..style = PaintingStyle.fill;
    final pts = [Offset(size.width*0.55, size.height*0.30), Offset(size.width*0.65, size.height*0.36), Offset(size.width*0.75, size.height*0.42),
      Offset(size.width*0.85, size.height*0.48), Offset(size.width*0.60, size.height*0.70), Offset(size.width*0.80, size.height*0.78)];
    for (final p in pts) { canvas.drawCircle(p, 6, joint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
