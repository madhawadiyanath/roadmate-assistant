import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';
import '../widgets/vehicle_widgets.dart';
import 'vehicle_details_screen.dart';
import 'vehicle_form_screen.dart';

/// Stand-alone Saved Vehicles page (top bar + [SavedVehiclesView]).
class SavedVehiclesScreen extends StatelessWidget {
  final String uid;
  final VehicleService? service;
  final VoidCallback? onAvatarTap;

  const SavedVehiclesScreen({
    super.key,
    required this.uid,
    this.service,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateTopBar(onAvatarTap: onAvatarTap),
            Expanded(
              child: SavedVehiclesView(
                uid: uid,
                service: service,
                onBack: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The garage list itself — embedded as the dashboard's Garage tab and
/// inside [SavedVehiclesScreen]. Handles loading, error, empty and
/// "Firebase not connected" states, and floats the Add Vehicle button.
class SavedVehiclesView extends StatefulWidget {
  final String uid;
  final VehicleService? service;

  /// Shows a back arrow in the heading when set.
  final VoidCallback? onBack;

  const SavedVehiclesView({
    super.key,
    required this.uid,
    this.service,
    this.onBack,
  });

  @override
  State<SavedVehiclesView> createState() => _SavedVehiclesViewState();
}

class _SavedVehiclesViewState extends State<SavedVehiclesView> {
  Stream<List<Vehicle>>? _stream;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.service != null || firebaseReady;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(SavedVehiclesView old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.service != widget.service) _subscribe();
  }

  void _subscribe() {
    _stream = _connected
        ? (widget.service ?? VehicleService()).watchVehicles(widget.uid)
        : null;
  }

  void _add() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VehicleFormScreen(uid: widget.uid, service: widget.service),
      ),
    );
  }

  void _open(Vehicle v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleDetailsScreen(
          uid: widget.uid,
          vehicleId: v.id,
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    return Stack(
      children: [
        stream == null
            ? _layout(
                count: null,
                body: const StateMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Firebase not connected',
                  message:
                      'Add your google-services files to save and view vehicles.',
                ),
              )
            : StreamBuilder<List<Vehicle>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _layout(
                      count: null,
                      body: StateMessage(
                        icon: Icons.error_outline_rounded,
                        color: const Color(0xFFB02A37),
                        title: 'Could not load vehicles',
                        message: AuthService.friendlyMessage(snap.error!),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return _layout(
                      count: null,
                      body: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return _layout(
                      count: 0,
                      body: const StateMessage(
                        icon: Icons.directions_car_outlined,
                        title: 'No vehicles yet',
                        message:
                            'Tap Add Vehicle to save your first vehicle for faster service.',
                      ),
                    );
                  }
                  return _layout(
                    count: list.length,
                    body: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                      itemCount: list.length,
                      itemBuilder: (_, i) => VehicleListCard(
                        vehicle: list[i],
                        onTap: () => _open(list[i]),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 18,
          bottom: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 26),
              label: const Text(
                'Add Vehicle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _layout({required int? count, required Widget body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadMatePageTitle(
          title: 'Saved Vehicles',
          onBack: widget.onBack,
          trailing: count == null
              ? null
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'vehicle' : 'vehicles'}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 6),
          child: Text(
            'Tap a vehicle to view or manage its details.',
            style: TextStyle(fontSize: 14.5, color: AppColors.greyText),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
