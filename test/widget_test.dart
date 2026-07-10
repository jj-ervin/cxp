import 'package:flutter_test/flutter_test.dart';

import 'package:cxp/main.dart';

void main() {
  testWidgets('App shell renders placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const CxpApp());

    expect(find.text('CXP — Coach Experience Platform'), findsOneWidget);
  });
}
