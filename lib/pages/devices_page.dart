import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

enum DeviceConn { disconnected, connecting, connected }

class _DevicesPageState extends State<DevicesPage> {
  late final DatabaseReference _iotRef;
  StreamSubscription? _iotSubscription;

  final List<_DeviceModel> devices = [
    _DeviceModel(
      name: 'Searching...',
      model: '-',
      id: '-',
      status: 'Connecting...', // สถานะเริ่มต้น
      lastSeen: '-',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iotRef = FirebaseDatabase.instance.ref('iot_device');
    _listenToDeviceStatus();
  }

  @override
  void dispose() {
    _iotSubscription?.cancel();
    super.dispose();
  }

  void _listenToDeviceStatus() {
    _iotSubscription = _iotRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (mounted) {
        setState(() {
          if (data != null && data is Map) {
            final info = data['info'] as Map? ?? {};

            // 1. Info เครื่อง
            devices[0].name = info['device_name'] ?? 'Unknown Device';
            devices[0].model = info['model'] ?? '-';
            devices[0].id = info['id'] ?? '-';

            // 🔥 แก้ไขจุดนี้: อ่านค่าจาก 'command' แทน 'status'
            // เพราะตอนนี้ใน Firebase เราเปลี่ยนชื่อตัวแปรเป็น command แล้ว
            final rawCommand = data['command'];

            // เอามาโชว์ในช่อง Status ของแอป (เพื่อให้ User รู้ว่าคำสั่งล่าสุดคืออะไร)
            devices[0].status = rawCommand?.toString() ?? '-';

            // 3. Last Seen
            final lastConn = data['last_connected'];
            if (lastConn != null &&
                lastConn is String &&
                lastConn.length > 16) {
              devices[0].lastSeen = lastConn.substring(11, 16);
            } else {
              devices[0].lastSeen = lastConn?.toString() ?? '-';
            }
          } else {
            devices[0].status = 'Offline';
            devices[0].name = 'No Device Data';
          }
        });
      }
    }, onError: (e) {
      debugPrint("Firebase Error: $e");
    });
  }

  // ... (ฟังก์ชัน _refresh, _connectToDevice, _disconnectDevice คงเดิม) ...
  // เพื่อความชัวร์ ก๊อปปี้ส่วน UI ด้านล่างนี้ไปด้วยเลยครับ จะได้ครบชุด

  Future<void> _refresh() async {
    setState(() => devices[0].conn = DeviceConn.connecting);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => devices[0].conn = DeviceConn.disconnected);
  }

  Future<void> _connectToDevice(_DeviceModel d) async {
    setState(() => d.conn = DeviceConn.connecting);
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      await _iotRef.update({
        'app_status': 'connected',
        'last_connected': DateTime.now().toIso8601String(),
      });
      if (mounted) setState(() => d.conn = DeviceConn.connected);
    } catch (e) {
      if (mounted) setState(() => d.conn = DeviceConn.disconnected);
    }
  }

  Future<void> _disconnectDevice(_DeviceModel d) async {
    try {
      await _iotRef.update({'app_status': 'disconnected'});
    } catch (_) {}
    if (mounted) setState(() => d.conn = DeviceConn.disconnected);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Device Setup',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 4),
          const Center(
              child: Text('Select Device',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87))),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.black87),
              label: const Text('Refresh Status',
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.black87)),
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(devices.length, (i) {
            final d = devices[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: _DeviceCard(
                model: d,
                onConnectTap: () {
                  if (d.conn == DeviceConn.disconnected) {
                    _connectToDevice(d);
                  } else if (d.conn == DeviceConn.connected) {
                    _disconnectDevice(d);
                  }
                },
                onCancelTap: () =>
                    setState(() => d.conn = DeviceConn.disconnected),
                onExpandToggle: () => setState(() => d.expanded = !d.expanded),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Model และ Widgets คงเดิม
class _DeviceModel {
  _DeviceModel({
    required this.name,
    required this.model,
    required this.id,
    required this.status,
    required this.lastSeen,
  });

  String name;
  String model;
  String id;
  String status;
  String lastSeen;
  DeviceConn conn = DeviceConn.disconnected;
  bool expanded = false;
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(
      {required this.model,
      required this.onConnectTap,
      required this.onCancelTap,
      required this.onExpandToggle});
  final _DeviceModel model;
  final VoidCallback onConnectTap;
  final VoidCallback onCancelTap;
  final VoidCallback onExpandToggle;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFFBE0CC),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: Colors.black12,
                    child: const Icon(Icons.precision_manufacturing_rounded,
                        size: 38, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(model.model, style: const TextStyle(height: 1.1)),
                      const SizedBox(height: 8),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: _ConnectControls(
                              state: model.conn,
                              onConnect: onConnectTap,
                              onCancel: onCancelTap)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFECC3A5),
            height: 36,
            child: InkWell(
              onTap: onExpandToggle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      model.expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(model.expanded ? 'Hide details' : 'Show details',
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ),
          if (model.expanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEBB790),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              // ส่ง Label 'Command' ไปโชว์ในตารางแทน Status
              child: _DetailTable(model: model),
            ),
        ],
      ),
    );
  }
}

class _ConnectControls extends StatelessWidget {
  const _ConnectControls(
      {required this.state, required this.onConnect, required this.onCancel});
  final DeviceConn state;
  final VoidCallback onConnect;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DeviceConn.disconnected:
        return _Pill(
            label: 'Connect',
            icon: Icons.link_rounded,
            bg: const Color(0xFFE7DAD1),
            textColor: Colors.black87,
            border: const BorderSide(color: Color(0xFFB8AAA0)),
            onTap: onConnect,
            minWidth: 160);
      case DeviceConn.connecting:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                  label: 'Connecting',
                  icon: Icons.sync_rounded,
                  bg: const Color(0xFF32C15A),
                  textColor: Colors.white,
                  onTap: null,
                  showSpinner: true,
                  minWidth: 160),
              _Pill(
                  label: 'Cancel',
                  icon: Icons.close,
                  bg: const Color(0xFFD4483C),
                  textColor: Colors.white,
                  onTap: onCancel,
                  minWidth: 100),
            ]);
      case DeviceConn.connected:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                  label: 'Connected',
                  icon: Icons.check_circle_rounded,
                  bg: const Color(0xFF32C15A),
                  textColor: Colors.white,
                  onTap: null,
                  minWidth: 160),
              _Pill(
                  label: 'Disconnect',
                  icon: Icons.link_off_rounded,
                  bg: const Color(0xFFD4483C),
                  textColor: Colors.white,
                  onTap: onConnect,
                  minWidth: 140),
            ]);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label,
      required this.bg,
      required this.textColor,
      this.icon,
      this.onTap,
      this.border,
      this.showSpinner = false,
      this.minWidth = 120});
  final String label;
  final Color bg;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final BorderSide? border;
  final bool showSpinner;
  final double minWidth;
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
            color: bg.withOpacity(disabled ? 0.9 : 1),
            borderRadius: BorderRadius.circular(24),
            border: border != null ? Border.all(color: border!.color) : null),
        child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (showSpinner) ...[
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor))),
            const SizedBox(width: 8)
          ],
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8)
          ],
          Text(label,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
        ])),
      ),
    );
  }
}

class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.model});
  final _DeviceModel model;
  @override
  Widget build(BuildContext context) {
    Text row(String l, String r) => Text.rich(TextSpan(children: [
          TextSpan(
              text: '$l : ',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: r)
        ]));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 🔥 เปลี่ยน Label จาก Status เป็น Command เพื่อให้ User ไม่งง
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        row('Last command', model.status),
        const SizedBox(height: 6),
        row('Device ID', model.id)
      ])),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [row('Last seen', model.lastSeen)])),
    ]);
  }
}
