import 'package:cloud_firestore/cloud_firestore.dart';

/// Vehicle kinds shown as the blue tag on the Saved Vehicles cards.
enum VehicleType {
  car('Car'),
  bike('Bike'),
  van('Van'),
  truck('Truck'),
  other('Other');

  const VehicleType(this.label);
  final String label;

  static VehicleType fromString(String? v) => VehicleType.values
      .firstWhere((t) => t.name == v, orElse: () => VehicleType.car);
}

enum FuelType {
  petrol('Petrol'),
  diesel('Diesel'),
  hybrid('Hybrid'),
  electric('Electric');

  const FuelType(this.label);
  final String label;

  static FuelType fromString(String? v) => FuelType.values
      .firstWhere((f) => f.name == v, orElse: () => FuelType.petrol);
}

/// A driver's saved vehicle — Firestore doc in `users/{uid}/vehicles/{id}`.
class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNo;
  final VehicleType type;
  final FuelType fuelType;
  final String color;
  final bool isDefault;

  /// Optional image URL. Empty = show the placeholder (no Storage yet).
  final String photoUrl;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNo,
    this.type = VehicleType.car,
    this.fuelType = FuelType.petrol,
    this.color = '',
    this.isDefault = false,
    this.photoUrl = '',
    this.createdAt,
  });

  /// "Toyota Corolla" — headline on cards and the details page.
  String get displayName => '$make $model'.trim();

  /// Fields that can be written on create *and* update (`createdAt` is set
  /// once by the service).
  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'year': year,
        'plateNo': plateNo,
        'type': type.name,
        'fuelType': fuelType.name,
        'color': color,
        'isDefault': isDefault,
        'photoUrl': photoUrl,
      };

  factory Vehicle.fromMap(String id, Map<String, dynamic> m) => Vehicle(
        id: id,
        make: (m['make'] ?? '') as String,
        model: (m['model'] ?? '') as String,
        year: (m['year'] as num?)?.toInt() ?? 0,
        plateNo: (m['plateNo'] ?? '') as String,
        type: VehicleType.fromString(m['type'] as String?),
        fuelType: FuelType.fromString(m['fuelType'] as String?),
        color: (m['color'] ?? '') as String,
        isDefault: (m['isDefault'] ?? false) as bool,
        photoUrl: (m['photoUrl'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  Vehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? plateNo,
    VehicleType? type,
    FuelType? fuelType,
    String? color,
    bool? isDefault,
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
        isDefault: isDefault ?? this.isDefault,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );
}
