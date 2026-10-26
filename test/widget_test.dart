import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_of_iot/main.dart';
import 'package:world_of_iot/services/api_service.dart';
import 'package:world_of_iot/widgets/google_logo_icon.dart';

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
    expect(find.text('ClipSync'), findsOneWidget);
    expect(find.text('Cross-Device Remote Actions & Clipboard Sync'),
        findsOneWidget);

    // Verify AuthScreen tabs and button
    expect(find.text('Sign In'), findsNWidgets(2));
    expect(find.text('Create Account'), findsOneWidget);

    // Verify input fields
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Sign in with Google option and logo icon
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byType(GoogleLogoIcon), findsOneWidget);

    // Verify Forgot password / options link is present
    expect(find.text('Forgot password / options?'), findsOneWidget);
  });

  testWidgets('AuthScreen Create Account displays Sign up with Google and forget options',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WorldOfItApp());
    await tester.pumpAndSettle();

    // Switch to Create Account tab
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify Sign up with Google is visible on the Create Account tab
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.text('Register Account'), findsOneWidget);
    expect(find.text('Forgot account or password?'), findsOneWidget);
  });

  testWidgets('AuthScreen opens Forget Options and Account Recovery sheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WorldOfItApp());
    await tester.pumpAndSettle();

    // Tap forgot password / options
    await tester.tap(find.text('Forgot password / options?'));
    await tester.pumpAndSettle();

    // Verify bottom sheet title and recovery options
    expect(find.text('Account Recovery & Forget Options'), findsOneWidget);
    expect(find.text('Send Password Reset Link'), findsOneWidget);
    expect(find.text('Used Google Sign-In? Tap here'), findsOneWidget);
    expect(find.text('Account Email'), findsOneWidget);
  });
}
