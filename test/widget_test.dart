import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';
import 'package:cxp/data/play_repository.dart';
import 'package:cxp/features/court_editor/animation_perf_spike_screen.dart';
import 'package:cxp/features/court_editor/court_editor_screen.dart';
import 'package:cxp/features/court_editor/frame_playback_screen.dart';
import 'package:cxp/features/court_editor/play_library_screen.dart';
import 'package:cxp/models/play_frame.dart';
import 'package:cxp/models/saved_play.dart';

/// In-memory `PlayRepository` for CXP.15 tests — avoids touching the real
/// `shared_preferences` platform channel, matching the pattern used
/// elsewhere in this file (`AnimationPerfSpikeScreen` tests wrap their own
/// `MaterialApp` rather than depending on `CxpApp`'s wiring).
class _FakePlayRepository implements PlayRepository {
  final List<SavedPlay> _plays = [];

  @override
  Future<List<SavedPlay>> loadAll() async => List.unmodifiable(_plays);

  @override
  Future<void> save(SavedPlay play) async {
    _plays.removeWhere((p) => p.id == play.id);
    _plays.add(play);
  }

  @override
  Future<void> delete(String id) async {
    _plays.removeWhere((p) => p.id == id);
  }
}

void main() {
  testWidgets('App shell renders the court editor prototype', (WidgetTester tester) async {
    await tester.pumpWidget(const CxpApp());

    expect(find.byType(CourtEditorScreen), findsOneWidget);
    expect(find.text('Untitled Play'), findsOneWidget);
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

  group('CXP.15 local persistence', () {
    test('SavedPlay round-trips through JSON, including paths and multiple frames', () {
      final original = SavedPlay(
        id: 'play_1',
        name: 'Horns Twist',
        frames: [
          PlayFrameData(
            actors: defaultBasketballFrame(),
            paths: const [
              ActorPath(actorId: 'off_0', type: PathType.pass, points: [Offset(0.1, 0.2), Offset(0.3, 0.4)]),
            ],
          ),
          PlayFrameData(actors: stressTestFrames(frameCount: 2)[1]),
        ],
        createdAt: DateTime.utc(2026, 7, 10, 12, 0),
      );

      final restored = SavedPlay.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.createdAt, original.createdAt);
      expect(restored.frames.length, original.frames.length);
      expect(restored.frames.first.paths.single.type, PathType.pass);
      expect(restored.frames.first.paths.single.points.first.dx, closeTo(0.1, 1e-9));
      expect(restored.frames.first.actors.length, original.frames.first.actors.length);
    });

    test('_FakePlayRepository save/loadAll/delete round-trip (validates the interface contract)', () async {
      final repo = _FakePlayRepository();
      final play = SavedPlay(id: 'p1', name: 'Test Play', frames: defaultPlayFrames(), createdAt: DateTime.now());

      expect(await repo.loadAll(), isEmpty);

      await repo.save(play);
      expect((await repo.loadAll()).map((p) => p.id), [play.id]);

      // Saving again with the same id overwrites rather than duplicates.
      final renamed = play.copyWith(name: 'Renamed');
      await repo.save(renamed);
      final afterRename = await repo.loadAll();
      expect(afterRename.length, 1);
      expect(afterRename.single.name, 'Renamed');

      await repo.delete(play.id);
      expect(await repo.loadAll(), isEmpty);
    });

    testWidgets('Save prompts for a name, persists the play, and updates the app bar title', (
      WidgetTester tester,
    ) async {
      final repo = _FakePlayRepository();
      await tester.pumpWidget(MaterialApp(home: CourtEditorScreen(repository: repo)));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.save_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Save play'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Horns Twist');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Horns Twist'), findsWidgets); // app bar title
      final saved = await repo.loadAll();
      expect(saved, hasLength(1));
      expect(saved.single.name, 'Horns Twist');
    });

    testWidgets('My Plays lists a saved play; tapping it loads it back into the editor', (
      WidgetTester tester,
    ) async {
      final repo = _FakePlayRepository();
      await repo.save(
        SavedPlay(id: 'preexisting', name: 'Preexisting Play', frames: defaultPlayFrames(), createdAt: DateTime.now()),
      );
      await tester.pumpWidget(MaterialApp(home: CourtEditorScreen(repository: repo)));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.folder_open));
      await tester.pumpAndSettle();

      expect(find.byType(PlayLibraryScreen), findsOneWidget);
      expect(find.text('Preexisting Play'), findsOneWidget);

      await tester.tap(find.text('Preexisting Play'));
      await tester.pumpAndSettle();

      // Back on the editor, the app bar title reflects the loaded play.
      expect(find.text('Preexisting Play'), findsOneWidget);
    });

    testWidgets('My Plays delete button removes the play from the repository', (WidgetTester tester) async {
      final repo = _FakePlayRepository();
      await repo.save(
        SavedPlay(id: 'to_delete', name: 'Delete Me', frames: defaultPlayFrames(), createdAt: DateTime.now()),
      );
      await tester.pumpWidget(MaterialApp(home: CourtEditorScreen(repository: repo)));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.folder_open));
      await tester.pumpAndSettle();
      expect(find.text('Delete Me'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsNothing);
      expect(find.text('No saved plays yet.'), findsOneWidget);
      expect(await repo.loadAll(), isEmpty);
    });

    testWidgets('Reset clears play identity so Save creates a new record instead of overwriting', (
      WidgetTester tester,
    ) async {
      final repo = _FakePlayRepository();
      await tester.pumpWidget(MaterialApp(home: CourtEditorScreen(repository: repo)));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.save_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'First Play');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(await repo.loadAll(), hasLength(1));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.restart_alt));
      await tester.pumpAndSettle();
      expect(find.text('Untitled Play'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.save_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Second Play');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final all = await repo.loadAll();
      expect(all.map((p) => p.name).toSet(), {'First Play', 'Second Play'});
    });
  });
}
