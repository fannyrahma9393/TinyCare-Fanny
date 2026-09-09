import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycare_mobile/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TinyCareApp());

    // Verify the app renders without errors
    expect(find.byType(TinyCareApp), findsOneWidget);
  });

  testWidgets('App should display TinyCare title on login', (WidgetTester tester) async {
    // No stored session -> app settles on the login page.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TinyCareApp());
    await tester.pumpAndSettle();

    // Check if TinyCare title is displayed
    expect(find.text('TinyCare'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
