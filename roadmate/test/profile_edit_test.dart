import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/profile_screen.dart';

const _user = AppUser(
  uid: 'u1',
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
  vehicle: 'Toyota Axio',
  plate: 'ABC 1234',
);

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(920, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('edit mode: photo placeholder, Cancel, no Verified badge',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen(user: _user)));
    await tester.pumpAndSettle();

    // View mode.
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Change photo'), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Edit mode matches the design: photo block, explicit buttons.
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('profile photo'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Verified'), findsNothing); // no phone verification yet
    expect(find.text('Logout'), findsNothing);

    // Photo upload is not built: tapping says so instead of failing.
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle(); // snackbar fully in, its timer running
    expect(find.text('Photo upload is not available yet.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(); // ...and out, so it cannot cover buttons

    // Type something, then Cancel → back to view mode, values restored.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Someone Else');
    await tester.enterText(fields.at(1), '0');
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Someone Else'), findsNothing);
    final name = tester.widget<TextField>(fields.at(0));
    final tel = tester.widget<TextField>(fields.at(1));
    expect(name.controller!.text, 'Kasun Perera');
    expect(tel.controller!.text, '+94771234567');

    // Edit again: still the saved values.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Kasun Perera'), findsWidgets);
  });
}
