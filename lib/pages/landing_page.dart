import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const darkText = Color(0xFF3A5150);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo Area
              Center(
                child: Column(
                  children: [
                    // Use full logo from assets
                    Image.asset(
                      'assets/rally_logo.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Badminton Training Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        color: darkText.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Buttons
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/Log_Reg'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Login / Register',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkText,
                  side: BorderSide(color: darkText.withOpacity(0.3), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quick Start',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
