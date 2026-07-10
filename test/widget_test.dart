import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';
import 'package:cxp/features/court_editor/animation_perf_spike_screen.dart';
import 'package:cxp/features/court_editor/court_editor_screen.dart';
import 'package:cxp/models/play_frame.dart';

void main() {
  testWidgets('App shell renders the court editor prototype', (WidgetTester tester) async {
    await tester.pumpWidget(const CxpApp());

    expect(find.byType(CourtEditorScreen), findsOneWidget);
    expect(find.text('Court Editor — prototype'), findsOneWidget);
  });

  testWidgets('Default frame renders 5 offense + 5 defense actors', (WidgetTester tester) async {
    await tester.pumpWidget(const CxpApp());

    // Offense tokens are labeled 1-5, defense X1-X5.
    for (var i = 1; i <= 5; i++) {
      expect(find.text('$i'), findsOneWidget);
      expect(find.text('X$i'), findsOneWidget);
    }
  });

  testWidgets('CXP.03 perf-spike screen runs multiple animation ticks without error', (
    WidgetTester tester,
  ) async {
    // Functional regression guard only — see docs/architecture/perf-spike-cxp03.md
    // for what this does and does not validate about real device performance.
    await tester.pumpWidget(const MaterialApp(home: AnimationPerfSpikeScreen()));

    // Pump enough frames to interpolate across every generated frame segment
    // at least once; this must not throw and must keep producing output.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.textContaining('Sampled frames:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('lerpFrame interpolates every actor between two frames', () {
    final a = defaultBasketballFrame();
    final b = stressTestFrames(frameCount: 2)[1];

    final mid = lerpFrame(a, b, 0.5);

    expect(mid.length, a.length);
    for (var i = 0; i < a.length; i++) {
      expect(mid[i].x, closeTo((a[i].x + b[i].x) / 2, 1e-9));
      expect(mid[i].y, closeTo((a[i].y + b[i].y) / 2, 1e-9));
    }
  });
}
