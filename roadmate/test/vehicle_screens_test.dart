import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/saved_vehicles_screen.dart';
import 'package:roadmate/screens/vehicle_details_screen.dart';
import 'package:roadmate/services/vehicle_service.dart';

const _uid = 'u1';

const _user = AppUser(
  uid: _uid,
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

Vehicle _v(String make, String model, String plate,
        {int year = 2020, VehicleType type = VehicleType.car}) =>
    Vehicle(
      id: '',
      make: make,
      model: model,
      year: year,
      plateNo: plate,
      type: type,
      fuelType: 'Petrol',
      color: 'Blue',
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(home: home);

/// SnackBars float over the bottom buttons until their timer ends.
Future<void> _dismissSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore db;
  late VehicleService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = VehicleService(db: db);
  });

  testWidgets('Saved Vehicles says Firebase is not connected', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const SavedVehiclesScreen(uid: _uid)));
    await tester.pumpAndSettle();

    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('Firebase not connected'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsOneWidget);
  });

  testWidgets('Saved Vehicles empty state', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
        _app(SavedVehiclesScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();

    expect(find.text('No vehicles yet'), findsOneWidget);
    expect(find.text('0 vehicles'), findsOneWidget);
  });

  testWidgets('Saved Vehicles lists cards with default tag and count',
      (tester) async {
    _phone(tester);
    await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
    await service.addVehicle(
        _uid, _v('Honda', 'Beat', 'BBF 5678', year: 2021, type: VehicleType.bike));
    await tester.pumpWidget(
        _app(SavedVehiclesScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();

    expect(find.text('2 vehicles'), findsOneWidget);
    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Honda Beat'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('CAK 1234'), findsOneWidget);
    expect(find.text('2021'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('Plate No'), findsNWidgets(2));
    expect(find.text('Add Vehicle'), findsOneWidget);
  });

  testWidgets('Add Vehicle validates, then saves and lists the vehicle',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(
        _app(SavedVehiclesScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Add Vehicle'), findsOneWidget); // form title

    // Empty submit → inline errors, nothing saved.
    await tester.ensureVisible(find.text('Save Vehicle'));
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the make'), findsOneWidget);
    expect(find.text('Enter the model'), findsOneWidget);
    expect(find.text('Enter the registration number'), findsOneWidget);
    expect(find.textContaining('Enter a year between'), findsOneWidget);
    expect(await service.watchVehicles(_uid).first, isEmpty);

    // Out-of-range year is rejected too.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Suzuki');
    await tester.enterText(fields.at(1), 'Wagon R');
    await tester.enterText(fields.at(2), '1800');
    await tester.enterText(fields.at(3), 'cba 9021');
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a year between'), findsOneWidget);
    expect(find.text('Enter the make'), findsNothing);

    await tester.enterText(fields.at(2), '2017');
    await tester.tap(find.text('Van'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Vehicle'));
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();

    // Back on the list with the new (default) vehicle.
    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('Suzuki Wagon R'), findsOneWidget);
    expect(find.text('CBA 9021'), findsOneWidget); // upper-cased
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('1 vehicle'), findsOneWidget);

    final saved = (await service.watchVehicles(_uid).first).single;
    expect(saved.type, VehicleType.van);
    expect(saved.year, 2017);
    expect(saved.isDefault, isTrue);
  });

  testWidgets('Details show every row; set default; edit keeps default',
      (tester) async {
    _phone(tester);
    await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
    final honda = await service.addVehicle(
        _uid, _v('Honda', 'Beat', 'BBF 5678', year: 2021));

    await tester.pumpWidget(_app(
        VehicleDetailsScreen(uid: _uid, vehicleId: honda, service: service)));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.text('Honda Beat'), findsOneWidget);
    expect(find.textContaining('Added '), findsOneWidget);
    for (final label in [
      'Make',
      'Model',
      'Year',
      'Registration No',
      'Vehicle Type',
      'Color',
      'Fuel Type',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // Fuel Type sits directly below Color.
    expect(tester.getTopLeft(find.text('Fuel Type')).dy,
        greaterThan(tester.getTopLeft(find.text('Color')).dy));
    expect(find.text('Petrol'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Default'), findsNothing);

    // Set as default → link goes away, tag appears (live stream).
    await tester.tap(find.text('Set as default'));
    await tester.pumpAndSettle();
    expect(find.text('Set as default'), findsNothing);
    expect(find.text('Default'), findsOneWidget);
    await _dismissSnackBars(tester);

    // Edit → change model, default flag untouched.
    await _tapVisible(tester, find.text('Edit'));
    expect(find.text('Edit Vehicle'), findsOneWidget);
    expect(find.text('Honda'), findsOneWidget); // prefilled
    await tester.enterText(find.byType(TextField).at(1), 'Dio');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Honda Dio'), findsOneWidget); // updated live
    expect(find.text('Default'), findsOneWidget);
    final list = await service.watchVehicles(_uid).first;
    expect(list.first.id, honda);
    expect(list.where((v) => v.isDefault), hasLength(1));
  });

  testWidgets('Delete asks first, then removes and returns to the list',
      (tester) async {
    _phone(tester);
    final a = await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
    await service.addVehicle(_uid, _v('Honda', 'Beat', 'BBF 5678'));
    await tester.pumpWidget(
        _app(SavedVehiclesScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toyota Corolla'));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Details'), findsOneWidget);

    // Cancel keeps it.
    await _tapVisible(tester, find.text('Delete'));
    expect(find.text('Delete vehicle?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(await service.watchVehicles(_uid).first, hasLength(2));

    // Confirm deletes; page closes; the other vehicle is promoted.
    await _tapVisible(tester, find.text('Delete'));
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Delete')));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Details'), findsNothing);
    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('Toyota Corolla'), findsNothing);
    expect(find.text('1 vehicle'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect((await service.watchVehicles(_uid).first).single.isDefault, isTrue);
    final gone = await db
        .collection('users')
        .doc(_uid)
        .collection('vehicles')
        .doc(a)
        .get();
    expect(gone.exists, isFalse);
  });

  testWidgets('Details page closes when the vehicle is deleted elsewhere',
      (tester) async {
    _phone(tester);
    final a = await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
    await tester.pumpWidget(
        _app(SavedVehiclesScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toyota Corolla'));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Details'), findsOneWidget);

    await service.deleteVehicle(_uid, a);
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Details'), findsNothing);
    expect(find.text('Saved Vehicles'), findsOneWidget);
  });

  group('driver dashboard', () {
    testWidgets('Garage tab is the live Saved Vehicles view', (tester) async {
      _phone(tester);
      await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
      await tester.pumpWidget(_app(
          DriverDashboardScreen(user: _user, vehicleService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Garage'));
      await tester.pumpAndSettle();

      expect(find.text('My Garage'), findsNothing); // old hardcoded tab
      expect(find.text('Saved Vehicles'), findsOneWidget);
      expect(find.text('Toyota Corolla'), findsOneWidget);
      expect(find.text('1 vehicle'), findsOneWidget);

      // Back arrow returns to Home.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Kasun'), findsOneWidget);
    });

    testWidgets('Home vehicle card follows the default vehicle',
        (tester) async {
      _phone(tester);
      await service.addVehicle(_uid, _v('Toyota', 'Corolla', 'CAK 1234'));
      final b = await service.addVehicle(_uid, _v('Honda', 'Beat', 'BBF 5678'));
      await tester.pumpWidget(_app(
          DriverDashboardScreen(user: _user, vehicleService: service)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('REGISTERED VEHICLE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Toyota Corolla • CAK 1234'), findsOneWidget);
      expect(find.text('Toyota Axio • ABC 1234'), findsNothing); // no demo

      await service.setDefault(_uid, b);
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat • BBF 5678'), findsOneWidget);
      expect(find.text('Toyota Corolla • CAK 1234'), findsNothing);
    });

    testWidgets('Home vehicle card prompts when nothing is saved',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
          DriverDashboardScreen(user: _user, vehicleService: service)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('REGISTERED VEHICLE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No vehicle saved — tap to add'), findsOneWidget);
      expect(find.text('Toyota Axio • ABC 1234'), findsNothing);
    });

    testWidgets('Logout works from the Home tab', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
          DriverDashboardScreen(user: _user, vehicleService: service)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Logout'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Logout')));
      await tester.pumpAndSettle();

      expect(find.text('Help on the road, always with you.'), findsOneWidget);
      expect(find.text('Hello, Kasun'), findsNothing);
    });
  });
}
