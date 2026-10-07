import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_colors.dart';

IconData vehicleTypeIcon(VehicleType t) => switch (t) {
      VehicleType.car => Icons.directions_car_filled_rounded,
      VehicleType.bike => Icons.two_wheeler_rounded,
      VehicleType.van => Icons.airport_shuttle_rounded,
      VehicleType.truck => Icons.local_shipping_rounded,
      VehicleType.other => Icons.commute_rounded,
    };

/// Small blue pill with the vehicle type ("Car", "Bike"…).
class VehicleTypeChip extends StatelessWidget {
  final VehicleType type;
  const VehicleTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2F5BD6),
        ),
      ),
    );
  }
}

/// Bordered number-plate badge.
class PlateChip extends StatelessWidget {
  final String plate;
  final double fontSize;
  const PlateChip({super.key, required this.plate, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCD5EE)),
      ),
      child: Text(
        plate,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}
