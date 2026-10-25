import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_of_iot/main.dart';
import 'package:world_of_iot/services/api_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService().init();
  });

  testWidgets('WorldOfItApp unauthenticated smoke test',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const WorldOfItApp());
    await tester.pumpAndSettle();

    // Verify title and subtitle
    expect(find.text('World of IT'), findsOneWidget);
    expect(find.text('Cross-Device Remote Actions & Clipboard Sync'),
        findsOneWidget);

    // Verify AuthScreen tabs and button
    expect(find.text('Sign In'), findsNWidgets(2));
    expect(find.text('Create Account'), findsOneWidget);

    // Verify input fields
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
