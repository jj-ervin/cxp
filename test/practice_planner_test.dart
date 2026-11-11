import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cxp/features/practice_planner/drill_library_screen.dart';
import 'package:cxp/features/practice_planner/practice_planner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starter drills have stable IDs and usable coaching instructions', () {
    expect(starterDrills.length, 8);
    expect(starterDrills.map((d) => d.id).toSet().length, starterDrills.length);
    for (final drill in starterDrills) {
      expect(drill.minutes, greaterThan(0));
      expect(drill.objective.trim(), isNotEmpty);
      expect(drill.equipment.trim(), isNotEmpty);
      expect(drill.steps, isNotEmpty);
      expect(drill.coachingCues, isNotEmpty);
    }
  });

  testWidgets('drill library searches and filters', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DrillLibraryScreen()));
    expect(find.text('8 drills'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'form shooting');
    await tester.pumpAndSettle();

    expect(find.text('1 drills'), findsOneWidget);
    expect(find.text('Form shooting'), findsOneWidget);
    expect(find.text('Ball handling stations'), findsNothing);
  });

  testWidgets('selected drill returns to team practice planner', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PracticePlannerScreen(teamId: 'test-team', teamName: 'Test Team'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse drill library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dynamic warm-up'));
    await tester.pumpAndSettle();
    expect(find.text('Instructions'), findsOneWidget);

    await tester.tap(find.text('Add to practice'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 10 minutes'), findsOneWidget);
    expect(find.text('Dynamic warm-up'), findsOneWidget);
  });
}
