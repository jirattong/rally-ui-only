import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ เพิ่ม import นี้

// Pages
import 'pages/landing_page.dart';
import 'pages/home_page.dart';
import 'pages/log_reg_page.dart';
import 'pages/start_cam.dart';
import 'pages/custom_gesture_page.dart';
import 'pages/save_gesture_page.dart';
import 'pages/help_page.dart';
import 'pages/devices_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('✅ Firebase Init Success');
  } catch (e) {
    print('❌ Firebase Error: $e');
  }
  runApp(const RallyApp());
}

class RallyApp extends StatelessWidget {
  const RallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rally',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7E2F)),
        useMaterial3: true,
      ),
      // ❌ ลบ initialRoute: '/' ออก
      // ✅ ใช้ home: AuthGate() เป็นด่านแรก
      home: const AuthGate(),

      routes: {
        // '/': (context) => const LandingPage(), // ไม่ต้องมี '/' แล้ว เพราะใช้ AuthGate
        '/home': (context) => const HomePage(),
        '/Log_Reg': (context) => const LogRegPage(),
        '/Start_Cam': (context) => const StartCamPage(),
        '/Custom_Gesture': (context) => const CustomGesturePage(),
        '/Custom_Gesture/save': (context) => SaveGesturePage.fromRoute(context),
        '/Devices': (context) => const DevicesPage(),
        '/Help': (context) => const HelpPage(),
        '/Profile': (context) => const ProfilePage(),
      },
    );
  }
}

// Widget ยามเฝ้าประตู (Auth Gate)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ฟังสถานะ Login ตลอดเวลา
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. ถ้ามี User ล็อกอินอยู่ -> ส่งไปหน้า Home เลย
        if (snapshot.hasData) {
          return const HomePage();
        }

        // 2. ถ้าไม่มี User -> ส่งไปหน้า Landing (หรือ LogReg ตามต้องการ)
        else {
          return const LandingPage();
        }
      },
    );
  }
}
