import 'package:flutter/material.dart';

import 'features/coaching_home/coaching_home_screen.dart';

void main() {
  runApp(const CxpApp());
}

/// Standalone coaching entry point; existing court editor remains available.
class CxpApp extends StatelessWidget {
  const CxpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CXP',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const CoachingHomeScreen(),
    );
  }
}
