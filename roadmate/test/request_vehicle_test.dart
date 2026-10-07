import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/screens/confirm_request_screen.dart';
import 'package:roadmate/screens/payment_review_screen.dart';
import 'package:roadmate/screens/request_success_screen.dart';
import 'package:roadmate/services/assistance_service.dart';
import 'package:roadmate/services/vehicle_service.dart';

const _user = AppUser(
  uid: 'u1',
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

const _address = 'No. 25, Galle Road, Colombo 06';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Vehicle _v(String make, String model, String plate) => Vehicle(
    id: '', make: make, model: model, year: 2020, plateNo: plate);

void main() {
  late FakeFirebaseFirestore db;
  late VehicleService vehicles;

  setUp(() {
    db = FakeFirebaseFirestore();
    vehicles = VehicleService(db: db);
  });

  group('Confirm Request shows the default vehicle', () {
    Future<void> pump(WidgetTester tester, {VehicleService? service}) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(
        home: ConfirmRequestScreen(
          user: _user,
          serviceType: AssistanceType.flatTyre,
          address: _address,
          vehicleService: service,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('default vehicle, and it follows a change of default',
        (tester) async {
      await vehicles.addVehicle(_user.uid, _v('Toyota', 'Corolla', 'CAK 1234'));
      final beat =
          await vehicles.addVehicle(_user.uid, _v('Honda', 'Beat', 'BBF 5678'));
      await pump(tester, service: vehicles);

      expect(find.text('Toyota Corolla (CAK 1234)'), findsOneWidget);
      expect(find.text('Toyota Axio (ABC 1234)'), findsNothing); // no demo

      await vehicles.setDefault(_user.uid, beat);
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat (BBF 5678)'), findsOneWidget);
    });

    testWidgets('"No vehicle selected" when none is saved', (tester) async {
      await pump(tester, service: vehicles);
      expect(find.text('No vehicle selected'), findsOneWidget);
      expect(find.text('Toyota Axio (ABC 1234)'), findsNothing);
    });

    testWidgets('"No vehicle selected" when Firebase is not connected',
        (tester) async {
      await pump(tester);
      expect(find.text('No vehicle selected'), findsOneWidget);
    });

    testWidgets('Vehicle row opens Saved Vehicles; adding one fills the row',
        (tester) async {
      await pump(tester, service: vehicles);
      expect(find.text('No vehicle selected'), findsOneWidget);

      await tester.tap(find.text('No vehicle selected'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Vehicles'), findsOneWidget);
      expect(find.text('Vehicle editing coming soon.'), findsNothing);

      // Add a vehicle from there.
      await tester.tap(find.text('Add Vehicle'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Nissan');
      await tester.enterText(fields.at(1), 'Leaf');
      await tester.enterText(fields.at(2), '2019');
      await tester.enterText(fields.at(3), 'cba 5555');
      await tester.ensureVisible(find.text('Save Vehicle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Vehicle'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Vehicles'), findsOneWidget);
      expect(find.text('Nissan Leaf'), findsOneWidget);

      // Back on Confirm Request the row shows the new default vehicle.
      await tester.pump(const Duration(seconds: 5)); // snackbar timer
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Request'), findsOneWidget);
      expect(find.text('Nissan Leaf (CBA 5555)'), findsOneWidget);
    });

    testWidgets('Vehicle row still opens the garage without Firebase',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('No vehicle selected'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Vehicles'), findsOneWidget);
      expect(find.text('Firebase not connected'), findsOneWidget);
    });
  });

  group('Payment snapshots the default vehicle onto the request', () {
    Future<void> submit(WidgetTester tester) async {
      // 800 logical px wide: the payment page overflows on phone widths
      // (existing layout issue, not part of this change).
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      firebaseReady = true;
      addTearDown(() => firebaseReady = false);
      await tester.pumpWidget(MaterialApp(
        home: PaymentReviewScreen(
          user: _user,
          serviceType: AssistanceType.flatTyre,
          address: _address,
          assistanceService: AssistanceService(db: db),
          vehicleService: vehicles,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Complete & Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete & Submit'));
      await tester.pumpAndSettle();
    }

    testWidgets('with a default vehicle', (tester) async {
      await vehicles.addVehicle(_user.uid, _v('Toyota', 'Corolla', 'CAK 1234'));
      await vehicles.addVehicle(_user.uid, _v('Honda', 'Beat', 'BBF 5678'));
      await submit(tester);

      expect(find.byType(RequestSuccessScreen), findsOneWidget);
      expect(find.text('Toyota Corolla • CAK 1234'), findsOneWidget);

      final docs = (await db.collection('requests').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.single.data()['vehicle'], 'Toyota Corolla');
      expect(docs.single.data()['plate'], 'CAK 1234');
      expect(docs.single.data()['driverUid'], 'u1');
    });

    testWidgets('with no saved vehicle: blank snapshot, no demo text',
        (tester) async {
      await submit(tester);

      expect(find.byType(RequestSuccessScreen), findsOneWidget);
      expect(find.text('No vehicle selected'), findsOneWidget);
      expect(find.textContaining('Toyota Axio'), findsNothing);

      final doc = (await db.collection('requests').get()).docs.single.data();
      expect(doc['vehicle'], '');
      expect(doc['plate'], '');
    });
  });

  test('getDefaultVehicle returns the default or null', () async {
    expect(await vehicles.getDefaultVehicle('u1'), isNull);
    await vehicles.addVehicle('u1', _v('Toyota', 'Corolla', 'CAK 1234'));
    final b = await vehicles.addVehicle('u1', _v('Honda', 'Beat', 'BBF 5678'));
    expect((await vehicles.getDefaultVehicle('u1'))?.make, 'Toyota');
    await vehicles.setDefault('u1', b);
    expect((await vehicles.getDefaultVehicle('u1'))?.id, b);
  });

  test('ServiceRequest.vehicleDisplay has no demo fallback', () {
    ServiceRequest r(String v, String p) => ServiceRequest(
        id: 'x',
        driverUid: 'u1',
        driverName: 'K',
        type: AssistanceType.towing,
        status: RequestStatus.pending,
        vehicle: v,
        plate: p);
    expect(r('', '').vehicleDisplay, 'No vehicle selected');
    expect(r('Toyota Corolla', 'CAK 1234').vehicleDisplay,
        'Toyota Corolla • CAK 1234');
    expect(r('Toyota Corolla', '').vehicleDisplay, 'Toyota Corolla');
  });

  test('AppUser has no vehicle fields and writes none', () {
    FakeFirebaseFirestore(); // FieldValue needs the fake factory
    final map = _user.toMap();
    expect(map.containsKey('vehicle'), isFalse);
    expect(map.containsKey('plate'), isFalse);
    // Legacy docs that still carry them load fine.
    final loaded = AppUser.fromMap('u1', {
      'name': 'K',
      'role': 'driver',
      'vehicle': 'Old',
      'plate': 'OLD 1',
    });
    expect(loaded.name, 'K');
  });
}
