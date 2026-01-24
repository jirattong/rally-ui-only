import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 1. เพิ่ม import นี้
import '../core/gesture_store.dart';
import 'save_gesture_page.dart';

class CustomGesturePage extends StatefulWidget {
  const CustomGesturePage({super.key});
  @override
  State<CustomGesturePage> createState() => _CustomGesturePageState();
}

class _CustomGesturePageState extends State<CustomGesturePage> {
  // Data
  List<PoseGesture> _customItems = [];

  final Map<String, String> _presetCmds = {};
  final Map<String, int> _presetDurs = {};
  final Map<String, bool> _presetActive = {};
  final Map<String, double> _presetThresholds = {};

  final List<String> _presetKeys = [
    'SWIPE_RIGHT',
    'SWIPE_LEFT',
    'L_SWIPE_LEFT',
    'L_SWIPE_RIGHT',
    'RAISE_RIGHT',
    'RAISE_LEFT',
    'RAISE_BOTH'
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _customItems = await GestureStore.loadAll();

    for (var key in _presetKeys) {
      _presetCmds[key] =
          await GestureStore.getPresetCommand(key, _getDefaultCmd(key));
      _presetDurs[key] = await GestureStore.getPresetDuration(key, 1000);
      _presetActive[key] = await GestureStore.getPresetActive(key, true);
      _presetThresholds[key] = await GestureStore.getPresetThreshold(key, 0.25);
    }

    if (mounted) setState(() {});
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

  Future<void> _deleteCustom(String id) async {
    await GestureStore.delete(id);
    _loadAll();
  }

  // 🔥 2. ฟังก์ชัน ยามเฝ้าประตู (Guest Guard)
  void _checkGuest(VoidCallback onAllowed) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ❌ ถ้าเป็น Guest -> เด้ง Dialog เตือน
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text("Member Only"),
            ],
          ),
          content: const Text(
              "Please sign in to add custom gestures and save your progress."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                // ดีดไปหน้า Login/Register และล้างประวัติหน้าเก่า
                Navigator.pushNamedAndRemoveUntil(
                    context, '/Log_Reg', (route) => false);
              },
              child: const Text("Sign In / Register",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // ✅ ถ้าเป็น Member -> ให้ทำงานต่อ
      onAllowed();
    }
  }

  void _showEditDialog({
    required String title,
    required String currentCmd,
    required int currentDur,
    double? currentThreshold,
    String? currentName,
    bool allowNameEdit = false,
    bool isDynamic = false,
    required Future<void> Function(
            String newCmd, String newName, int newDur, double newThr)
        onSave,
  }) {
    final cmdCtrl = TextEditingController(text: currentCmd);
    final nameCtrl = TextEditingController(text: currentName ?? '');
    double durVal = currentDur.toDouble();
    double thrVal = currentThreshold ?? 0.25;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit $title'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allowNameEdit) ...[
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: cmdCtrl,
                      decoration: const InputDecoration(
                          labelText: 'IoT Command',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),

                    // --- Duration Slider ---
                    Text(
                        "Hold Duration: ${(durVal / 1000).toStringAsFixed(1)}s",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange)),
                    Slider(
                      value: durVal,
                      min: 500,
                      max: 3000,
                      divisions: 25,
                      activeColor: Colors.deepOrange,
                      onChanged: (val) => setStateDialog(() => durVal = val),
                    ),

                    // --- Threshold Slider ---
                    if (!isDynamic) ...[
                      const SizedBox(height: 10),
                      Text("Strictness: ${((0.55 - thrVal) * 200).toInt()}%",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent)),
                      Slider(
                        value: thrVal,
                        min: 0.1,
                        max: 0.5,
                        divisions: 20,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) => setStateDialog(() => thrVal = val),
                      ),
                      Text(
                        allowNameEdit
                            ? "Lower % = Loose Match\nHigher % = Strict Match"
                            : "Lower % = Low Height (Shoulder)\nHigher % = High Height (Eye/Head)",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    await onSave(cmdCtrl.text.trim().toUpperCase(),
                        nameCtrl.text.trim(), durVal.toInt(), thrVal);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadAll();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9EFE6),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Static Gesture',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepOrange),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/Custom_Gesture/save',
                          arguments:
                              const SaveGestureArgs(mode: SaveMode.capture))
                      .then((_) => _loadAll());
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/Custom_Gesture/save',
                          arguments:
                              const SaveGestureArgs(mode: SaveMode.upload))
                      .then((_) => _loadAll());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Gesture Settings',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF3A5150))),
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- RIGHT HAND SWIPES ----------------
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Right Hand Motion (มือขวา)",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
          ),

          _PresetTile(
              icon: Icons.swipe_right,
              name: "Right Hand Swipe Right (>>)",
              command: _presetCmds['SWIPE_RIGHT'] ?? 'NEXT',
              duration: _presetDurs['SWIPE_RIGHT'] ?? 1000,
              isActive: _presetActive['SWIPE_RIGHT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('SWIPE_RIGHT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Right Hand > Right",
                  currentCmd: _presetCmds['SWIPE_RIGHT'] ?? 'NEXT',
                  currentDur: _presetDurs['SWIPE_RIGHT'] ?? 1000,
                  isDynamic: true,
                  onSave: (cmd, _, dur, __) async {
                    await GestureStore.savePresetCommand('SWIPE_RIGHT', cmd);
                    await GestureStore.savePresetDuration('SWIPE_RIGHT', dur);
                  })),
          _PresetTile(
              icon: Icons.swipe_left,
              name: "Right Hand Swipe Left (<<)",
              command: _presetCmds['SWIPE_LEFT'] ?? 'PREV',
              duration: _presetDurs['SWIPE_LEFT'] ?? 1000,
              isActive: _presetActive['SWIPE_LEFT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('SWIPE_LEFT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Right Hand < Left",
                  currentCmd: _presetCmds['SWIPE_LEFT'] ?? 'PREV',
                  currentDur: _presetDurs['SWIPE_LEFT'] ?? 1000,
                  isDynamic: true,
                  onSave: (cmd, _, dur, __) async {
                    await GestureStore.savePresetCommand('SWIPE_LEFT', cmd);
                    await GestureStore.savePresetDuration('SWIPE_LEFT', dur);
                  })),

          const SizedBox(height: 16),

          // ---------------- LEFT HAND SWIPES (NEW) ----------------
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Left Hand Motion (มือซ้าย)",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
          ),

          _PresetTile(
              icon: Icons.swipe_left,
              name: "Left Hand Swipe Left (<<)",
              command: _presetCmds['L_SWIPE_LEFT'] ?? 'VOL_DOWN',
              duration: _presetDurs['L_SWIPE_LEFT'] ?? 1000,
              isActive: _presetActive['L_SWIPE_LEFT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('L_SWIPE_LEFT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Left Hand < Left",
                  currentCmd: _presetCmds['L_SWIPE_LEFT'] ?? 'VOL_DOWN',
                  currentDur: _presetDurs['L_SWIPE_LEFT'] ?? 1000,
                  isDynamic: true,
                  onSave: (cmd, _, dur, __) async {
                    await GestureStore.savePresetCommand('L_SWIPE_LEFT', cmd);
                    await GestureStore.savePresetDuration('L_SWIPE_LEFT', dur);
                  })),
          _PresetTile(
              icon: Icons.swipe_right,
              name: "Left Hand Swipe Right (>>)",
              command: _presetCmds['L_SWIPE_RIGHT'] ?? 'VOL_UP',
              duration: _presetDurs['L_SWIPE_RIGHT'] ?? 1000,
              isActive: _presetActive['L_SWIPE_RIGHT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('L_SWIPE_RIGHT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Left Hand > Right",
                  currentCmd: _presetCmds['L_SWIPE_RIGHT'] ?? 'VOL_UP',
                  currentDur: _presetDurs['L_SWIPE_RIGHT'] ?? 1000,
                  isDynamic: true,
                  onSave: (cmd, _, dur, __) async {
                    await GestureStore.savePresetCommand('L_SWIPE_RIGHT', cmd);
                    await GestureStore.savePresetDuration('L_SWIPE_RIGHT', dur);
                  })),

          const SizedBox(height: 16),

          // ---------------- STATIC PRESETS ----------------
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Hold Presets (Static)",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent)),
          ),

          _PresetTile(
              icon: Icons.accessibility_new_rounded,
              name: "Raise Both Hands",
              command: _presetCmds['RAISE_BOTH'] ?? 'STOP',
              duration: _presetDurs['RAISE_BOTH'] ?? 1000,
              isActive: _presetActive['RAISE_BOTH'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('RAISE_BOTH', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Raise Both Hands",
                  currentCmd: _presetCmds['RAISE_BOTH'] ?? 'STOP',
                  currentDur: _presetDurs['RAISE_BOTH'] ?? 1000,
                  currentThreshold: _presetThresholds['RAISE_BOTH'],
                  isDynamic: false,
                  onSave: (cmd, _, dur, thr) async {
                    await GestureStore.savePresetCommand('RAISE_BOTH', cmd);
                    await GestureStore.savePresetDuration('RAISE_BOTH', dur);
                    await GestureStore.savePresetThreshold('RAISE_BOTH', thr);
                  })),

          _PresetTile(
              icon: Icons.pan_tool,
              name: "Raise Right Hand",
              command: _presetCmds['RAISE_RIGHT'] ?? 'ON',
              duration: _presetDurs['RAISE_RIGHT'] ?? 1000,
              isActive: _presetActive['RAISE_RIGHT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('RAISE_RIGHT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Raise Right",
                  currentCmd: _presetCmds['RAISE_RIGHT'] ?? 'ON',
                  currentDur: _presetDurs['RAISE_RIGHT'] ?? 1000,
                  currentThreshold: _presetThresholds['RAISE_RIGHT'],
                  isDynamic: false,
                  onSave: (cmd, _, dur, thr) async {
                    await GestureStore.savePresetCommand('RAISE_RIGHT', cmd);
                    await GestureStore.savePresetDuration('RAISE_RIGHT', dur);
                    await GestureStore.savePresetThreshold('RAISE_RIGHT', thr);
                  })),
          _PresetTile(
              icon: Icons.pan_tool,
              name: "Raise Left Hand",
              command: _presetCmds['RAISE_LEFT'] ?? 'OFF',
              duration: _presetDurs['RAISE_LEFT'] ?? 1000,
              isActive: _presetActive['RAISE_LEFT'] ?? true,
              onToggle: (val) async {
                await GestureStore.savePresetActive('RAISE_LEFT', val);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                  title: "Raise Left",
                  currentCmd: _presetCmds['RAISE_LEFT'] ?? 'OFF',
                  currentDur: _presetDurs['RAISE_LEFT'] ?? 1000,
                  currentThreshold: _presetThresholds['RAISE_LEFT'],
                  isDynamic: false,
                  onSave: (cmd, _, dur, thr) async {
                    await GestureStore.savePresetCommand('RAISE_LEFT', cmd);
                    await GestureStore.savePresetDuration('RAISE_LEFT', dur);
                    await GestureStore.savePresetThreshold('RAISE_LEFT', thr);
                  })),

          const SizedBox(height: 24),

          // ---------------- CUSTOM GESTURES ----------------
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("My Custom Gestures",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),

          InkWell(
            // 🔥 3. ครอบฟังก์ชัน _checkGuest ที่ปุ่ม Add
            onTap: () => _checkGuest(_showAddOptions),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFBE0CC),
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text("Add New Gesture",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A5150))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_customItems.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No custom gestures yet.",
                        style: TextStyle(color: Colors.grey)))),

          for (final g in _customItems)
            _CustomGestureTile(
              item: g,
              onDelete: () => _deleteCustom(g.id),
              onToggle: (val) async {
                final updated = PoseGesture(
                    id: g.id,
                    name: g.name,
                    command: g.command,
                    holdDuration: g.holdDuration,
                    keypoints: g.keypoints,
                    thumbnailPath: g.thumbnailPath,
                    timestamp: g.timestamp,
                    isActive: val,
                    threshold: g.threshold);
                await GestureStore.saveOne(updated);
                _loadAll();
              },
              onEdit: () => _showEditDialog(
                title: "Custom Gesture",
                currentCmd: g.command,
                currentDur: g.holdDuration,
                currentName: g.name,
                currentThreshold: g.threshold,
                allowNameEdit: true,
                isDynamic: false,
                onSave: (newCmd, newName, newDur, newThr) async {
                  final updated = PoseGesture(
                    id: g.id,
                    name: newName,
                    command: newCmd,
                    holdDuration: newDur,
                    threshold: newThr,
                    keypoints: g.keypoints,
                    thumbnailPath: g.thumbnailPath,
                    timestamp: g.timestamp,
                    isActive: g.isActive,
                  );
                  await GestureStore.saveOne(updated);
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ... (Classes _PresetTile และ _CustomGestureTile เหมือนเดิม) ...
// เพื่อความสะดวก ผมยังคงไว้ให้ด้านล่างนี้ครับ

class _PresetTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String command;
  final int duration;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _PresetTile(
      {required this.icon,
      required this.name,
      required this.command,
      required this.duration,
      required this.isActive,
      required this.onToggle,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Switch(
          value: isActive,
          onChanged: onToggle,
          activeColor: Colors.deepOrange,
        ),
        title: Text(name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : Colors.grey)),
        subtitle: isActive
            ? Row(
                children: [
                  Text("CMD: $command",
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text("Wait: ${(duration / 1000).toStringAsFixed(1)}s",
                      style:
                          TextStyle(color: Colors.orange[800], fontSize: 12)),
                ],
              )
            : const Text("Disabled", style: TextStyle(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _CustomGestureTile extends StatelessWidget {
  final PoseGesture item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _CustomGestureTile(
      {required this.item,
      required this.onDelete,
      required this.onEdit,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Switch(
          value: item.isActive,
          onChanged: onToggle,
          activeColor: Colors.green,
        ),
        title: Text(item.name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isActive ? Colors.black : Colors.grey)),
        subtitle: item.isActive
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("CMD: ${item.command}",
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text(
                          "Wait: ${(item.holdDuration / 1000).toStringAsFixed(1)}s",
                          style: TextStyle(
                              color: Colors.orange[800], fontSize: 12)),
                    ],
                  ),
                  Text(
                      "Strictness: ${((0.55 - item.threshold) * 200).toInt()}%",
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            : const Text("Disabled", style: TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
