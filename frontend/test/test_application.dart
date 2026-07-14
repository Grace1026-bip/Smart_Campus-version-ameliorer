import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_campus_app/application.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Smart Faculty launches on login screen', (tester) async {
    await tester.pumpWidget(const SmartFacultyApp());
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('FASI Smart Faculty'), findsWidgets);
  });
}
