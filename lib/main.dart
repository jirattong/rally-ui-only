import 'package:flutter/material.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/home.dart';
import 'pages/log_reg_page.dart';
import 'pages/start_cam.dart';
import 'pages/custom_gesture_page.dart';
import 'pages/analytics_page.dart';
import 'pages/devices_page.dart';
import 'pages/profile_page.dart';

void main() {
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

      // หน้าแรกเวลาเปิดแอป
      initialRoute: '/',

      routes: {
        '/': (context) => const HomePage(),

        // Home (จากไฟล์ home.dart)
        '/home': (context) => const HomePageReal(),

        // Login + Register
        '/Log_Reg': (context) => const LogRegPage(),

        // Camera Training Page
        '/Start_Cam': (context) => const StartCamPage(),

        // Custom Gesture Section
        '/Custom_Gesture': (context) => const CustomGesturePage(),
        '/Custom_Gesture/add': (context) => const AddGestureChooserPage(),
        '/Custom_Gesture/save': (context) => SaveGesturePage.fromRoute(context),

        // Placeholder ใช้ทดแทนหน้าไหนที่ยังไม่เสร็จ
        '/placeholder': (context) =>
            const PlaceholderPage(title: 'Placeholder'),

        // Device Connect Page
        '/Devices': (context) => const DevicesPage(),

        // Analytics
        '/Analytics': (context) => const AnalyticsPage(),
        '/Analytics/detail': (context) => const AnalyticsDetailPage(),
        '/Analytics/history': (context) => const AnalyticsHistoryPage(),

        // Profile
        '/Profile': (context) => const ProfilePage(),
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
