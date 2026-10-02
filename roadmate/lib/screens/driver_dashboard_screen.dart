import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/tow_truck_illustration.dart';
import 'location_screen.dart';
import 'onboarding_screen.dart';
import 'select_service_screen.dart';
import 'track_request_screen.dart';

/// Driver home after login — matches the RoadMate dashboard design:
/// header, dispatch banner, rapid-assistance hero, SOS button,
/// quick services, registered vehicle, recent requests, bottom nav.
class DriverDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  final AssistanceService? assistanceService;

  const DriverDashboardScreen({
    super.key,
    required this.user,
    this.authService,
    this.assistanceService,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _tab = 0;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  String get _firstName {
    final n = widget.user.name.trim();
    if (n.isEmpty) return 'Driver';
    return n.split(' ').first;
  }

  /// Full Select Service page. Returns the picked type (→ confirm flow)
  /// or a dashboard tab index (bottom nav).
  Future<void> _openServicePicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectServiceScreen(user: widget.user),
      ),
    );
    if (!mounted) return;
    if (result is AssistanceType) {
      await _requestAssistance(result);
    } else if (result is int) {
      setState(() => _tab = result);
    }
  }

  /// Every request goes through location → confirm → success.
  /// Result: `true` = Track (Requests tab), `'home'` = Home tab,
  /// int = bottom-nav tab.
  Future<void> _requestAssistance(AssistanceType type) async {
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          user: widget.user,
          serviceType: type,
        ),
      ),
    );
    if (!mounted) return;
    if (done == true) {
      setState(() => _tab = 1);
    } else if (done == 'home') {
      setState(() => _tab = 0);
    } else if (done is int) {
      setState(() => _tab = done);
    }
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await (widget.authService ?? AuthService()).signOut();
    } catch (_) {
      // Leave anyway.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(
              user: widget.user,
              firstName: _firstName,
              requesting: false,
              onSOS: () => _requestAssistance(AssistanceType.general),
              onSelectService: _openServicePicker,
              onQuick: _requestAssistance,
              onViewAll: () => setState(() => _tab = 1),
              onLogout: _logout,
              assistance: _assist,
              onTab: (i) => setState(() => _tab = i),
            ),
            _RequestsTab(
              assistance: _assist,
              user: widget.user,
              onTab: (i) => setState(() => _tab = i),
            ),
            _GarageTab(user: widget.user, onLogout: _logout),
            const _ChatTab(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ============================== HOME TAB ==============================

class _HomeTab extends StatelessWidget {
  final AppUser user;
  final String firstName;
  final bool requesting;
  final VoidCallback onSOS;
  final VoidCallback onSelectService;
  final ValueChanged<AssistanceType> onQuick;
  final VoidCallback onViewAll;
  final VoidCallback onLogout;
  final AssistanceService assistance;
  final ValueChanged<int> onTab;

  const _HomeTab({
    required this.user,
    required this.firstName,
    required this.requesting,
    required this.onSOS,
    required this.onSelectService,
    required this.onQuick,
    required this.onViewAll,
    required this.onLogout,
    required this.assistance,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROADSIDE CARE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.orange,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.directions_car_filled_rounded,
                          size: 20, color: AppColors.navy),
                      SizedBox(width: 4),
                      Text(
                        'RoadMate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onLogout,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.navy,
                      child: Text(
                        firstName.isEmpty
                            ? 'D'
                            : firstName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Welcome row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.greyText,
                    ),
                  ),
                  Text(
                    'Hello, $firstName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new alerts.')),
                    ),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.navy,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dispatch banner
          const _DispatchBanner(),
          const SizedBox(height: 12),

          // Hero card
          const _HeroCard(),
          const SizedBox(height: 12),

          // SOS button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: requesting ? null : onSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: requesting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      children: [
                        _SosIcon(),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Request Assistance',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 19),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Select Service — big clear entry for emergencies
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: requesting ? null : onSelectService,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy, width: 1.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select Service',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 19),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Quick services
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Services',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              Text(
                'Tap to trigger',
                style: TextStyle(fontSize: 11.5, color: AppColors.greyText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.tire_repair_rounded,
                  label: 'Flat Tyre',
                  eta: AssistanceType.flatTyre.eta,
                  onTap: () => onQuick(AssistanceType.flatTyre),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickCard(
                  icon: Icons.bolt_rounded,
                  label: 'Jump Start',
                  eta: AssistanceType.jumpStart.eta,
                  onTap: () => onQuick(AssistanceType.jumpStart),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickCard(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel Drop',
                  eta: AssistanceType.fuelDrop.eta,
                  onTap: () => onQuick(AssistanceType.fuelDrop),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Registered vehicle
          const _VehicleCard(),
          const SizedBox(height: 16),

          // Recent requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Requests',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RecentPreview(
            assistance: assistance,
            driverUid: user.uid,
            onTab: onTab,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SosIcon extends StatelessWidget {
  const _SosIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// ============================== PIECES ==============================

class _DispatchBanner extends StatelessWidget {
  const _DispatchBanner();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(
        color: const Color(0xFF5B8DEF),
        radius: 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: const Row(
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF2F7DE1)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '24/7 Priority Dispatch Active',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F7DE1),
                ),
              ),
            ),
            Icon(Icons.support_agent_rounded,
                size: 20, color: Color(0xFF2F7DE1)),
          ],
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedPainter({required this.color, this.radius = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    const dash = 5.0, gap = 4.0;
    final rrect = RRect.fromLTRBR(
        0, 0, size.width, size.height, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    double d = 0;
    while (d < metrics.length) {
      final seg = metrics.extractPath(d, (d + dash).clamp(0, metrics.length));
      canvas.drawPath(seg, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAPID ASSISTANCE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.orange,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Stuck on the road? We're here!",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'GPS verified dispatch arrives in ~14 mins. Safely hazard-light your vehicle and request below.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 4,
            child: SizedBox(
              height: 110,
              child: TowTruckIllustration(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String eta;
  final VoidCallback onTap;
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.eta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.navy, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              eta,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.navy,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGISTERED VEHICLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.greyText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Toyota Prius • CAB-8492',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 7, color: Color(0xFF22B573)),
                SizedBox(width: 5),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22B573),
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

// ============================== REQUESTS ==============================

/// Demo accepted request powering the tappable preview without Firebase.
const _demoTrackingRequest = ServiceRequest(
  id: 'demo-track-1',
  driverUid: 'd1',
  driverName: 'Kasun Perera',
  type: AssistanceType.towing,
  status: RequestStatus.accepted,
  address: 'No. 25, Galle Road, Colombo 06',
  mechanicUid: 'm1',
  mechanicName: 'Sampath Perera',
);

/// Opens tracking for active jobs; otherwise explains the status.
Future<void> openTracking(
  BuildContext context,
  ServiceRequest r,
  ValueChanged<int> onTab,
) async {
  if (r.status == RequestStatus.accepted ||
      r.status == RequestStatus.onTheWay) {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackRequestScreen(request: r)),
    );
    if (!context.mounted) return;
    if (res is int) {
      onTab(res);
    } else if (res == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled.')),
      );
    }
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        r.status == RequestStatus.pending
            ? 'Searching for a nearby patrol…'
            : 'Request ${r.status.label.toLowerCase()}.',
      ),
    ),
  );
}

class _RecentPreview extends StatelessWidget {
  final AssistanceService assistance;
  final String driverUid;
  final ValueChanged<int> onTab;
  const _RecentPreview({
    required this.assistance,
    required this.driverUid,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      // Demo tappable row (matches design) until Firebase is connected.
      return _RequestRow(
        title: _demoTrackingRequest.type.label,
        refCode: '#RM1024',
        status: RequestStatus.accepted,
        dateText: '12 Jul 2026',
        address: _demoTrackingRequest.address,
        mechanicName: _demoTrackingRequest.mechanicName,
        onTap: () => openTracking(context, _demoTrackingRequest, onTab),
      );
    }
    return StreamBuilder<List<ServiceRequest>>(
      stream: assistance.watchDriverRequests(driverUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _StreamErrorBox(error: snap.error);
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
            ),
            child: const Text(
              'No requests yet. Tap SOS to request help.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
          );
        }
        final first = items.first;
        return _RequestRow(
          title: first.type.label,
          refCode: first.refCode,
          status: first.status,
          dateText: formatDate(first.createdAt),
          address: first.address,
          mechanicName: first.mechanicName,
          onTap: () => openTracking(context, first, onTab),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final AssistanceService assistance;
  final AppUser user;
  final ValueChanged<int> onTab;
  const _RequestsTab({
    required this.assistance,
    required this.user,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'My Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track active & past rescues.',
            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          const SizedBox(height: 14),
          if (!firebaseReady)
            const Column(
              children: [
                _RequestRow(
                  title: 'Towing Service',
                  refCode: '#RM1024',
                  status: RequestStatus.completed,
                  dateText: '12 Jul 2026',
                ),
                SizedBox(height: 10),
                _RequestRow(
                  title: 'Flat Tyre',
                  refCode: '#RM1018',
                  status: RequestStatus.pending,
                  dateText: '02 Jul 2026',
                ),
              ],
            )
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: assistance.watchDriverRequests(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _StreamErrorBox(error: snap.error);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No requests yet.',
                      style:
                          TextStyle(color: AppColors.greyText, fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final r in items) ...[
                      _RequestRow(
                        title: r.type.label,
                        refCode: r.refCode,
                        status: r.status,
                        dateText: formatDate(r.createdAt),
                        address: r.address,
                        mechanicName: r.mechanicName,
                        onTap: () => openTracking(context, r, onTab),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final String title;
  final String refCode;
  final RequestStatus status;
  final String dateText;
  final String address;
  final String mechanicName;
  final VoidCallback? onTap;
  const _RequestRow({
    required this.title,
    required this.refCode,
    required this.status,
    required this.dateText,
    this.address = '',
    this.mechanicName = '',
    this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case RequestStatus.completed:
        return const Color(0xFF22B573);
      case RequestStatus.pending:
        return AppColors.orange;
      case RequestStatus.cancelled:
        return AppColors.greyText;
      case RequestStatus.accepted:
      case RequestStatus.onTheWay:
        return const Color(0xFF2F7DE1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        refCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: _statusColor),
                    const SizedBox(width: 5),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '•  $dateText${mechanicName.isNotEmpty ? ' • $mechanicName' : ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.greyText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.greyText,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Shown when a Firestore stream fails (rules / network / index),
/// so problems are visible instead of an empty list.
class _StreamErrorBox extends StatelessWidget {
  final Object? error;
  const _StreamErrorBox({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C2C7), width: 1.2),
      ),
      child: Text(
        'Could not load requests.\n${_short(error)}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB02A37), fontSize: 12.5),
      ),
    );
  }

  static String _short(Object? e) {
    final s = '$e';
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }
}

String formatDate(DateTime? d) {
  if (d == null) return 'Just now';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ============================== GARAGE / CHAT ==============================

class _GarageTab extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const _GarageTab({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'My Garage',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          const _VehicleCard(),
          const SizedBox(height: 12),
          _DetailRow(label: 'Owner', value: user.name.isEmpty ? '—' : user.name),
          _DetailRow(label: 'Plate No', value: 'CAB-8492'),
          _DetailRow(label: 'Make / Model', value: 'Toyota Prius'),
          _DetailRow(label: 'Phone', value: user.phone.isEmpty ? '—' : user.phone),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.greyText)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark)),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          Text(
            'Support Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Talk to our 24/7 dispatch team.',
            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          SizedBox(height: 14),
          EmergencyBanner(),
          SizedBox(height: 12),
          _DetailRow(label: 'Live chat', value: 'Coming soon'),
        ],
      ),
    );
  }
}

// ============================== CONFIRM SHEET / NAV ==============================

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: onTap,
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
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.garage_outlined),
          activeIcon: Icon(Icons.garage_rounded),
          label: 'Garage',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Chat',
        ),
      ],
    );
  }
}
