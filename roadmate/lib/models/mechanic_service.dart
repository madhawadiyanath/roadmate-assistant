import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categories of services offered by roadside mechanics/garages.
enum ServiceCategory {
  tyre('Tyre & Wheel', Icons.tire_repair_rounded),
  battery('Battery & Electrical', Icons.bolt_rounded),
  towing('Towing & Recovery', Icons.local_shipping_rounded),
  engine('Engine & Mechanical', Icons.build_circle_rounded),
  fuel('Fuel Delivery', Icons.local_gas_station_rounded),
  ac('AC & Cooling', Icons.ac_unit_rounded),
  general('General Inspection', Icons.car_repair_rounded);

  const ServiceCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  static ServiceCategory fromString(String? v) => ServiceCategory.values
      .firstWhere((c) => c.name == v, orElse: () => ServiceCategory.general);
}

/// A service offered by a mechanic/garage — `users/{uid}/services/{id}`.
class MechanicService {
  final String id;
  final String title;
  final ServiceCategory category;
  final double basePrice;
  final int estimatedDurationMinutes;
  final String description;
  final bool isAvailable;
  final DateTime? createdAt;

  const MechanicService({
    required this.id,
    required this.title,
    this.category = ServiceCategory.general,
    required this.basePrice,
    this.estimatedDurationMinutes = 30,
    this.description = '',
    this.isAvailable = true,
    this.createdAt,
  });

  /// "Rs. 2,500"
  String get formattedPrice {
    final clean = basePrice.toStringAsFixed(basePrice.truncateToDouble() == basePrice ? 0 : 2);
    return 'Rs. $clean';
  }

  /// "30 mins" or "1 hr 15 mins"
  String get durationText {
    if (estimatedDurationMinutes < 60) {
      return '$estimatedDurationMinutes mins';
    }
    final hrs = estimatedDurationMinutes ~/ 60;
    final mins = estimatedDurationMinutes % 60;
    if (mins == 0) return hrs == 1 ? '1 hr' : '$hrs hrs';
    return '$hrs hr $mins mins';
  }

  MechanicService copyWith({
    String? id,
    String? title,
    ServiceCategory? category,
    double? basePrice,
    int? estimatedDurationMinutes,
    String? description,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return MechanicService(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category.name,
        'basePrice': basePrice,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'description': description,
        'isAvailable': isAvailable,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory MechanicService.fromMap(String id, Map<String, dynamic> map) {
    return MechanicService(
      id: id,
      title: (map['title'] ?? '') as String,
      category: ServiceCategory.fromString(map['category'] as String?),
      basePrice: ((map['basePrice'] ?? 0) as num).toDouble(),
      estimatedDurationMinutes:
          ((map['estimatedDurationMinutes'] ?? 30) as num).toInt(),
      description: (map['description'] ?? '') as String,
      isAvailable: (map['isAvailable'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
