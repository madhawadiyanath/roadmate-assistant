import 'package:cloud_firestore/cloud_firestore.dart';

/// Garage and workshop profile details for Member 2 (Garage / Service Provider).
class GarageProfile {
  final String ownerUid;
  final String garageName;
  final String registrationNumber;
  final String hotline;
  final String address;
  final double? latitude;
  final double? longitude;
  final String operatingHours;
  final bool is24Hours;
  final bool isOpen;
  final List<String> facilities;
  final List<String> imageUrls;
  final DateTime? updatedAt;

  const GarageProfile({
    required this.ownerUid,
    required this.garageName,
    this.registrationNumber = '',
    this.hotline = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.operatingHours = '08:00 AM - 07:00 PM',
    this.is24Hours = false,
    this.isOpen = true,
    this.facilities = const [],
    this.imageUrls = const [],
    this.updatedAt,
  });

  /// True if coordinates are configured
  bool get hasLocation => latitude != null && longitude != null;

  /// Display string for location coordinates
  String get locationCoordText => hasLocation
      ? '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
      : 'Location not pinned';

  GarageProfile copyWith({
    String? ownerUid,
    String? garageName,
    String? registrationNumber,
    String? hotline,
    String? address,
    double? latitude,
    double? longitude,
    String? operatingHours,
    bool? is24Hours,
    bool? isOpen,
    List<String>? facilities,
    List<String>? imageUrls,
    DateTime? updatedAt,
  }) {
    return GarageProfile(
      ownerUid: ownerUid ?? this.ownerUid,
      garageName: garageName ?? this.garageName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      hotline: hotline ?? this.hotline,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingHours: operatingHours ?? this.operatingHours,
      is24Hours: is24Hours ?? this.is24Hours,
      isOpen: isOpen ?? this.isOpen,
      facilities: facilities ?? this.facilities,
      imageUrls: imageUrls ?? this.imageUrls,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'garageName': garageName,
        'registrationNumber': registrationNumber,
        'hotline': hotline,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'operatingHours': operatingHours,
        'is24Hours': is24Hours,
        'isOpen': isOpen,
        'facilities': facilities,
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory GarageProfile.fromMap(String ownerUid, Map<String, dynamic> map) {
    return GarageProfile(
      ownerUid: ownerUid,
      garageName: (map['garageName'] ?? '') as String,
      registrationNumber: (map['registrationNumber'] ?? '') as String,
      hotline: (map['hotline'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      operatingHours: (map['operatingHours'] ?? '08:00 AM - 07:00 PM') as String,
      is24Hours: (map['is24Hours'] as bool?) ?? false,
      isOpen: (map['isOpen'] as bool?) ?? true,
      facilities: List<String>.from(map['facilities'] ?? const []),
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
