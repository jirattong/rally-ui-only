import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rally')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/Log_Reg'),
                child: const Text('Open Log/Register')),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                child: const Text('Open Home (UI)')),
          ],
        ),
      ),
    );
  }
}
