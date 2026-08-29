import 'package:flutter_test/flutter_test.dart';
import 'package:tinycare_mobile/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TinyCareApp());
    
    // Verify the app renders without errors
    expect(find.byType(TinyCareApp), findsOneWidget);
  });

  testWidgets('App should display TinyCare title', (WidgetTester tester) async {
    await tester.pumpWidget(const TinyCareApp());
    
    // Check if TinyCare title is displayed
    expect(find.text('TinyCare'), findsWidgets);
  });
}
