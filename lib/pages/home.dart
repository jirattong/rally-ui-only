import 'package:flutter/material.dart';

/// ใช้ค่าสีร่วมทั้งไฟล์
const Color kBg = Color(0xFFF9EFE6);
const Color kDark = Color(0xFF3A5150);

class HomePageReal extends StatelessWidget {
  const HomePageReal({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 8),
                            // เอา const TextStyle ให้ใช้ kDark ที่เป็น const ด้านบนได้
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
                      // ถ้าโปรเจ็กต์คุณใช้ไฟล์โลโก้ชื่ออื่น เปลี่ยน path ตรงนี้ได้
                      SizedBox(
                        width: w * 0.25,
                        child: Image.asset(
                          'assets/rally_logo_square.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.05),
                  _GradientBigButton(
                    title: 'Start Training',
                    subtitle: 'Preset',
                    onTap: () => Navigator.pushNamed(context, '/Start_Cam'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SquareTile(
                          icon: Icons.settings_suggest_rounded,
                          label: 'Device\nSetup',
                          onTap: () => Navigator.pushNamed(context, '/Devices'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SquareTile(
                          icon: Icons.pie_chart_rounded,
                          label: 'Analytics',
                          onTap: () =>
                              Navigator.pushNamed(context, '/Analytics'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Custom',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 10),
                  _GradientWideCard(
                    title: 'Gestures',
                    onTap: () =>
                        Navigator.pushNamed(context, '/Custom_Gesture'),
                  ),
                  const SizedBox(height: 22),
                  const Text('Profile User',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 10),
                  _ProfileCard(
                    name: 'IpedNoi',
                    handle: '@Yutpauy',
                    // >>> เชื่อมปุ่ม Edit Profile ไปหน้า /Profile <<<
                    onEdit: () => Navigator.pushNamed(context, '/Profile'),
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
          // เดิมเป็น const และ hard-coded จนใช้ title/subtitle ไม่ได้ — แก้แล้ว
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
              const Icon(Icons.schema_rounded, color: Colors.black87, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title, // เดิม hard-coded เป็น 'Gestures' — แก้ให้ใช้ตัวแปร
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
              ),
              const Opacity(
                opacity: 0.25,
                child: Icon(Icons.sports_tennis, size: 72),
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
    required this.onEdit,
  });
  final String name;
  final String handle;
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
                      onPressed: onEdit, // ← เปิดหน้า /Profile แล้วด้านบน
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 68,
                height: 68,
                color: Colors.black12,
                child:
                    const Icon(Icons.person, size: 42, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
