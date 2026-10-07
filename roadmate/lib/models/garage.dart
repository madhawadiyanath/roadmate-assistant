import 'package:cloud_firestore/cloud_firestore.dart';

/// Public garage directory entry in `garages/{ownerUid}`.
/// Readable by any signed-in user; only the owning mechanic (or an
/// admin) may write it.
class GarageProfile {
  final String ownerUid;
  final String name;
  final String area;
  final String phone;
  final List<String> services;
  final double rating;
  final int jobsDone;
  final bool open;
  final DateTime? updatedAt;

  const GarageProfile({
    required this.ownerUid,
    required this.name,
    this.area = '',
    this.phone = '',
    this.services = const [],
    this.rating = 0,
    this.jobsDone = 0,
    this.open = true,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'area': area,
        'phone': phone,
        'services': services,
        'rating': rating,
        'jobsDone': jobsDone,
        'open': open,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory GarageProfile.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final rawServices = (m['services'] as List?) ?? [];
    return GarageProfile(
      ownerUid: doc.id,
      name: (m['name'] ?? '') as String,
      area: (m['area'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      services: rawServices.map((e) => '$e').toList(),
      rating: ((m['rating'] ?? 0) as num).toDouble(),
      jobsDone: ((m['jobsDone'] ?? 0) as num).toInt(),
      open: (m['open'] ?? true) as bool,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Demo listings shown until Firebase connects.
const demoGarages = [
  GarageProfile(
    ownerUid: 'demo-g1',
    name: 'City Auto Garage',
    area: 'Colombo 03 • 1.2 km',
    phone: '+94112345678',
    services: ['Flat Tyre', 'Jump Start', 'Towing'],
    rating: 4.8,
    jobsDone: 240,
    open: true,
  ),
  GarageProfile(
    ownerUid: 'demo-g2',
    name: 'Express Motors',
    area: 'Dehiwala • 3.4 km',
    phone: '+94112765432',
    services: ['Fuel Drop', 'Towing'],
    rating: 4.6,
    jobsDone: 180,
    open: true,
  ),
  GarageProfile(
    ownerUid: 'demo-g3',
    name: 'Night Owl Repairs',
    area: 'Nugegoda • 5.1 km',
    phone: '+94112876543',
    services: ['Flat Tyre', 'Jump Start'],
    rating: 4.5,
    jobsDone: 96,
    open: false,
  ),
];
