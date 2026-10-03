import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user.dart';

/// Types of roadside assistance a driver can request.
enum AssistanceType {
  flatTyre('Flat Tyre', '~12 min'),
  jumpStart('Jump Start', '~10 min'),
  fuelDrop('Fuel Drop', '~15 min'),
  towing('Towing Service', '~20 min'),
  general('Request Assistance', '~14 min');

  const AssistanceType(this.label, this.eta);
  final String label;
  final String eta;

  static AssistanceType fromString(String? v) => AssistanceType.values
      .firstWhere((t) => t.name == v, orElse: () => AssistanceType.general);
}

/// Request lifecycle.
enum RequestStatus {
  pending('Pending'),
  accepted('Accepted'),
  onTheWay('On the way'),
  completed('Completed'),
  cancelled('Cancelled');

  const RequestStatus(this.label);
  final String label;

  static RequestStatus fromString(String? v) => RequestStatus.values
      .firstWhere((s) => s.name == v, orElse: () => RequestStatus.pending);
}

/// A driver assistance request — Firestore doc in `requests/{id}`.
class ServiceRequest {
  final String id;
  final String driverUid;
  final String driverName;
  final AssistanceType type;
  final RequestStatus status;
  final String address;
  final double? latitude;
  final double? longitude;
  final String mechanicUid;
  final String mechanicName;
  final String paymentMethod;
  final int rating;
  final String feedback;
  final double totalFee;

  /// Vehicle snapshot at request time (driver may change theirs later).
  final String vehicle;
  final String plate;

  /// Stable reference code like #RM1024, generated once at creation and
  /// stored in the doc (never recomputed — `String.hashCode` is not
  /// stable across app restarts).
  final String refCode;
  final DateTime? createdAt;

  const ServiceRequest({
    required this.id,
    required this.driverUid,
    required this.driverName,
    required this.type,
    required this.status,
    this.address = '',
    this.latitude,
    this.longitude,
    this.mechanicUid = '',
    this.mechanicName = '',
    this.paymentMethod = '',
    this.rating = 0,
    this.feedback = '',
    this.totalFee = 0,
    this.vehicle = '',
    this.plate = '',
    this.refCode = '',
    this.createdAt,
  });

  /// Display for the request's vehicle, with demo fallback.
  String get vehicleDisplay {
    final v = vehicle.isEmpty ? demoVehicleName : vehicle;
    final p = plate.isEmpty ? demoVehiclePlate : plate;
    return '$v • $p';
  }

  Map<String, dynamic> toMap() => {
        'driverUid': driverUid,
        'driverName': driverName,
        'type': type.name,
        'status': status.name,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'mechanicUid': mechanicUid,
        'mechanicName': mechanicName,
        'paymentMethod': paymentMethod,
        'rating': rating,
        'feedback': feedback,
        'totalFee': totalFee,
        'vehicle': vehicle,
        'plate': plate,
        'refCode': refCode,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ServiceRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final stored = (m['refCode'] ?? '') as String;
    return ServiceRequest(
      id: doc.id,
      driverUid: (m['driverUid'] ?? '') as String,
      driverName: (m['driverName'] ?? '') as String,
      type: AssistanceType.fromString(m['type'] as String?),
      status: RequestStatus.fromString(m['status'] as String?),
      address: (m['address'] ?? '') as String,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      mechanicUid: (m['mechanicUid'] ?? '') as String,
      mechanicName: (m['mechanicName'] ?? '') as String,
      paymentMethod: (m['paymentMethod'] ?? '') as String,
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      feedback: (m['feedback'] ?? '') as String,
      totalFee: (m['totalFee'] as num?)?.toDouble() ?? 0,
      vehicle: (m['vehicle'] ?? '') as String,
      plate: (m['plate'] ?? '') as String,
      // Old docs written before refCode existed fall back to the legacy
      // id-derived code so they still display something.
      refCode: stored.isEmpty ? legacyRefCode(doc.id) : stored,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Legacy id-derived code — only for pre-refCode docs.
  static String legacyRefCode(String id) {
    final h = id.hashCode.abs() % 9000 + 1000;
    return '#RM$h';
  }
}
