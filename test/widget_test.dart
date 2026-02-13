import 'package:flutter_test/flutter_test.dart';
import 'package:ai_daddy/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AIDaddyApp());
    await tester.pump(const Duration(seconds: 4));
    // App should render without crashing
    expect(find.byType(AIDaddyApp), findsOneWidget);
  });
}
