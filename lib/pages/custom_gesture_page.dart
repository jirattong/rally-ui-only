import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Custom Gestures',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _AddGestureTile(
            onTap: () => Navigator.pushNamed(context, '/Custom_Gesture/add'),
          ),
          const SizedBox(height: 12),
          _GestureItem(
            title: 'Smash Ready',
            onEdit: () => Navigator.pushNamed(
              context,
              '/Custom_Gesture/save',
              arguments: const SaveGestureArgs(mode: SaveMode.upload),
            ),
            onDelete: () {},
          ),
          const SizedBox(height: 12),
          _GestureItem(
            title: 'Double Hand Life',
            onEdit: () => Navigator.pushNamed(
              context,
              '/Custom_Gesture/save',
              arguments: const SaveGestureArgs(mode: SaveMode.upload),
            ),
            onDelete: () {},
          ),
        ],
      ),
    );
  }
}

class _AddGestureTile extends StatelessWidget {
  const _AddGestureTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 84,
        decoration: BoxDecoration(
          color: const Color(0xFFFBE0CC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: const [
          SizedBox(width: 18),
          Icon(Icons.add, size: 28, color: Colors.black87),
          SizedBox(width: 12),
          Text('Add Gesture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _GestureItem extends StatelessWidget {
  const _GestureItem(
      {required this.title, required this.onEdit, required this.onDelete});
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE0CC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 46,
              height: 46,
              color: Colors.black12,
              child: const Icon(Icons.person, color: Colors.black45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  width: 72,
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.black87)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.black87)),
        ]),
      ),
    );
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
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Save Gesture',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child:
                    Icon(Icons.sports_tennis, size: 120, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 16),
            _GradientButton(
              icon: Icons.photo_camera_rounded,
              label: 'Capture Pose',
              onTap: () => Navigator.pushNamed(
                context,
                '/Custom_Gesture/save',
                arguments: const SaveGestureArgs(mode: SaveMode.capture),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Or',
                  style: TextStyle(fontSize: 16, color: Colors.black87)),
            ),
            const SizedBox(height: 12),
            _LightButton(
              icon: Icons.photo_library_rounded,
              label: 'Upload Image',
              onTap: () => Navigator.pushNamed(
                context,
                '/Custom_Gesture/save',
                arguments: const SaveGestureArgs(mode: SaveMode.upload),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- Save page (with camera switch) ----------------------
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

  CameraController? _cam;
  Future<void>? _initCam;
  List<CameraDescription> _cams = [];
  int _camIndex = 0;
  bool _asking = false;

  XFile? _selectedImage;
  final _nameCtrl = TextEditingController(text: 'Smash Ready');

  @override
  void initState() {
    super.initState();
    _prepareCamera();
  }

  Future<void> _prepareCamera() async {
    setState(() => _asking = true);

    await [Permission.camera, Permission.photos, Permission.storage].request();

    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) throw 'No camera';
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
        const SnackBar(content: Text('อุปกรณ์นี้มีกล้องเดียว')),
      );
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
    _cam?.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      if (_cam == null) return;
      if (!_cam!.value.isInitialized) await _initCam;
      if (_cam!.value.isTakingPicture) return;
      final img = await _cam!.takePicture();
      if (!mounted) return;
      setState(() => _selectedImage = img);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ถ่ายรูปไม่สำเร็จ: $e')));
    }
  }

  Future<void> _pick() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null) return;
      if (!mounted) return;
      setState(() => _selectedImage = img);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เลือกรูปไม่สำเร็จ: $e')));
    }
  }

  void _save() {
    // TODO: ต่อระบบเซฟจริง
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Save "${_nameCtrl.text}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Save Gesture',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'สลับกล้อง',
            onPressed: (_cam != null) ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.black87),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // พรีวิวรูป/กล้อง
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: const Color(0xFF1C1C1C),
                  child: _asking
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImage != null
                          ? Image.file(File(_selectedImage!.path),
                              fit: BoxFit.cover)
                          : (_cam != null && _cam!.value.isInitialized)
                              ? CameraPreview(_cam!)
                              : const Center(
                                  child: Icon(Icons.photo_camera_outlined,
                                      size: 80, color: Colors.white38)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ตั้งชื่อ gesture
            SizedBox(
              height: 54,
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Gesture command name',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFFFE9DA),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC9CED4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFC9CED4), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ปุ่ม Capture / Upload
            Row(
              children: [
                Expanded(
                  child: _GradientButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Capture Pose',
                    onTap: (_cam != null && _cam!.value.isInitialized)
                        ? _capture
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LightButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Upload Image',
                    onTap: _pick,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Save
            InkWell(
              onTap: _save,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFFFAF66)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('Save',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Buttons (หนึ่งชุดเท่านั้น) ----
class _GradientButton extends StatelessWidget {
  const _GradientButton(
      {required this.label, required this.onTap, required this.icon});
  final String label;
  final VoidCallback? onTap;
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
  final VoidCallback? onTap;
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
