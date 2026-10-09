import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';
import '../widgets/striped_placeholder.dart';
import '../widgets/vehicle_widgets.dart';
import 'driver_dashboard_screen.dart' show formatDate;
import 'vehicle_form_screen.dart';

/// One saved vehicle. Watches it live (edits and "set default" appear
/// immediately) and closes itself if the vehicle is deleted.
class VehicleDetailsScreen extends StatefulWidget {
  final String uid;
  final String vehicleId;
  final VehicleService? service;

  const VehicleDetailsScreen({
    super.key,
    required this.uid,
    required this.vehicleId,
    this.service,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  Stream<Vehicle?>? _stream;
  bool _closing = false;
  bool _busy = false;

  bool get _connected => widget.service != null || firebaseReady;
  VehicleService get _service => widget.service ?? VehicleService();

  @override
  void initState() {
    super.initState();
    if (_connected) {
      _stream = _service.watchVehicle(widget.uid, widget.vehicleId);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Pop once, whether triggered by our own delete or by the live stream
  /// reporting the vehicle gone.
  void _close() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _edit(Vehicle v) => Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleFormScreen(
            uid: widget.uid,
            vehicle: v,
            service: widget.service,
          ),
        ),
      );

  Future<void> _setDefault(Vehicle v) async {
    setState(() => _busy = true);
    try {
      await _service.setDefault(widget.uid, v.id);
      if (mounted) _snack('${v.name} is now your default vehicle.');
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Vehicle v) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text('${v.name} (${v.plateNo}) will be removed from your '
            'saved vehicles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.deleteVehicle(widget.uid, v.id);
      if (!mounted) return;
      _snack('Vehicle deleted.');
      _close();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(AuthService.friendlyMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateTopBar(),
            RoadMatePageTitle(
              title: 'Vehicle Details',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final stream = _stream;
    if (stream == null) {
      return const StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Firebase not connected',
        message: 'Add your google-services files to view saved vehicles.',
      );
    }
    return StreamBuilder<Vehicle?>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return StateMessage(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFB02A37),
            title: 'Could not load vehicle',
            message: AuthService.friendlyMessage(snap.error!),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final v = snap.data;
        if (v == null) {
          _close();
          return const SizedBox.shrink();
        }
        return _content(v);
      },
    );
  }

  Widget _content(Vehicle v) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3E8F5), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: v.photoUrl == null || v.photoUrl!.isEmpty
                          ? const StripedPlaceholder(
                              label: 'vehicle photo',
                              borderRadius: BorderRadius.zero,
                            )
                          : VehiclePhoto(
                              vehicle: v,
                              borderRadius: BorderRadius.zero,
                            ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vehicleTypeIcon(v.type),
                                size: 17, color: const Color(0xFF2F5BD9)),
                            const SizedBox(width: 6),
                            Text(
                              v.type.label,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F5BD9),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  v.name,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                if (v.isDefault) const DefaultTag(),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Added ${formatDate(v.createdAt)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      PlateBadge(plate: v.plateNo, fontSize: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!v.isDefault)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _busy ? null : () => _setDefault(v),
                icon: const Icon(Icons.star_outline_rounded, size: 19),
                label: const Text(
                  'Set as default',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.orange),
              ),
            )
          else
            const SizedBox(height: 14),
          VehicleDetailRows(vehicle: v),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _edit(v),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text(
                      'Edit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _delete(v),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text(
                      'Delete',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE5484D),
                      side: const BorderSide(color: Color(0xFFE5484D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
