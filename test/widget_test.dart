import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';
import 'package:cxp/data/play_repository.dart';
import 'package:cxp/export/playbook_pdf_exporter.dart';
import 'package:cxp/features/court_editor/animation_perf_spike_screen.dart';
import 'package:cxp/features/court_editor/basketball_court_painter.dart';
import 'package:cxp/features/court_editor/court_editor_screen.dart';
import 'package:cxp/features/court_editor/frame_playback_screen.dart';
import 'package:cxp/features/court_editor/play_library_screen.dart';
import 'package:cxp/models/play_frame.dart';
import 'package:cxp/models/court_configuration.dart';
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
  group('Court configuration', () {
    test('regulation presets expose their expected boundaries', () {
      expect(dimensionsFor(CourtStandard.nba).lengthFeet, 94);
      expect(dimensionsFor(CourtStandard.ncaa).widthFeet, 50);
      expect(dimensionsFor(CourtStandard.highSchool).lengthFeet, 84);
      expect(dimensionsFor(CourtStandard.middleSchool).widthFeet, 42);
      expect(dimensionsFor(CourtStandard.fiba).lengthFeet, closeTo(91.86, 0.001));
    });

    test('custom full blacktop configuration round-trips through JSON', () {
      const dimensions = CourtDimensions(
        lengthFeet: 80,
        widthFeet: 44,
        laneWidthFeet: 12,
        freeThrowLineFeet: 19,
        threePointRadiusFeet: 20,
        cornerThreeDistanceFeet: 19,
        basketOffsetFeet: 5.25,
        restrictedArcRadiusFeet: 0,
      );
      const original = CourtConfiguration(
        standard: CourtStandard.custom,
        extent: CourtExtent.full,
        surface: CourtSurface.blacktop,
        customDimensions: dimensions,
      );

      final restored = CourtConfiguration.fromJson(original.toJson());

      expect(restored.standard, CourtStandard.custom);
      expect(restored.extent, CourtExtent.full);
      expect(restored.surface, CourtSurface.blacktop);
      expect(restored.dimensions.lengthFeet, 80);
      expect(restored.displayedLengthFeet, 80);
    });

    testWidgets('every regulation preset paints in half and full court without throwing', (
      WidgetTester tester,
    ) async {
      for (final standard in CourtStandard.values.where((value) => value != CourtStandard.custom)) {
        for (final extent in CourtExtent.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: SizedBox(
                width: 500,
                height: extent == CourtExtent.full ? 940 : 470,
                child: CustomPaint(
                  painter: BasketballCourtPainter(
                    configuration: CourtConfiguration(standard: standard, extent: extent),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '${standard.name}/${extent.name}');
        }
      }
    });

    testWidgets('court configuration control applies and saves regulation, extent, and surface choices', (
      WidgetTester tester,
    ) async {
      final repo = _FakePlayRepository();
      await tester.pumpWidget(MaterialApp(home: CourtEditorScreen(repository: repo)));

      await tester.tap(find.byTooltip('Court configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Court configuration'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('court-standard')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FIBA / European').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('court-extent')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full court').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('court-surface')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outdoor blacktop').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.save_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Configured court');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final saved = (await repo.loadAll()).single;
      expect(saved.courtConfiguration.standard, CourtStandard.fiba);
      expect(saved.courtConfiguration.extent, CourtExtent.full);
      expect(saved.courtConfiguration.surface, CourtSurface.blacktop);
    });
  });

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

  group('CXP.20 tool rail', () {
    testWidgets('exposes Select/Move plus all six path-drawing tools', (WidgetTester tester) async {
      await tester.pumpWidget(const CxpApp());

      for (final label in ['Select / Move', 'Pass', 'Dribble', 'Cut', 'Screen', 'Shot', 'Defense']) {
        expect(find.byTooltip(label), findsOneWidget, reason: 'missing tool: $label');
      }
    });
  });

  group('CXP.06 route drawing', () {
    testWidgets('dragging from an actor with the Pass tool active records a path (enables Undo)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      final undoButtonFinder = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undoButtonFinder).onPressed, isNull);

      await tester.tap(find.byTooltip('Pass'));
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

      await tester.tap(find.byTooltip('Pass'));
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
      await tester.tap(find.byTooltip('Pass'));
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
        courtConfiguration: const CourtConfiguration(
          standard: CourtStandard.highSchool,
          extent: CourtExtent.full,
          surface: CourtSurface.blacktop,
        ),
      );

      final restored = SavedPlay.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.createdAt, original.createdAt);
      expect(restored.frames.length, original.frames.length);
      expect(restored.frames.first.paths.single.type, PathType.pass);
      expect(restored.frames.first.paths.single.points.first.dx, closeTo(0.1, 1e-9));
      expect(restored.frames.first.actors.length, original.frames.first.actors.length);
      expect(restored.courtConfiguration.standard, CourtStandard.highSchool);
      expect(restored.courtConfiguration.extent, CourtExtent.full);
      expect(restored.courtConfiguration.surface, CourtSurface.blacktop);
    });

    test('SavedPlay defaults older JSON without court configuration to NBA half hardwood', () {
      final json = SavedPlay(
        id: 'legacy',
        name: 'Legacy',
        frames: defaultPlayFrames(),
        createdAt: DateTime.utc(2026, 7, 10),
      ).toJson()
        ..remove('courtConfiguration');

      final restored = SavedPlay.fromJson(json);

      expect(restored.courtConfiguration.standard, CourtStandard.nba);
      expect(restored.courtConfiguration.extent, CourtExtent.half);
      expect(restored.courtConfiguration.surface, CourtSurface.hardwood);
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

  group('CXP.16 PDF export', () {
    // These test the pure-Dart PDF byte generation directly. They
    // deliberately do NOT drive the "Export PDF" app-bar button via
    // widget tap — Printing.layoutPdf talks to a platform channel with no
    // real implementation in this test harness, the same reason CXP.03's
    // perf spike is validated as a functional pass rather than a full
    // device test. The button's presence is checked by finder only.

    test('produces non-empty bytes with a valid PDF header for a single frame, no paths', () async {
      final bytes = await buildPlaybookPdf(playName: 'Test Play', frames: defaultPlayFrames());

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('produces one page per frame across a multi-frame play', () async {
      final frames = [
        PlayFrameData(actors: defaultBasketballFrame()),
        PlayFrameData(actors: stressTestFrames(frameCount: 2)[1]),
        PlayFrameData(actors: defaultBasketballFrame()),
      ];
      final bytes = await buildPlaybookPdf(playName: 'Three Frames', frames: frames);

      // /Type /Page (without the trailing s of /Pages) appears once per
      // page object in a pdf-package-generated document — a reasonable,
      // if approximate, structural check without pulling in a PDF parser.
      final content = String.fromCharCodes(bytes);
      final pageObjectCount = RegExp(r'/Type\s*/Page[^s]').allMatches(content).length;
      expect(pageObjectCount, 3);
    });

    test('does not throw for every PathType, including dashed and screen-bar styles', () async {
      final actors = defaultBasketballFrame();
      final paths = [
        for (final type in PathType.values)
          ActorPath(actorId: actors.first.id, type: type, points: [const Offset(0.2, 0.2), const Offset(0.7, 0.6)]),
      ];
      final bytes = await buildPlaybookPdf(
        playName: 'All Path Types',
        frames: [PlayFrameData(actors: actors, paths: paths)],
      );

      expect(bytes, isNotEmpty);
    });

    test('does not throw for a zero-length path (identical start/end points)', () async {
      final actors = defaultBasketballFrame();
      final bytes = await buildPlaybookPdf(
        playName: 'Degenerate Path',
        frames: [
          PlayFrameData(
            actors: actors,
            paths: [ActorPath(actorId: actors.first.id, type: PathType.pass, points: const [Offset(0.5, 0.5), Offset(0.5, 0.5)])],
          ),
        ],
      );

      expect(bytes, isNotEmpty);
    });

    testWidgets('Export PDF button is present in the app bar', (WidgetTester tester) async {
      await tester.pumpWidget(const CxpApp());

      expect(find.widgetWithIcon(IconButton, Icons.picture_as_pdf_outlined), findsOneWidget);
    });
  });

  group('CXP.21 frame-add advances actors to their drawn path endpoint', () {
    testWidgets('an actor with a drawn path starts the next frame at the path end, not the old spot', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      final startCenter = tester.getCenter(find.text('1'));

      await tester.tap(find.byTooltip('Pass'));
      await tester.pumpAndSettle();

      const dragOffset = Offset(120, 90);
      final gesture = await tester.startGesture(startCenter);
      await gesture.moveBy(dragOffset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Still on Frame 1 — token "1" has not moved (paths are drawn,
      // not applied to the current frame's actor position).
      expect(tester.getCenter(find.text('1')), startCenter);

      await tester.tap(find.byTooltip('Select / Move'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      // On the new frame, token "1" should now sit at (approximately)
      // where the drawn path ended, not back at its Frame-1 position.
      final newCenter = tester.getCenter(find.text('1'));
      expect((newCenter - (startCenter + dragOffset)).distance, lessThan(20));
      expect((newCenter - startCenter).distance, greaterThan(50));
    });

    testWidgets('an actor with no drawn path keeps its position when a frame is added', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      final startCenter = tester.getCenter(find.text('X1'));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      expect(tester.getCenter(find.text('X1')), startCenter);
    });
  });

  group('CXP.21 ball marker', () {
    testWidgets('Ball tool assigns and clears a ball-holder badge on tap', (WidgetTester tester) async {
      await tester.pumpWidget(const CxpApp());

      final badgeFinder = find.byKey(const ValueKey('ball-badge-off_0'));
      expect(badgeFinder, findsNothing);

      await tester.tap(find.byTooltip('Ball'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(badgeFinder, findsOneWidget);

      // Tapping the same holder again clears it.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(badgeFinder, findsNothing);
    });

    testWidgets('a pass from the ball holder transfers the ball to the receiver on the next frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      // Give actor "1" the ball.
      await tester.tap(find.byTooltip('Ball'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ball-badge-off_0')), findsOneWidget);

      // Draw a pass from "1" directly onto actor "2"'s token.
      await tester.tap(find.byTooltip('Pass'));
      await tester.pumpAndSettle();
      final fromCenter = tester.getCenter(find.text('1'));
      final toCenter = tester.getCenter(find.text('2'));
      final gesture = await tester.startGesture(fromCenter);
      await gesture.moveTo(toCenter);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Select / Move'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      // The ball should now belong to actor "2" (off_1), not "1".
      expect(find.byKey(const ValueKey('ball-badge-off_0')), findsNothing);
      expect(find.byKey(const ValueKey('ball-badge-off_1')), findsOneWidget);
    });

    testWidgets('a pass followed by a cut still transfers the ball to the receiver on the next frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const CxpApp());

      await tester.tap(find.byTooltip('Ball'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      final passerCenter = tester.getCenter(find.text('1'));
      final receiverCenter = tester.getCenter(find.text('2'));

      await tester.tap(find.byTooltip('Pass'));
      await tester.pumpAndSettle();
      final passGesture = await tester.startGesture(passerCenter);
      await passGesture.moveTo(receiverCenter);
      await tester.pump();
      await passGesture.up();
      await tester.pumpAndSettle();

      // Draw the passer's relocation second. This used to overwrite the
      // pass for ball-transfer purposes because only the last path was
      // inspected when the next frame was created.
      await tester.tap(find.byTooltip('Cut'));
      await tester.pumpAndSettle();
      final cutGesture = await tester.startGesture(passerCenter);
      await cutGesture.moveBy(const Offset(-80, 100));
      await tester.pump();
      await cutGesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Select / Move'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_box));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ball-badge-off_0')), findsNothing);
      expect(find.byKey(const ValueKey('ball-badge-off_1')), findsOneWidget);
    });
  });
}
