import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';
import 'package:cxp/features/court_editor/court_editor_screen.dart';

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
}
