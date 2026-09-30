import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/main.dart';

void main() {
  testWidgets('Onboarding screen shows on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Help on the road, always with you.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
