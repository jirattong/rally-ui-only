import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/home.dart';
import 'pages/Log_Reg_page.dart';
import 'pages/Start_Cam.dart';
import 'pages/Custom_Gesture_page.dart';
import 'pages/Analytics_page.dart';
import 'pages/Devices_page.dart';
import 'pages/Profile_page.dart';

void main() => runApp(const RallyApp());

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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/home': (context) => const HomePageReal(),
        '/Log_Reg': (context) => const LogRegPage(),
        '/Start_Cam': (context) => const StartCamPage(),
        '/Custom_Gesture': (context) => const CustomGesturePage(),
        '/Custom_Gesture/add': (context) => const AddGestureChooserPage(),
        '/Custom_Gesture/save': (context) => SaveGesturePage.fromRoute(context),
        '/placeholder': (context) =>
            const PlaceholderPage(title: 'Placeholder'),
        '/Devices': (context) => const DevicesPage(),
        '/Analytics/detail': (context) => const AnalyticsDetailPage(),
        '/Analytics/history': (context) => const AnalyticsHistoryPage(),
        '/Analytics': (context) => const AnalyticsPage(),
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
        appBar: AppBar(title: Text(title)), body: Center(child: Text(title)));
  }
}
