import 'package:flutter_test/flutter_test.dart';
import 'package:convoy/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConvoyApp());

    // Basic assertion that the widget builds
    expect(find.byType(ConvoyApp), findsOneWidget);
  });
}
