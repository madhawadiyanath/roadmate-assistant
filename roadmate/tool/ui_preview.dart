// TEMPORARY visual-check harness (not part of the app): runs every screen
// against an in-memory fake Firestore seeded with the Figma sample data.
//   flutter run -d web-server --web-port 8099 -t tool/ui_preview.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/emergency_contacts_screen.dart';
import 'package:roadmate/screens/notifications_screen.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/screens/request_history_screen.dart';
import 'package:roadmate/screens/saved_vehicles_screen.dart';
import 'package:roadmate/screens/vehicle_details_screen.dart';
import 'package:roadmate/screens/vehicle_form_screen.dart';
import 'package:roadmate/services/assistance_service.dart';
import 'package:roadmate/services/emergency_contact_service.dart';
import 'package:roadmate/services/notification_service.dart';
import 'package:roadmate/services/vehicle_service.dart';

const uid = 'u1';
const user = AppUser(
  uid: uid,
  name: 'Nimal Perera',
  email: 'nimal.perera@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

late FakeFirebaseFirestore db;
late VehicleService vehicles;
late EmergencyContactService contacts;
late NotificationService notifications;
late AssistanceService assistance;
String firstVehicleId = '';

Future<void> seed() async {
  db = FakeFirebaseFirestore();
  vehicles = VehicleService(db: db);
  contacts = EmergencyContactService(db: db);
  notifications = NotificationService(db: db);
  assistance = AssistanceService(db: db);

  Vehicle v(String make, String model, int year, String plate,
          VehicleType t, String fuel, String color) =>
      Vehicle(
          id: '', make: make, model: model, year: year, plateNo: plate,
          type: t, fuelType: fuel, color: color);
  firstVehicleId = await vehicles.addVehicle(uid,
      v('Toyota', 'Corolla', 2020, 'CAK 1234', VehicleType.car, 'Petrol', 'Blue'));
  await vehicles.addVehicle(uid,
      v('Honda', 'Beat', 2021, 'BBF 5678', VehicleType.bike, 'Petrol', 'Yellow'));
  await vehicles.addVehicle(uid,
      v('Toyota', 'Hiace', 2018, 'PX 7708', VehicleType.van, 'Diesel', 'White'));
  await vehicles.addVehicle(uid,
      v('Suzuki', 'Wagon R', 2017, 'CBA 9021', VehicleType.car, 'Petrol', 'Silver'));
  // Spread createdAt so the list order is deterministic.
  final col = db.collection('users').doc(uid).collection('vehicles');
  final docs = await col.get();
  var i = 0;
  for (final d in docs.docs) {
    await d.reference.update({'createdAt': DateTime(2026, 3, 12 + i++)});
  }

  final cc = db.collection('users').doc(uid).collection('emergencyContacts');
  var k = 0;
  for (final c in [
    ('Kamala Perera', '+94 77 234 5678', 'family'),
    ('Dilini Perera', '+94 71 345 6789', 'spouse'),
    ('Ruwan Silva', '+94 76 456 7890', 'friend'),
    ('Sunil Fernando', '+94 70 567 8901', 'colleague'),
  ]) {
    await cc.add({
      'name': c.$1,
      'phone': c.$2,
      'relation': c.$3,
      'createdAt': DateTime(2026, 5, 1, 9, k++),
    });
  }

  final now = DateTime.now();
  final nc = db.collection('users').doc(uid).collection('notifications');
  Future<void> n(String type, String title, String body, Duration ago,
      {bool read = false}) {
    return nc.add({
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'senderUid': 's1',
      'createdAt': now.subtract(ago),
    });
  }

  await n('accepted', 'Mechanic accepted your request',
      'Sampath Perera is on the way to Main St, Colombo 03.',
      const Duration(minutes: 2));
  await n('arriving', 'Technician is arriving',
      'Patrol Unit #04 is about 4 minutes away.', const Duration(minutes: 8));
  await n('message', 'New message',
      'Sampath: "I\'m at the Main Street junction."',
      const Duration(minutes: 12));
  await n('completed', 'Job completed',
      'Flatbed towing #RM1058 is finished. Rate your experience.',
      const Duration(hours: 26), read: true);
  await n('receipt', 'Receipt emailed',
      'Rs. 3,500.00 receipt sent to nimal.perera@example.com.',
      const Duration(hours: 26, minutes: -3), read: true);
  await n('cancelled', 'Request cancelled',
      'Tire replacement #RM1019 was cancelled.', const Duration(days: 35),
      read: true);

  Future<void> r(String type, String status, DateTime at, double fee,
      String ref) {
    return db.collection('requests').add({
      'driverUid': uid,
      'driverName': 'Nimal Perera',
      'type': type,
      'status': status,
      'totalFee': fee,
      'refCode': ref,
      'mechanicName': 'Sampath Perera',
      'createdAt': at,
    });
  }

  await r('general', 'accepted',
      DateTime(now.year, now.month, now.day, 9, 12), 4200, '#RM1074');
  await r('towing', 'completed', DateTime(2026, 9, 28, 18, 40), 3500, '#RM1058');
  await r('jumpStart', 'completed', DateTime(2026, 9, 14, 8, 5), 2200, '#RM1031');
  await r('flatTyre', 'cancelled', DateTime(2026, 9, 2, 16, 30), 0, '#RM1019');
  await r('general', 'completed', DateTime(2026, 8, 19, 11, 20), 6750, '#RM0987');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seed();
  runApp(const Preview());
}

class Preview extends StatelessWidget {
  const Preview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadMate preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2A66)),
      ),
      home: const Gallery(),
    );
  }
}

class Gallery extends StatelessWidget {
  const Gallery({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final items = <(String, Widget Function())>[
      ('Driver dashboard (full app)', () => DriverDashboardScreen(
            user: user,
            assistanceService: assistance,
            vehicleService: vehicles,
            notificationService: notifications,
          )),
      ('Profile', () => const ProfileScreen(user: user)),
      ('Saved Vehicles', () => SavedVehiclesScreen(uid: uid, service: vehicles)),
      ('Vehicle Details', () => VehicleDetailsScreen(
          uid: uid, vehicleId: firstVehicleId, service: vehicles)),
      ('Add Vehicle form',
          () => VehicleFormScreen(uid: uid, service: vehicles)),
      ('Emergency Contacts',
          () => EmergencyContactsScreen(uid: uid, service: contacts)),
      ('Request History',
          () => RequestHistoryScreen(uid: uid, service: assistance)),
      ('Notifications',
          () => NotificationsScreen(uid: uid, service: notifications)),
      ('-- no-Firebase states --', () => const SizedBox()),
      ('Saved Vehicles (not connected)',
          () => const SavedVehiclesScreen(uid: uid)),
      ('Emergency Contacts (not connected)',
          () => const EmergencyContactsScreen(uid: uid)),
      ('Request History (not connected)',
          () => const RequestHistoryScreen(uid: uid)),
      ('Notifications (not connected)',
          () => const NotificationsScreen(uid: uid)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('RoadMate UI preview')),
      body: ListView(
        children: [
          for (final it in items)
            ListTile(
              title: Text(it.$1),
              enabled: !it.$1.startsWith('--'),
              onTap: () => open(it.$2()),
            ),
        ],
      ),
    );
  }
}
