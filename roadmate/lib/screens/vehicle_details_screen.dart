import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/striped_placeholder.dart';
import '../widgets/vehicle_widgets.dart';
import 'profile_screen.dart';
import 'vehicle_form_screen.dart';

/// Details of one saved vehicle with Edit / Delete.
///
/// Watches the vehicle document, so edits and "set as default" show up
/// immediately, and the page closes itself if the vehicle disappears.
class VehicleDetailsScreen extends StatefulWidget {
  final AppUser user;
  final String vehicleId;
  final VehicleService vehicleService;

  const VehicleDetailsScreen({
    super.key,
    required this.user,
    required this.vehicleId,
    required this.vehicleService,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late final Stream<Vehicle?> _stream =
      widget.vehicleService.watchVehicle(widget.user.uid, widget.vehicleId);
  bool _busy = false;
  bool _deleted = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _edit(Vehicle v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleFormScreen(
          user: widget.user,
          vehicleService: widget.vehicleService,
          vehicle: v,
        ),
      ),
    );
  }

  Future<void> _makeDefault(Vehicle v) async {
    setState(() => _busy = true);
    try {
      await widget.vehicleService.setDefault(widget.user.uid, v.id);
      if (mounted) _snack('${v.displayName} is now your default vehicle.');
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Vehicle v) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text('${v.displayName} (${v.plateNo}) will be removed '
            'from your saved vehicles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      _deleted = true; // stop the stream's "gone" event from double-popping
      await widget.vehicleService.deleteVehicle(widget.user.uid, v.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _deleted = false;
      if (mounted) {
        setState(() => _busy = false);
        _snack(AuthService.friendlyMessage(e));
      }
    }
  }

  static String _added(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Added ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: StreamBuilder<Vehicle?>(
          stream: _stream,
          builder: (context, snap) {
            final v = snap.data;
            if (snap.hasError) {
              return Center(
                child: Text(AuthService.friendlyMessage(snap.error!)),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (v == null) {
              // Deleted (here or elsewhere) — leave the page.
              if (!_deleted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                });
              }
              return const SizedBox.shrink();
            }
            return _content(v);
          },
        ),
      ),
    );
  }

  Widget _content(Vehicle v) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoadMateTopBar(
            onAvatarTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: widget.user)),
            ),
          ),
          const SizedBox(height: 14),
          PageTitleRow(
            title: 'Vehicle Details',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 14),

          // Photo + name card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE3F2), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    const StripedPlaceholder(
                      label: 'vehicle photo',
                      height: 150,
                      width: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(vehicleTypeIcon(v.type),
                                size: 16, color: const Color(0xFF2F5BD6)),
                            const SizedBox(width: 6),
                            Text(
                              v.type.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F5BD6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.displayName,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                              ),
                            ),
                            if (v.createdAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _added(v.createdAt!),
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.greyText),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PlateChip(plate: v.plateNo, fontSize: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Info rows
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE3F2), width: 1.2),
            ),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Make',
                    value: v.make),
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Model',
                    value: v.model),
                _InfoRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Year',
                    value: v.year > 0 ? '${v.year}' : '—'),
                _InfoRow(
                    icon: Icons.pin_outlined,
                    label: 'Registration No',
                    value: v.plateNo),
                _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Vehicle Type',
                    value: v.type.label),
                _InfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Color',
                    value: v.color),
                _InfoRow(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Fuel Type',
                    value: v.fuelType.label,
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _edit(v),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('Edit',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _delete(v),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          if (!v.isDefault) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => _makeDefault(v),
                child: const Text(
                  'Set as default vehicle',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE9EDF6))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.greyText),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14.5, color: AppColors.greyText)),
          ),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }
}
