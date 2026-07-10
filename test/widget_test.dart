import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';
import 'package:cxp/features/court_editor/animation_perf_spike_screen.dart';
import 'package:cxp/features/court_editor/court_editor_screen.dart';
import 'package:cxp/features/court_editor/frame_playback_screen.dart';
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

  group('CXP.07 multi-frame sequencing', () {
    testWidgets('starts with exactly one frame chip and a disabled delete button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      expect(find.text('Frame 1'), findsOneWidget);
      expect(find.text('Frame 2'), findsNothing);

      final deleteButtonFinder = find.widgetWithIcon(IconButton, Icons.delete_outline);
      expect(tester.widget<IconButton>(deleteButtonFinder).onPressed, isNull);
    });

    testWidgets('Add frame appends and selects a new chip; delete becomes enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      expect(find.text('Frame 1'), findsOneWidget);
      expect(find.text('Frame 2'), findsOneWidget);

      final deleteButtonFinder = find.widgetWithIcon(IconButton, Icons.delete_outline);
      expect(tester.widget<IconButton>(deleteButtonFinder).onPressed, isNotNull);
    });

    testWidgets('Add frame duplicates actor positions but not drawn paths', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      // Draw a path on Frame 1.
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

      // Adding a frame should land on a fresh frame with no paths yet,
      // even though the path drawn on Frame 1 still exists there.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNull);

      // But actor "1" should still be rendered (duplicated position), not lost.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Delete frame removes the current frame and clamps selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();
      expect(find.text('Frame 2'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Frame 1'), findsOneWidget);
      expect(find.text('Frame 2'), findsNothing);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline)).onPressed, isNull);
    });

    testWidgets('Reset collapses back to a single frame', (WidgetTester tester) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();
      expect(find.text('Frame 3'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.restart_alt));
      await tester.pumpAndSettle();

      expect(find.text('Frame 1'), findsOneWidget);
      expect(find.text('Frame 2'), findsNothing);
    });

    testWidgets('Play opens FramePlaybackScreen and it runs without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(FramePlaybackScreen), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);

      // Pause/play toggle should be present and tappable.
      final playPauseFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && (widget.tooltip == 'Play' || widget.tooltip == 'Pause'),
      );
      expect(playPauseFinder, findsOneWidget);
      await tester.tap(playPauseFinder);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('actorsAtSequenceProgress returns the single frame unchanged when only one frame exists', () {
      final only = defaultBasketballFrame();
      final result = actorsAtSequenceProgress([only], 0.7);
      expect(result, same(only));
    });
  });
}
