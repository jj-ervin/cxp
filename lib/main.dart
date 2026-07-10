import 'package:flutter/material.dart';

import 'features/court_editor/court_editor_screen.dart';

void main() {
  runApp(const CxpApp());
}

/// App shell (CXP.05) now hosting the court editor prototype (CXP.04).
/// Still no module wiring beyond this single screen — see DEV-PLAN.md.
class CxpApp extends StatelessWidget {
  const CxpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CXP',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const CourtEditorScreen(),
    );
  }
}
