import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/striped_placeholder.dart';
import '../widgets/vehicle_widgets.dart';
import 'profile_screen.dart';
import 'vehicle_details_screen.dart';
import 'vehicle_form_screen.dart';

/// Saved Vehicles list — the body of the driver's Garage tab.
///
/// Not a Scaffold: it lives inside the dashboard (which owns the bottom nav).
/// Pass [onBack] to show the back arrow when pushing it as its own page.
class SavedVehiclesView extends StatelessWidget {
  final AppUser user;
  final VehicleService? vehicleService;
  final VoidCallback? onBack;

  const SavedVehiclesView({
    super.key,
    required this.user,
    this.vehicleService,
    this.onBack,
  });

  /// Real Firestore only when Firebase is up (or a service was injected).
  bool get _live => vehicleService != null || firebaseReady;
  VehicleService get _svc => vehicleService ?? VehicleService();

  void _openProfile(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
      );

  void _add(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleFormScreen(user: user, vehicleService: _svc),
        ),
      );

  void _open(BuildContext context, Vehicle v) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleDetailsScreen(
            user: user,
            vehicleId: v.id,
            vehicleService: _svc,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_live) {
      return _Shell(
        user: user,
        count: null,
        onBack: onBack,
        onProfile: () => _openProfile(context),
        child: const _Message(
          icon: Icons.cloud_off_rounded,
          text: 'Firebase is not connected yet, so saved vehicles '
              'can\'t be loaded.',
        ),
      );
    }
    return StreamBuilder<List<Vehicle>>(
      stream: _svc.watchVehicles(user.uid),
      builder: (context, snap) {
        final items = snap.data ?? const <Vehicle>[];
        Widget body;
        if (snap.hasError) {
          body = _Message(
            icon: Icons.error_outline_rounded,
            text: AuthService.friendlyMessage(snap.error!),
          );
        } else if (snap.connectionState == ConnectionState.waiting) {
          body = const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (items.isEmpty) {
          body = const _Message(
            icon: Icons.directions_car_outlined,
            text: 'No vehicles yet. Tap “Add Vehicle” to save your first one.',
          );
        } else {
          body = Column(
            children: [
              for (final v in items) ...[
                _VehicleCard(vehicle: v, onTap: () => _open(context, v)),
                const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Stack(
          children: [
            _Shell(
              user: user,
              count: snap.hasData ? items.length : null,
              onBack: onBack,
              onProfile: () => _openProfile(context),
              child: body,
            ),
            Positioned(
              right: 18,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: () => _add(context),
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Vehicle',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Header + scroll area shared by every state of the list.
class _Shell extends StatelessWidget {
  final AppUser user;
  final int? count;
  final VoidCallback? onBack;
  final VoidCallback onProfile;
  final Widget child;
  const _Shell({
    required this.user,
    required this.count,
    required this.onBack,
    required this.onProfile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoadMateTopBar(onAvatarTap: onProfile),
          const SizedBox(height: 14),
          PageTitleRow(
            title: 'Saved Vehicles',
            onBack: onBack,
            trailing: count == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count ${count == 1 ? 'vehicle' : 'vehicles'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a vehicle to view or manage its details.',
            style: TextStyle(fontSize: 13.5, color: AppColors.greyText),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE3F2), width: 1.2),
        ),
        child: Row(
          children: [
            const StripedPlaceholder(
              label: 'photo',
              width: 66,
              height: 66,
              circle: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vehicle.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      if (vehicle.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.peachBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB4570B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      VehicleTypeChip(type: vehicle.type),
                      const SizedBox(width: 10),
                      if (vehicle.year > 0)
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
                            fontSize: 13, color: AppColors.greyText),
                      ),
                      const SizedBox(width: 8),
                      PlateChip(plate: vehicle.plateNo),
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
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.fieldHint),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.greyText),
          ),
        ],
      ),
    );
  }
}
