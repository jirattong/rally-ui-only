import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const textDark = Color(0xFF3A5150);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Guide & Help',
          style: TextStyle(fontWeight: FontWeight.w900, color: textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🔥 Tips for Stability & Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.accessibility_new_rounded,
                        color: Colors.deepOrange, size: 30),
                    SizedBox(width: 12),
                    Text("คำแนะนำสำคัญ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    "1. ยืนนิ่งๆ (Stability) หากขยับตัว ระบบจะไม่ตรวจจับท่า",
                    style: TextStyle(fontSize: 13)),
                const Text(
                    "2. เปิด/ปิดท่าได้ ไปที่ Gesture Settings เพื่อปิดท่าที่ไม่ต้องการ",
                    style: TextStyle(fontSize: 13)),
                const Text(
                    "3. ปรับความไว สามารถปรับเวลา (Duration) ของแต่ละท่าได้",
                    style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Static Gestures ---
          const _SectionHeader(title: "⏱️ Static Gestures (ท่าค้าง)"),
          const SizedBox(height: 8),
          const _InfoCard(
            text: "ทำท่าค้างไว้จนกว่าจะขึ้น Status สีเขียว",
            icon: Icons.timer,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          const _GestureCard(
            title: "BOTH",
            command: "RAISE BOTH",
            icon: Icons.accessibility_new,
            iconColor: Colors.purple,
            steps: [
              "ยกมือทั้งสองข้าง ขึ้นเหนือระดับจมูก",
              "แขนเหยียดตรง ค้างไว้"
            ],
            isHold: true,
          ),
          const SizedBox(height: 12),

          const _GestureCard(
            title: "Right",
            command: "RAISE RIGHT",
            icon: Icons.pan_tool,
            iconColor: Colors.green,
            steps: ["ยกมือขวา ขึ้นเหนือระดับจมูก", "แขนเหยียดตรง ค้างไว้"],
            isHold: true,
          ),
          const SizedBox(height: 12),

          const _GestureCard(
            title: "Left",
            command: "RAISE LEFT",
            icon: Icons.pan_tool_outlined,
            iconColor: Colors.red,
            steps: ["ยกมือซ้าย ขึ้นเหนือระดับจมูก", "แขนเหยียดตรง ค้างไว้"],
            isHold: true,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // --- Right Hand Motion Gestures ---
          const _SectionHeader(title: "👋 Right Hand Motion (มือขวา)"),
          const SizedBox(height: 8),
          const _InfoCard(
            text: "ต้องขยับมือต่อเนื่อง ไม่ต้องค้าง (ทำให้ทันเวลา)",
            icon: Icons.speed,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const _GestureCard(
            title: "Swipe Right",
            command: "R_SWIPE RIGHT",
            icon: Icons.swipe_right,
            iconColor: Colors.deepOrange,
            steps: ["1. มือขวาแตะไหล่ซ้าย", "2. ปัดผ่านหน้าอก", "3. กางแขนออก"],
          ),
          const SizedBox(height: 12),
          const _GestureCard(
            title: "Swipe Left",
            command: "R_SWIPE LEFT",
            icon: Icons.swipe_left,
            iconColor: Colors.deepOrange,
            steps: ["1. กางแขนขวาออก", "2. ปัดกลับมา", "3. แตะไหล่ซ้าย"],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          //ส่วนที่เพิ่มใหม่: Left Hand Motion Gestures ---
          const _SectionHeader(title: "👋 Left Hand Motion (มือซ้าย)"),
          const SizedBox(height: 8),
          const _InfoCard(
            text: "ต้องขยับมือต่อเนื่อง ไม่ต้องค้าง (ทำให้ทันเวลา)",
            icon: Icons.volume_up,
            color: Colors.teal,
          ),
          const SizedBox(height: 16),

          const _GestureCard(
            title: "Swipe Left",
            command: "L_SWIPE LEFT",
            icon: Icons.volume_down,
            iconColor: Colors.teal,
            steps: ["1. มือซ้ายแตะไหล่ขวา", "2. ปัดออกข้างนอก", "3. กางแขนออก"],
          ),
          const SizedBox(height: 12),

          const _GestureCard(
            title: "Swipe Right",
            command: "L_SWIPE RIGHT",
            icon: Icons.volume_up,
            iconColor: Colors.teal,
            steps: ["1. กางแขนซ้ายออก", "2. ปัดเข้าหาตัว", "3. แตะไหล่ขวา"],
          ),

          const SizedBox(height: 40), // พื้นที่ว่างด้านล่างสุด
        ],
      ),
    );
  }
}

// ... Sub-widgets (เหมือนเดิมเป๊ะ) ...

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3A5150)));
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _InfoCard(
      {required this.text, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)))
      ]),
    );
  }
}

class _GestureCard extends StatelessWidget {
  final String title;
  final String command;
  final IconData icon;
  final Color iconColor;
  final List<String> steps;
  final bool isHold;
  const _GestureCard(
      {required this.title,
      required this.command,
      required this.icon,
      required this.iconColor,
      required this.steps,
      this.isHold = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 28)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text(command,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: iconColor,
                          letterSpacing: 1.0))
                ])),
            if (isHold)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text("Hold",
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.arrow_right, size: 18, color: Colors.grey),
                Expanded(
                    child: Text(step,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 14)))
              ]))),
        ]),
      ),
    );
  }
}
