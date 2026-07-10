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

  group('CXP.06 route drawing', () {
    testWidgets('switching to Draw Route mode reveals the path-type picker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      expect(find.byType(DropdownButton<PathType>), findsNothing);

      await tester.tap(find.text('Draw Route'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<PathType>), findsOneWidget);
    });

    testWidgets('dragging from an actor in Draw mode records a path (enables Undo)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      final undoButtonFinder = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNull);

      await tester.tap(find.text('Draw Route'));
      await tester.pumpAndSettle();

      // Offense actor "1" sits near the top-left of the default frame
      // (see defaultBasketballFrame's x/y formula) — drag from its
      // rendered token position to a distant point on the court.
      final startTokenCenter = tester.getCenter(find.text('1'));
      final gesture = await tester.startGesture(startTokenCenter);
      await gesture.moveBy(const Offset(80, 60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNotNull);

      // Undo removes it again.
      await tester.tap(undoButtonFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNull);
    });

    testWidgets('Reset clears drawn paths as well as actor positions', (WidgetTester tester) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.text('Draw Route'));
      await tester.pumpAndSettle();

      final startTokenCenter = tester.getCenter(find.text('1'));
      final gesture = await tester.startGesture(startTokenCenter);
      await gesture.moveBy(const Offset(80, 60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final undoButtonFinder = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNotNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.restart_alt));
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNull);
    });
  });
}
