import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import 'striped_placeholder.dart';

const _lineColor = Color(0xFFE3E8F5);
const _chipBlue = Color(0xFF2F5BD9);
const _chipBlueBg = Color(0xFFE8EEFF);
const _plateBg = Color(0xFFEEF2FF);

IconData vehicleTypeIcon(VehicleType type) {
  switch (type) {
    case VehicleType.car:
      return Icons.directions_car_outlined;
    case VehicleType.bike:
      return Icons.two_wheeler_rounded;
    case VehicleType.van:
      return Icons.airport_shuttle_outlined;
    case VehicleType.truck:
      return Icons.local_shipping_outlined;
    case VehicleType.other:
      return Icons.category_outlined;
  }
}

/// "Car" chip: blue text on a light blue pill.
class VehicleTypeChip extends StatelessWidget {
  final VehicleType type;
  const VehicleTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: _chipBlueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _chipBlue,
        ),
      ),
    );
  }
}

/// Orange "Default" tag shown next to the default vehicle's name.
class DefaultTag extends StatelessWidget {
  const DefaultTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.peachBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45A06),
        ),
      ),
    );
  }
}

/// Registration plate in a bordered pill.
class PlateBadge extends StatelessWidget {
  final String plate;
  final double fontSize;
  const PlateBadge({super.key, required this.plate, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _plateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD3F0), width: 1.2),
      ),
      child: Text(
        plate,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}

/// Vehicle photo, or the striped placeholder when there isn't one.
class VehiclePhoto extends StatelessWidget {
  final Vehicle vehicle;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final String label;

  const VehiclePhoto({
    super.key,
    required this.vehicle,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.label = 'vehicle photo',
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = StripedPlaceholder(
      label: label,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
    final url = vehicle.photoUrl;
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// One row of the Saved Vehicles list.
class VehicleListCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const VehicleListCard({super.key, required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _lineColor, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _plateBg,
                    shape: BoxShape.circle,
                  ),
                  child: VehiclePhoto(
                    vehicle: vehicle,
                    width: 60,
                    height: 36,
                    label: 'photo',
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          if (vehicle.isDefault) const DefaultTag(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          VehicleTypeChip(type: vehicle.type),
                          const SizedBox(width: 10),
                          Text(
                            '${vehicle.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Plate No',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.greyText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: PlateBadge(plate: vehicle.plateNo)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.greyText, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Make / Model / Year / Registration No / Vehicle Type / Color / Fuel Type.
class VehicleDetailRows extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleDetailRows({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    String orDash(String v) => v.trim().isEmpty ? '—' : v;
    final rows = <(IconData, String, String)>[
      (Icons.directions_car_outlined, 'Make', orDash(vehicle.make)),
      (Icons.badge_outlined, 'Model', orDash(vehicle.model)),
      (Icons.calendar_month_outlined, 'Year', '${vehicle.year}'),
      (Icons.pin_outlined, 'Registration No', orDash(vehicle.plateNo)),
      (Icons.category_outlined, 'Vehicle Type', vehicle.type.label),
      (Icons.palette_outlined, 'Color', orDash(vehicle.color)),
      (Icons.local_gas_station_outlined, 'Fuel Type', orDash(vehicle.fuelType)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor, width: 1.2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: _lineColor)),
              ),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 22, color: AppColors.greyText),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.greyText,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
