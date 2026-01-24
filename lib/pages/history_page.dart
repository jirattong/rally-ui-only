import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE6), // สีพื้นหลังเดียวกับธีมแอป
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9EFE6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity History',
          style:
              TextStyle(color: Color(0xFF3A5150), fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลจาก history โดยเรียงจากล่าสุดไปเก่าสุด (descending)
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .orderBy('started_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No activity yet",
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // แปลงข้อมูล
              final startTs = data['started_at'] as Timestamp?;
              final durationSec = data['duration_seconds'] as int? ?? 0;
              final cmdCount = data['commands_count'] as int? ?? 0;

              // จัดรูปแบบวันที่และเวลา
              final dateStr = startTs != null
                  ? DateFormat('dd MMM yyyy').format(startTs.toDate())
                  : 'Unknown Date';
              final timeStr = startTs != null
                  ? DateFormat('HH:mm').format(startTs.toDate())
                  : '--:--';

              // แปลงวินาทีเป็น นาที:วินาที
              final mins = (durationSec / 60).floor();
              final secs = durationSec % 60;
              final durationStr = '${mins}m ${secs}s';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE0CC).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Colors.deepOrange),
                  ),
                  title: Text(
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A5150),
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "$timeStr  •  $cmdCount commands",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        durationStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.deepOrange,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "Duration",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
