import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_capsule/main.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The MyApp widget does not take isFirebaseReady in its constructor.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title "Legacy Capsule" is present on the splash screen.
    expect(find.text('Legacy Capsule'), findsOneWidget);
    
    // Verify that the "Loading..." text is present.
    expect(find.text('Loading...'), findsOneWidget);
  });
}
