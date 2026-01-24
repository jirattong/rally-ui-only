import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ เพิ่ม import
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ เพิ่ม import

// Color constants used throughout the file
const Color kBg = Color(0xFFF9EFE6);
const Color kDark = Color(0xFF3A5150);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ดึง User ปัจจุบันแบบปลอดภัย
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final side = w * 0.06;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(side, w * 0.04, side, w * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text('Home',
                                style: TextStyle(fontSize: 24, color: kDark)),
                            SizedBox(height: 6),
                            Text('Rally-Ai',
                                style: TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    color: kDark)),
                            Text('Training',
                                style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: kDark)),
                          ],
                        ),
                      ),
                      // Use square logo from assets
                      SizedBox(
                        width: w * 0.25,
                        child: Image.asset('assets/rally_logo_square.png',
                            fit: BoxFit.contain),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.05),

                  // Big Start Button
                  _GradientBigButton(
                    title: 'Start Training',
                    subtitle: 'AI Motion Detection',
                    onTap: () => Navigator.pushNamed(context, '/Start_Cam'),
                  ),
                  const SizedBox(height: 16),

                  // Menu Grid
                  Row(
                    children: [
                      Expanded(
                        child: _SquareTile(
                          icon: Icons.settings_remote_rounded,
                          label: 'Device\nSetup',
                          onTap: () => Navigator.pushNamed(context, '/Devices'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SquareTile(
                          icon: Icons.menu_book_rounded,
                          label: 'Guide &\nHelp',
                          onTap: () => Navigator.pushNamed(context, '/Help'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Custom Section
                  const Text('Customization',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 10),
                  _GradientWideCard(
                    title: 'Gesture Settings',
                    onTap: () =>
                        Navigator.pushNamed(context, '/Custom_Gesture'),
                  ),
                  const SizedBox(height: 22),

                  // Profile Section
                  const Text('User Profile',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 10),

                  // 🔥 2. ส่วนแสดงผล Profile แบบ Real-time
                  if (user != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String displayName = user.displayName ?? 'Loading...';
                        String emailHandle = user.email ?? '';
                        // ✅ ตั้งค่า Default Avatar เป็นผู้ชาย
                        String avatarAsset = 'assets/avatar_male.jpg';

                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;

                          // ดึงชื่อ
                          if (data.containsKey('username')) {
                            displayName = data['username'];
                          }

                          // ✅ ดึง avatar_type เพื่อเปลี่ยนรูป
                          if (data['avatar_type'] == 'female') {
                            avatarAsset = 'assets/avatar_female.jpg';
                          }
                        }

                        return _ProfileCard(
                          name: displayName,
                          handle: emailHandle,
                          avatarAsset: avatarAsset, // ส่ง path รูปไปโชว์
                          onEdit: () =>
                              Navigator.pushNamed(context, '/Profile'),
                        );
                      },
                    )
                  else
                    // กรณีไม่มี User (Guest Mode)
                    _ProfileCard(
                      name: 'Guest Mode',
                      handle: 'Please Login',
                      avatarAsset: 'assets/avatar_male.jpg',
                      onEdit: () =>
                          Navigator.pushReplacementNamed(context, '/Log_Reg'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============ Sub-widgets ============

class _GradientBigButton extends StatelessWidget {
  const _GradientBigButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = (w * 0.26).clamp(120.0, 180.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A3D), Color(0xFFFFAF66)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareTile extends StatelessWidget {
  const _SquareTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = (w * 0.32).clamp(120.0, 170.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFFBE0CC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: Colors.black87),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientWideCard extends StatelessWidget {
  const _GradientWideCard({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = (w * 0.26).clamp(110.0, 160.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A3D), Color(0xFFCA6B36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  color: Colors.black87, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
              ),
              const Opacity(
                opacity: 0.25,
                child: Icon(Icons.settings, size: 72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.handle,
    required this.avatarAsset, // ✅ เพิ่มพารามิเตอร์รับ path รูป
    required this.onEdit,
  });
  final String name;
  final String handle;
  final String avatarAsset;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE0CC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(handle,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAF66),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Edit Profile',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ✅ ใช้ CircleAvatar แสดงรูปจาก Assets
            CircleAvatar(
              radius: 34, // ขนาดเท่าเดิม (68/2)
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(avatarAsset),
            ),
          ],
        ),
      ),
    );
  }
}
