import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in RoadMate. Stored as string in Firestore (`users/{uid}.role`).
///
/// `admin` can NEVER be chosen in the app — the sign-up UI and the
/// Firestore create-rule only allow driver/mechanic. Admins are created
/// in the Firebase console (Auth user + `users/{uid}` doc with
/// `role: "admin"`) and log in with email + password like everyone else.
enum AppRole {
  driver('driver'),
  mechanic('mechanic'),
  admin('admin');

  const AppRole(this.value);
  final String value;

  static AppRole fromString(String? v) =>
      AppRole.values.firstWhere((r) => r.value == v, orElse: () => AppRole.driver);
}

/// Demo fallback until the driver saves their real vehicle.
const demoVehicleName = 'Toyota Axio';
const demoVehiclePlate = 'ABC 1234';

/// App user profile — Auth uid is the Firestore doc id (`users/{uid}`).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final AppRole role;
  final String vehicle;
  final String plate;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.vehicle = '',
    this.plate = '',
    this.createdAt,
  });

  /// Single source for every vehicle label in the app.
  String get vehicleName => vehicle.isEmpty ? demoVehicleName : vehicle;
  String get vehiclePlate => plate.isEmpty ? demoVehiclePlate : plate;
  String get vehicleDisplay => '$vehicleName • $vehiclePlate';
  String get vehicleParen => '$vehicleName ($vehiclePlate)';

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'vehicle': vehicle,
        'plate': plate,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: (map['name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        role: AppRole.fromString(map['role'] as String?),
        vehicle: (map['vehicle'] ?? '') as String,
        plate: (map['plate'] ?? '') as String,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
