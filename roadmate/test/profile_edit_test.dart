import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/emergency_contact.dart';
import 'package:roadmate/models/garage_profile.dart';
import 'package:roadmate/models/mechanic_service.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/services/emergency_contact_service.dart';
import 'package:roadmate/services/garage_service.dart';
import 'package:roadmate/services/mechanic_service_service.dart';
import 'package:roadmate/services/vehicle_service.dart';

const _driver = AppUser(
  uid: 'u1',
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

const _mechanic = AppUser(
  uid: 'm1',
  name: 'Sampath Perera',
  email: 's@example.com',
  phone: '+94770000000',
  role: AppRole.mechanic,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(home: home);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('driver view: photo, name, role, menu, logout — no vehicle data',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen(user: _driver)));
    await tester.pumpAndSettle();

    expect(find.text('profile photo'), findsOneWidget);
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    for (final row in [
      'Personal Information',
      'Vehicle Information',
      'Emergency Contacts',
      'Payment Methods',
      'Transaction History',
      'Documents',
      'Change Password',
    ]) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    expect(find.text('Services Offered'), findsNothing); // mechanic-only
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(7));
    expect(find.text('Logout'), findsOneWidget);

    // The old inline vehicle section and its demo data are gone.
    expect(find.text('Vehicle Details'), findsNothing);
    expect(find.text('Toyota Axio'), findsNothing);
    expect(find.text('ABC 1234'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('mechanic view: Services Offered, no vehicle entries',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen(user: _mechanic)));
    await tester.pumpAndSettle();

    expect(find.text('Mechanic'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Services Offered'), findsOneWidget);
    expect(find.text('Garage & Workshop Details'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Vehicle Information'), findsNothing);
    expect(find.text('Emergency Contacts'), findsNothing);
  });

  testWidgets('Personal Information opens name/phone edit; Cancel reverts',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen(user: _driver)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('profile photo'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    // Only name + phone are editable; email is read-only; no vehicle fields.
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Vehicle Model'), findsNothing);
    expect(find.text('Plate Number'), findsNothing);
    expect(find.text('Verified'), findsNothing); // no phone verification yet
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);

    // Photo upload is not built: tapping says so instead of failing.
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();
    expect(find.text('Photo upload is not available yet.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Someone Else');
    await tester.enterText(fields.at(1), '0');
    await _tap(tester, find.text('Cancel'));

    // Back to the menu; reopening shows the saved values again.
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Someone Else'), findsNothing);
    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fields.at(0)).controller!.text,
        'Kasun Perera');
    expect(tester.widget<TextField>(fields.at(1)).controller!.text,
        '+94771234567');
  });

  testWidgets('Vehicle Information opens Saved Vehicles (live data)',
      (tester) async {
    _phone(tester);
    final db = FakeFirebaseFirestore();
    final vehicles = VehicleService(db: db);
    await vehicles.addVehicle(
        'u1',
        const Vehicle(
            id: '',
            make: 'Toyota',
            model: 'Corolla',
            year: 2020,
            plateNo: 'CAK 1234'));
    await tester.pumpWidget(
        _app(ProfileScreen(user: _driver, vehicleService: vehicles)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vehicle Information'));
    await tester.pumpAndSettle();
    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsOneWidget);

    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
  });

  testWidgets('Emergency Contacts row opens the contacts page',
      (tester) async {
    _phone(tester);
    final db = FakeFirebaseFirestore();
    final contacts = EmergencyContactService(db: db);
    await contacts.addContact(
        'u1',
        const EmergencyContact(
            id: '', name: 'Kamala Perera', phone: '0772345678'));
    await tester.pumpWidget(
        _app(ProfileScreen(user: _driver, contactService: contacts)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergency Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Add Emergency Contact'), findsOneWidget);
    expect(find.text('Kamala Perera'), findsOneWidget);
  });

  testWidgets('Documents shows a Coming soon page', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen(user: _driver)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.textContaining('is not available yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
  });

  testWidgets('Services Offered opens the services offered page', (tester) async {
    _phone(tester);
    final db = FakeFirebaseFirestore();
    final services = MechanicServiceService(db: db);
    await services.addService(
      'm1',
      const MechanicService(
        id: '',
        title: 'Emergency Towing',
        category: ServiceCategory.towing,
        basePrice: 5000,
      ),
    );
    await tester.pumpWidget(
      _app(ProfileScreen(user: _mechanic, mechanicServiceService: services)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services Offered'));
    await tester.pumpAndSettle();
    expect(find.text('Services Offered'), findsOneWidget);
    expect(find.text('Emergency Towing'), findsOneWidget);
    expect(find.text('Add Service'), findsOneWidget);

    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
  });

  testWidgets('Garage & Workshop Details opens the garage profile page',
      (tester) async {
    _phone(tester);
    final db = FakeFirebaseFirestore();
    final garageService = GarageService(db: db);
    await garageService.saveGarageProfile(
      'm1',
      const GarageProfile(
        ownerUid: 'm1',
        garageName: 'City Center Motors',
        registrationNumber: 'BR-9901',
      ),
    );
    await tester.pumpWidget(
      _app(ProfileScreen(user: _mechanic, garageService: garageService)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Garage & Workshop Details'));
    await tester.pumpAndSettle();
    expect(find.text('Garage Profile'), findsOneWidget);
    expect(find.text('City Center Motors'), findsOneWidget);

    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
  });

  testWidgets('Logout asks first, Cancel keeps the profile', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen(user: _driver)));
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Logout'));
    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);

    await _tap(tester, find.text('Logout'));
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Logout')));
    await tester.pumpAndSettle();
    expect(find.text('Help on the road, always with you.'), findsOneWidget);
  });
}
