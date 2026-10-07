import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/screens/saved_vehicles_screen.dart';
import 'package:roadmate/services/vehicle_service.dart';

const _user = AppUser(
  uid: 'u1',
  name: 'Nimal Perera',
  email: 'nimal@example.com',
  phone: '0771234567',
  role: AppRole.driver,
);

Future<VehicleService> _seeded() async {
  final svc = VehicleService(db: FakeFirebaseFirestore());
  await svc.addVehicle(
    _user.uid,
    const Vehicle(
      id: '',
      make: 'Toyota',
      model: 'Corolla',
      year: 2020,
      plateNo: 'CAK 1234',
      color: 'Blue',
    ),
  );
  await svc.addVehicle(
    _user.uid,
    const Vehicle(
      id: '',
      make: 'Honda',
      model: 'Beat',
      year: 2021,
      plateNo: 'BBF 5678',
      type: VehicleType.bike,
    ),
  );
  return svc;
}

Future<void> _pump(WidgetTester tester, VehicleService svc) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SavedVehiclesView(user: _user, vehicleService: svc),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Saved Vehicles lists vehicles with count and Default tag',
      (tester) async {
    await _pump(tester, await _seeded());

    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('2 vehicles'), findsOneWidget);
    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Honda Beat'), findsOneWidget);
    expect(find.text('CAK 1234'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no vehicles', (tester) async {
    await _pump(tester, VehicleService(db: FakeFirebaseFirestore()));
    expect(find.textContaining('No vehicles yet'), findsOneWidget);
    expect(find.text('0 vehicles'), findsOneWidget);
  });

  testWidgets('without Firebase it shows a connect message, no Add button',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SavedVehiclesView(user: _user)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Firebase is not connected'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsNothing);
  });

  testWidgets('tap opens details; Set as default and Delete work',
      (tester) async {
    final svc = await _seeded();
    await _pump(tester, svc);

    await tester.tap(find.text('Honda Beat'));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.text('Registration No'), findsOneWidget);
    expect(find.text('Bike'), findsWidgets);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Set as default vehicle'));
    await tester.pumpAndSettle();
    var list = await svc.watchVehicles(_user.uid).first;
    expect(list.firstWhere((v) => v.make == 'Honda').isDefault, isTrue);
    expect(find.text('Set as default vehicle'), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete vehicle?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Back on the list, one vehicle left.
    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('1 vehicle'), findsOneWidget);
    list = await svc.watchVehicles(_user.uid).first;
    expect(list.single.make, 'Toyota');
    expect(list.single.isDefault, isTrue);
  });

  testWidgets('Add Vehicle form validates then saves', (tester) async {
    final svc = VehicleService(db: FakeFirebaseFirestore());
    await _pump(tester, svc);

    await tester.tap(find.text('Add Vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Save Vehicle'), findsOneWidget);

    await tester.tap(find.text('Save Vehicle'));
    await tester.pump();
    expect(find.textContaining('Please enter make'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Suzuki');
    await tester.enterText(fields.at(1), 'Wagon R');
    await tester.enterText(fields.at(2), '2017');
    await tester.enterText(fields.at(3), 'cba 9021');
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Vehicles'), findsOneWidget);
    expect(find.text('Suzuki Wagon R'), findsOneWidget);
    expect(find.text('CBA 9021'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget); // first vehicle
  });

  testWidgets('Edit changes the vehicle', (tester) async {
    final svc = await _seeded();
    await _pump(tester, svc);

    await tester.tap(find.text('Toyota Corolla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Vehicle'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(4), 'Red');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
  });
}
