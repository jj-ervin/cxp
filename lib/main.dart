import 'package:flutter/material.dart';

void main() {
  runApp(const CxpApp());
}

/// App shell only — CXP.05. No feature modules wired in yet.
///
/// This is intentionally minimal: it exists to prove the Flutter project
/// builds and runs on web/Windows, not to implement any CXP module. The
/// court editor prototype (CXP.04) replaces the placeholder home screen.
class CxpApp extends StatelessWidget {
  const CxpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CXP',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const CxpShellPlaceholder(),
    );
  }
}

class CxpShellPlaceholder extends StatelessWidget {
  const CxpShellPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CXP — Coach Experience Platform')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'App shell only. See docs/architecture/ for the domain model, '
            'module boundaries, and UX philosophy driving the next build steps.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
