import 'dart:async';
import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

/// สถานะการเชื่อมต่อ
enum DeviceConn { disconnected, connecting, connected }

class _DevicesPageState extends State<DevicesPage> {
  final List<_DeviceModel> devices = [
    _DeviceModel(
      name: 'Device Name',
      model: 'H7 Badminton\nShuttlecock Shooting\nMachine',
      id: 'BM01',
      serial: 'ZWO2V-PZ6UU-LBUAI-SFRIK',
      status: 'Ready',
      signal: 'Strength',
      lastSeen: '25/08/2025',
    ),
    _DeviceModel(
      name: 'Device Name',
      model: 'H7 Badminton\nShuttlecock Shooting\nMachine',
      id: 'BM02',
      serial: 'A1B2C-3D4E5-FGHIJ-KLMNO',
      status: 'Ready',
      signal: 'Normal',
      lastSeen: '24/08/2025',
    ),
  ];

  void _refresh() {
    // TODO: refresh จริง
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Refresh devices (stub)')));
  }

  void _autoAdvanceToConnected(_DeviceModel d) {
    // เปลี่ยน Connecting -> Connected อัตโนมัติใน ~1.2 วินาที ถ้ายังเป็น Connecting อยู่
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (d.conn == DeviceConn.connecting) {
        setState(() => d.conn = DeviceConn.connected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          'Device Setup',
          style:
              TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3A5150)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Device',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.black87),
              label: const Text(
                'Refresh',
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // การ์ดอุปกรณ์ (เว้นระยะให้แน่นขึ้น)
          ...List.generate(devices.length, (i) {
            final d = devices[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: _DeviceCard(
                model: d,

                // ปุ่มหลัก:
                // - disconnected -> ไป connecting (แล้ว auto -> connected)
                // - connected    -> กลับเป็น disconnected
                onConnectTap: () {
                  setState(() {
                    if (d.conn == DeviceConn.disconnected) {
                      d.conn = DeviceConn.connecting;
                      _autoAdvanceToConnected(d);
                    } else if (d.conn == DeviceConn.connected) {
                      d.conn = DeviceConn.disconnected;
                    }
                  });
                },

                // ปุ่มรองตอนกำลัง Connecting (Disconnect เพื่อยกเลิก)
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

class _DeviceModel {
  _DeviceModel({
    required this.name,
    required this.model,
    required this.id,
    required this.serial,
    required this.status,
    required this.signal,
    required this.lastSeen,
  });

  final String name;
  final String model;
  final String id;
  final String serial;
  final String status;
  final String signal;
  final String lastSeen;

  DeviceConn conn = DeviceConn.disconnected;
  bool expanded = false;
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.model,
    required this.onConnectTap,
    required this.onCancelTap,
    required this.onExpandToggle,
  });

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
          // --- ส่วนบนสีอ่อน
          Container(
            color: const Color(0xFFFBE0CC),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปอุปกรณ์ (placeholder)
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

                // ข้อความ + ปุ่ม
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

                      // ปุ่มเชื่อมต่อ (ปรับตามสถานะ)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ConnectControls(
                          state: model.conn,
                          onConnect: onConnectTap,
                          onCancel: onCancelTap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // แก้ชื่อ (stub)
                IconButton(
                  onPressed: () {}, // TODO
                  icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
                ),
              ],
            ),
          ),

          // --- แถบ Show/Hide details (อยู่ภายในการ์ด)
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
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    model.expanded ? 'Hide details' : 'Show details',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // --- รายละเอียด (แสดงเมื่อ expanded)
          if (model.expanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEBB790),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _DetailTable(model: model),
            ),
        ],
      ),
    );
  }
}

/// กล่องควบคุมปุ่มเชื่อมต่อ:
/// - disconnected: ปุ่ม Connect เดี่ยว
/// - connecting:   ปุ่มคู่ [Connecting (หลัก, disabled+spinner)] + [Disconnect (รอง)]
/// - connected:    ปุ่มคู่ [Connected (หลัก, disabled)] + [Disconnect (รอง)]
class _ConnectControls extends StatelessWidget {
  const _ConnectControls({
    required this.state,
    required this.onConnect,
    required this.onCancel,
  });

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
          minWidth: 160,
        );

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
              onTap: null, // disabled
              showSpinner: true, // สปินเนอร์เล็ก
              minWidth: 160,
            ),
            _Pill(
              label: 'Disconnect',
              icon: Icons.link_off_rounded,
              bg: const Color(0xFFD4483C),
              textColor: Colors.white,
              onTap: onCancel, // กลับเป็น Connect (สีเทา)
              minWidth: 140,
            ),
          ],
        );

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
              onTap: null, // disabled
              minWidth: 160,
            ),
            _Pill(
              label: 'Disconnect',
              icon: Icons.link_off_rounded,
              bg: const Color(0xFFD4483C),
              textColor: Colors.white,
              onTap: onConnect, // ใน state นี้ onConnect = disconnect
              minWidth: 140,
            ),
          ],
        );
    }
  }
}

/// ปุ่มทรงแคปซูลใช้งานซ้ำได้
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.textColor,
    this.icon,
    this.onTap,
    this.border,
    this.showSpinner = false,
    this.minWidth = 120,
  });

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
          border: border != null ? Border.all(color: border!.color) : null,
          boxShadow: [
            if (!disabled && bg != const Color(0xFFE7DAD1))
              const BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.model});
  final _DeviceModel model;

  @override
  Widget build(BuildContext context) {
    Text row(String l, String r) {
      return Text.rich(TextSpan(children: [
        TextSpan(
            text: '$l : ', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: r),
      ]));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            row('Status', model.status),
            const SizedBox(height: 6),
            row('Device ID', model.id),
            const SizedBox(height: 6),
            row('Serial number', model.serial),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            row('Signal', model.signal),
            const SizedBox(height: 6),
            row('Last seen at', model.lastSeen),
          ]),
        ),
      ],
    );
  }
}
