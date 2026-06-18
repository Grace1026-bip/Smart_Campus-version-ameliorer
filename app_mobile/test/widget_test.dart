import 'package:flutter_test/flutter_test.dart';

import 'package:smart_campus_app/app.dart';

void main() {
  testWidgets('Smart Faculty launches on login screen', (tester) async {
    await tester.pumpWidget(const SmartFacultyApp());

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Smart Faculty'), findsWidgets);
  });
}
