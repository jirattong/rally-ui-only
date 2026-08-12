import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusText = "Checking Firebase Connection...";

  final DatabaseReference _rtdbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  // ✅ ทดสอบการเชื่อมต่อกับ Firebase Realtime Database
  Future<void> _checkFirebaseConnection() async {
    setState(() => _isLoading = true);
    try {
      // ลองดึงค่าจาก Node command_payload/current_command
      DataSnapshot snapshot = await _rtdbRef
          .child('command_payload/current_command')
          .get()
          .timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          _isConnected = true;
          _statusText = "Connected to Firebase Realtime Database";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusText = "Cannot reach Firebase: $e";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ ส่งคำสั่งทดสอบ (Test Ping) ไปยัง 3D Simulator ผ่าน Firebase
  Future<void> _sendTestPing() async {
    setState(() => _isLoading = true);

    try {
      // ยิงคำสั่ง SHOOT เป็นการทดสอบยิงปืนใน 3D Simulator
      await _rtdbRef.child('command_payload/current_command').set({
        'cmd': 'SHOOT',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test Signal (SHOOT) Sent to 3D Simulator!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send signal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const cardColor = Color(0xFFFBE0CC);
    const accentColor = Colors.deepOrange;
    const titleColor = Color(0xFF3A5150);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          'Simulator Connection',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConnected
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                size: 64,
                color: _isConnected ? Colors.green : accentColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Rally 3D Simulator Target",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: $_statusText",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isConnected ? Colors.green[700] : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Card แสดงรายละเอียดการเชื่อมต่อ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Target Realtime Database Path",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "/command_payload/current_command",
                    style: TextStyle(
                      color: accentColor,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ปุ่มส่งสัญญาณทดสอบไปที่ Simulator
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _sendTestPing,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SEND TEST SIGNAL (SHOOT)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ปุ่มรีเฟรชเช็คการเชื่อมต่อ
            TextButton.icon(
              onPressed: _checkFirebaseConnection,
              icon: const Icon(Icons.refresh, color: titleColor),
              label: const Text(
                "Re-check Connection",
                style:
                    TextStyle(color: titleColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
