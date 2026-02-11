// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:chikitsa_cloud/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our login screen is present.
    expect(find.text('ChikitsaCloud'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Sign Up'), findsOneWidget);

    // Initial state (Login)
    expect(find.text('Create Account'), findsNothing);
    
    // Tap Sign Up
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    
    // Verify Sign Up state
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Create Password'), findsOneWidget);
  });
}
