import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../models/vehicle.dart';
import '../services/assistance_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'payment_review_screen.dart';
import 'saved_vehicles_screen.dart';

/// Step 3 of the driver flow: review service, location, vehicle and
/// contact, then submit. Pops `true` when the request was created,
/// or a dashboard tab index from the bottom nav.
class ConfirmRequestScreen extends StatefulWidget {
  final AppUser user;
  final AssistanceType serviceType;
  final String address;
  final AssistanceService? assistanceService;
  final VehicleService? vehicleService;

  const ConfirmRequestScreen({
    super.key,
    required this.user,
    required this.serviceType,
    required this.address,
    this.assistanceService,
    this.vehicleService,
  });

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  /// The user's default vehicle (null stream = Firebase not connected).
  late final Stream<Vehicle?>? _vehicle = widget.vehicleService != null ||
          firebaseReady
      ? (widget.vehicleService ?? VehicleService())
          .watchDefaultVehicle(widget.user.uid)
      : null;

  String _vehicleTitle(AsyncSnapshot<Vehicle?> s) {
    if (s.connectionState == ConnectionState.waiting) return 'Loading…';
    final v = s.data;
    return v == null ? 'No vehicle selected' : '${v.name} (${v.plateNo})';
  }

  String get _contact {
    final p = widget.user.phone.trim();
    return p.isEmpty ? '077 123 4567' : p;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Same page as Profile → Vehicle Information, so a driver with no
  /// default vehicle can add one. The row above updates live on return.
  void _openGarage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedVehiclesScreen(
          uid: widget.user.uid,
          service: widget.vehicleService,
        ),
      ),
    );
  }

  /// Review payment + rating first. That page creates the request,
  /// shows the success receipt, and pops the onward result — forwarded up.
  Future<void> _submit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentReviewScreen(
          user: widget.user,
          serviceType: widget.serviceType,
          address: widget.address,
          assistanceService: widget.assistanceService,
          vehicleService: widget.vehicleService,
        ),
      ),
    );
    if (!mounted) return;
    // true = Track (Requests tab), 'home' = dashboard home, int = tab.
    if (result == true || result == 'home' || result is int) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.navyDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text(
                          '24/7 ROADSIDE ASSISTANCE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _snack('Calling 1-800-ROADMATE…'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE3C2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'Confirm Request',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Please review your details',
                style: TextStyle(fontSize: 13.5, color: AppColors.greyText),
              ),
              const SizedBox(height: 14),

              // Details card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.settings_outlined,
                      iconBg: AppColors.fieldFill,
                      iconColor: AppColors.navy,
                      label: 'SERVICE TYPE',
                      title: widget.serviceType.label,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF22B573),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEDF1F7)),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      iconBg: const Color(0xFFFFEDE0),
                      iconColor: AppColors.orange,
                      label: 'LOCATION',
                      title: widget.address,
                      subtitle: 'GPS Verified (Colombo Area)',
                      subtitleOk: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFEDF1F7)),
                    StreamBuilder<Vehicle?>(
                      stream: _vehicle,
                      builder: (context, snap) => _DetailRow(
                        icon: Icons.directions_car_outlined,
                        iconBg: AppColors.fieldFill,
                        iconColor: AppColors.navy,
                        label: 'VEHICLE',
                        title: _vehicle == null
                            ? 'No vehicle selected'
                            : _vehicleTitle(snap),
                        chevron: true,
                        onTap: _openGarage,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEDF1F7)),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      iconBg: const Color(0xFFE6F7EE),
                      iconColor: const Color(0xFF22B573),
                      label: 'CONTACT NUMBER',
                      title: _contact,
                      chevron: true,
                      onTap: () => _snack('Contact editing coming soon.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ETA card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTIMATED PATROL ARRIVAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.greyText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.serviceType.eta} (Patrol Unit #04)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Fixed Rate',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const EmergencyBanner(),
              const SizedBox(height: 12),

              // Continue to payment & rating
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) => Navigator.pop(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.greyText,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.garage_outlined),
            label: 'Garage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String title;
  final String? subtitle;
  final bool subtitleOk;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.title,
    this.subtitle,
    this.subtitleOk = false,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (subtitleOk)
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: Color(0xFF22B573)),
                        if (subtitleOk) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: subtitleOk
                                  ? const Color(0xFF22B573)
                                  : AppColors.greyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (chevron)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.greyText,
              ),
          ],
        ),
      ),
    );
  }
}
