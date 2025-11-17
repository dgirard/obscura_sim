import 'package:flutter_test/flutter_test.dart';
import 'package:obscura_sim/main.dart';

void main() {
  testWidgets('ObscuraSim app launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ObscuraSimApp());

    // Verify that the splash screen appears with the app title
    expect(find.text('OBSCURASIM'), findsOneWidget);
    expect(find.text('Camera Obscura'), findsOneWidget);
  });
}