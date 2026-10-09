import 'package:cloud_firestore/cloud_firestore.dart';

/// Vehicle categories offered in the garage. Stored as [name] in Firestore.
enum VehicleType {
  car('Car'),
  bike('Bike'),
  van('Van'),
  truck('Truck'),
  other('Other');

  const VehicleType(this.label);
  final String label;

  static VehicleType fromString(String? v) => VehicleType.values
      .firstWhere((t) => t.name == v, orElse: () => VehicleType.other);
}

/// A saved vehicle — `users/{uid}/vehicles/{id}`.
class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNo;
  final VehicleType type;
  final String fuelType;
  final String color;
  final bool isDefault;
  final String? photoUrl;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNo,
    this.type = VehicleType.car,
    this.fuelType = '',
    this.color = '',
    this.isDefault = false,
    this.photoUrl,
    this.createdAt,
  });

  /// "Toyota Corolla" — the label used across the app.
  String get name => '$make $model'.trim();

  /// "Toyota Corolla • CAK 1234".
  String get display => '$name • $plateNo';

  Vehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? plateNo,
    VehicleType? type,
    String? fuelType,
    String? color,
    String? photoUrl,
  }) =>
      Vehicle(
        id: id,
        make: make ?? this.make,
        model: model ?? this.model,
        year: year ?? this.year,
        plateNo: plateNo ?? this.plateNo,
        type: type ?? this.type,
        fuelType: fuelType ?? this.fuelType,
        color: color ?? this.color,
        isDefault: isDefault,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'year': year,
        'plateNo': plateNo,
        'type': type.name,
        'fuelType': fuelType,
        'color': color,
        'isDefault': isDefault,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) => Vehicle(
        id: id,
        make: (map['make'] ?? '') as String,
        model: (map['model'] ?? '') as String,
        year: (map['year'] as num?)?.toInt() ?? 0,
        plateNo: (map['plateNo'] ?? '') as String,
        type: VehicleType.fromString(map['type'] as String?),
        fuelType: (map['fuelType'] ?? '') as String,
        color: (map['color'] ?? '') as String,
        isDefault: (map['isDefault'] ?? false) as bool,
        photoUrl: map['photoUrl'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
