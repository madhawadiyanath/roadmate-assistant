import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/notification_item.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'earnings_dashboard_screen.dart';
import 'job_details_screen.dart';
import 'profile_screen.dart';

/// Mechanic home matching the RoadMate design:
/// greeting + online pill, hero card, live stat grid, earnings,
/// jobs feed (accept / advance), earnings and chat tabs.
class MechanicDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  final AssistanceService? assistanceService;

  const MechanicDashboardScreen({
    super.key,
    required this.user,
    this.authService,
    this.assistanceService,
  });

  @override
  State<MechanicDashboardScreen> createState() =>
      _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  int _tab = 0;
  bool _available = true;
  bool _busy = false;
  late AppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  String get _firstName {
    final n = _user.name.trim();
    return n.isEmpty ? 'Mechanic' : n.split(' ').first;
  }

  /// Avatar → Profile page. Saved edits refresh the dashboard user.
  Future<void> _openProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: _user,
          authService: widget.authService,
        ),
      ),
    );
    if (!mounted) return;
    if (updated is AppUser) setState(() => _user = updated);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showNotifications() {
    final service = NotificationService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StreamBuilder<List<AppNotificationItem>>(
          stream: service.watchUserNotifications(_user.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? const <AppNotificationItem>[];
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No notifications yet.'),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _accept(ServiceRequest r) async {
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _assist.acceptRequest(
        requestId: r.id,
        driverUid: r.driverUid,
        mechanicUid: _user.uid,
        mechanicName: _user.name,
      );
      if (!mounted) return;
      _snack('${r.type.label} accepted — driver notified!');
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance(ServiceRequest r) async {
    final next = r.status == RequestStatus.accepted
        ? RequestStatus.onTheWay
        : RequestStatus.completed;
    setState(() => _busy = true);
    try {
      await _assist.updateStatus(r.id, next);
      if (!mounted) return;
      _snack(next == RequestStatus.completed
          ? 'Job completed. Nice work!'
          : 'On the way to driver.');
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _MechHomeTab(
              firstName: _firstName,
              available: _available,
              onToggleAvailable: () =>
                  setState(() => _available = !_available),
              onAvatarTap: _openProfile,
              onViewRequests: () => setState(() => _tab = 1),
              onShowNotifications: _showNotifications,
              assistance: _assist,
              mechanicUid: _user.uid,
            ),
            _MechJobsTab(
              assistance: _assist,
              mechanicUid: _user.uid,
              mechanicName: _user.name,
              available: _available,
              busy: _busy,
              onAccept: _accept,
              onAdvance: _advance,
              onTabSelect: (i) => setState(() => _tab = i),
            ),
            const _EarningsTab(),
            _MechChatTab(user: _user, assistance: _assist),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
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
            icon: Icon(Icons.work_outline_rounded),
            activeIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

// ============================== HOME TAB ==============================

class _MechHomeTab extends StatelessWidget {
  final String firstName;
  final bool available;
  final VoidCallback onToggleAvailable;
  final VoidCallback onAvatarTap;
  final VoidCallback onViewRequests;
  final VoidCallback onShowNotifications;
  final AssistanceService assistance;
  final String mechanicUid;

  const _MechHomeTab({
    required this.firstName,
    required this.available,
    required this.onToggleAvailable,
    required this.onAvatarTap,
    required this.onViewRequests,
    required this.onShowNotifications,
    required this.assistance,
    required this.mechanicUid,
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
              const Row(
                children: [
                  Icon(Icons.shield_rounded,
                      size: 22, color: AppColors.navy),
                  SizedBox(width: 6),
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
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    firstName.isEmpty ? 'M' : firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Greeting row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  firstName.isEmpty ? 'M' : firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.greyText),
                    ),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleAvailable,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: available
                        ? const Color(0xFFE6F7EE)
                        : AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: available
                            ? const Color(0xFF22B573)
                            : AppColors.greyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        available ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: available
                              ? const Color(0xFF22B573)
                              : AppColors.greyText,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more_rounded,
                          size: 16, color: AppColors.greyText),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onShowNotifications,
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.navy, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hero card
          const _MechHeroCard(),
          const SizedBox(height: 14),

          // Live stat grid (demo numbers until Firebase connects)
          if (!firebaseReady)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: const [
                _StatCard(
                  value: '3',
                  label: 'New Requests',
                  icon: Icons.shield_outlined,
                  iconBg: Color(0xFFFFEDE0),
                  iconColor: AppColors.orange,
                ),
                _StatCard(
                  value: '1',
                  label: 'Active Job',
                  icon: Icons.work_outline_rounded,
                  iconBg: Color(0xFFE3EEFF),
                  iconColor: Color(0xFF2F7DE1),
                ),
                _StatCard(
                  value: '12',
                  label: 'Completed',
                  icon: Icons.check_circle_outline_rounded,
                  iconBg: Color(0xFFE6F7EE),
                  iconColor: Color(0xFF22B573),
                ),
                _StatCard(
                  value: '4.8',
                  label: 'Rating',
                  icon: Icons.star_rounded,
                  iconBg: Color(0xFFFFF3DC),
                  iconColor: AppColors.orange,
                ),
              ],
            )
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: assistance.watchPendingRequests(),
              builder: (context, pendingSnap) => StreamBuilder<
                  List<ServiceRequest>>(
                stream: assistance.watchMechanicJobs(mechanicUid),
                builder: (context, jobsSnap) {
                  final pendingCount =
                      (pendingSnap.data ?? []).length;
                  final myJobs = jobsSnap.data ?? [];
                  final activeCount = myJobs
                      .where((r) =>
                          r.status == RequestStatus.accepted ||
                          r.status == RequestStatus.onTheWay)
                      .length;
                  final completedCount = myJobs
                      .where(
                          (r) => r.status == RequestStatus.completed)
                      .length;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _StatCard(
                        value: '$pendingCount',
                        label: 'New Requests',
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xFFFFEDE0),
                        iconColor: AppColors.orange,
                      ),
                      _StatCard(
                        value: '$activeCount',
                        label: 'Active Job',
                        icon: Icons.work_outline_rounded,
                        iconBg: const Color(0xFFE3EEFF),
                        iconColor: const Color(0xFF2F7DE1),
                      ),
                      _StatCard(
                        value: '$completedCount',
                        label: 'Completed',
                        icon: Icons.check_circle_outline_rounded,
                        iconBg: const Color(0xFFE6F7EE),
                        iconColor: const Color(0xFF22B573),
                      ),
                      const _StatCard(
                        value: '4.8',
                        label: 'Rating',
                        icon: Icons.star_rounded,
                        iconBg: Color(0xFFFFF3DC),
                        iconColor: AppColors.orange,
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 14),

          // Earnings
          const Text(
            "Today's Earnings",
            style: TextStyle(fontSize: 13.5, color: AppColors.greyText),
          ),
          const SizedBox(height: 2),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. 12,500',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: _GainPill(text: '+12%'),
              ),
              Spacer(),
              _MiniBars(),
            ],
          ),
          const SizedBox(height: 14),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onViewRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
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
                    'View New Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
    );
  }
}

class _GainPill extends StatelessWidget {
  final String text;
  const _GainPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF22B573),
        ),
      ),
    );
  }
}

class _MechHeroCard extends StatelessWidget {
  const _MechHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's keep\nSri Lanka moving!",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Accept requests and help drivers in need.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 96,
              child: _MechanicArt(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small flat mechanic figure for the hero card.
class _MechanicArt extends StatelessWidget {
  const _MechanicArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MechanicArtPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MechanicArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final skin = Paint()..color = const Color(0xFFF0C8A0);
    final shirt = Paint()..color = const Color(0xFF2F7DE1);
    final vest = Paint()..color = const Color(0xFFFF8A1E);
    final pants = Paint()..color = const Color(0xFF1A2340);

    // Legs
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.38, h * 0.60, w * 0.48, h * 0.95,
          const Radius.circular(4)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.52, h * 0.60, w * 0.62, h * 0.95,
          const Radius.circular(4)),
      pants,
    );
    // Torso + vest
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.32, h * 0.30, w * 0.68, h * 0.64,
          const Radius.circular(10)),
      shirt,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.38, h * 0.30, w * 0.62, h * 0.64,
          const Radius.circular(6)),
      vest,
    );
    // Arm waving
    canvas.drawLine(
      Offset(w * 0.66, h * 0.36),
      Offset(w * 0.90, h * 0.18),
      Paint()
        ..color = const Color(0xFF2F7DE1)
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(w * 0.90, h * 0.16), w * 0.06, skin);
    // Head + cap
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.11, skin);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.17),
          width: w * 0.26,
          height: w * 0.26),
      3.14,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFF0A2A66)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.greyText,
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

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 28.0, 22.0, 34.0, 30.0, 44.0, 58.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < heights.length; i++) ...[
          Container(
            width: 9,
            height: heights[i],
            decoration: BoxDecoration(
              color: i == heights.length - 1
                  ? const Color(0xFF22B573)
                  : const Color(0xFF22B573).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (i != heights.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

// ============================== JOBS TAB ==============================

enum _JobFilter { fresh, active, done }

/// Jobs tab opens on freshly arrived requests. Filter chips switch
/// between New / Active / Done.
class _MechJobsTab extends StatefulWidget {
  final AssistanceService assistance;
  final String mechanicUid;
  final String mechanicName;
  final bool available;
  final bool busy;
  final ValueChanged<ServiceRequest> onAccept;
  final ValueChanged<ServiceRequest> onAdvance;
  final ValueChanged<int> onTabSelect;

  const _MechJobsTab({
    required this.assistance,
    required this.mechanicUid,
    required this.mechanicName,
    required this.available,
    required this.busy,
    required this.onAccept,
    required this.onAdvance,
    required this.onTabSelect,
  });

  @override
  State<_MechJobsTab> createState() => _MechJobsTabState();
}

class _MechJobsTabState extends State<_MechJobsTab> {
  _JobFilter _filter = _JobFilter.fresh;

  /// Open the details page. `true` = accepted/rejected (streams refresh),
  /// int = bottom-nav tab switch.
  Future<void> _openDetails(ServiceRequest r) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(
          request: r,
          mechanicUid: widget.mechanicUid,
          mechanicName: widget.mechanicName,
          assistanceService: widget.assistance,
        ),
      ),
    );
    if (!mounted) return;
    if (res is int) widget.onTabSelect(res);
  }

  static const _demoFresh = [
    ServiceRequest(
      id: 'demo-m1',
      driverUid: 'd1',
      driverName: 'Kasun Perera',
      type: AssistanceType.flatTyre,
      status: RequestStatus.pending,
      address: 'No. 25, Galle Road, Colombo 06',
    ),
    ServiceRequest(
      id: 'demo-m2',
      driverUid: 'd2',
      driverName: 'Amal Silva',
      type: AssistanceType.towing,
      status: RequestStatus.pending,
      address: 'Outer Circular Hwy',
    ),
  ];

  static const _demoActive = [
    ServiceRequest(
      id: 'demo-m3',
      driverUid: 'd3',
      driverName: 'Ruwan Fernando',
      type: AssistanceType.jumpStart,
      status: RequestStatus.accepted,
      address: 'Kandy Rd, Kelaniya',
      mechanicName: 'You',
    ),
  ];

  static const _demoDone = [
    ServiceRequest(
      id: 'demo-m4',
      driverUid: 'd4',
      driverName: 'Kasun Perera',
      type: AssistanceType.towing,
      status: RequestStatus.completed,
      address: 'No. 25, Galle Road, Colombo 06',
      mechanicName: 'You',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'Jobs',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          if (!firebaseReady)
            _DemoBody(
              filter: _filter,
              parent: widget,
              onChanged: (f) => setState(() => _filter = f),
              onTap: _openDetails,
            )
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: widget.assistance.watchPendingRequests(),
              builder: (context, pendingSnap) => StreamBuilder<
                  List<ServiceRequest>>(
                stream: widget.assistance
                    .watchMechanicJobs(widget.mechanicUid),
                builder: (context, jobsSnap) {
                  if (pendingSnap.connectionState ==
                          ConnectionState.waiting ||
                      jobsSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (pendingSnap.hasError) {
                    return _ErrorBox(error: pendingSnap.error);
                  }
                  if (jobsSnap.hasError) {
                    return _ErrorBox(error: jobsSnap.error);
                  }
                  final fresh = ((pendingSnap.data ?? [])
                        ..removeWhere(
                            (r) => r.driverUid == widget.mechanicUid))
                      .toList();
                  final mine = jobsSnap.data ?? [];
                  final active = mine
                      .where((r) =>
                          r.status == RequestStatus.accepted ||
                          r.status == RequestStatus.onTheWay)
                      .toList();
                  final done = mine
                      .where((r) =>
                          r.status == RequestStatus.completed ||
                          r.status == RequestStatus.cancelled)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterRow(
                        filter: _filter,
                        freshCount: fresh.length,
                        activeCount: active.length,
                        doneCount: done.length,
                        onChanged: (f) =>
                            setState(() => _filter = f),
                      ),
                      const SizedBox(height: 12),
                      _LiveBody(
                        filter: _filter,
                        available: widget.available,
                        fresh: fresh,
                        active: active,
                        done: done,
                        parent: widget,
                        onTap: _openDetails,
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Demo content (no Firebase): chips + per-filter lists.
class _DemoBody extends StatelessWidget {
  final _JobFilter filter;
  final _MechJobsTab parent;
  final ValueChanged<_JobFilter> onChanged;
  final ValueChanged<ServiceRequest> onTap;
  const _DemoBody({
    required this.filter,
    required this.parent,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterRow(
          filter: filter,
          freshCount: _MechJobsTabState._demoFresh.length,
          activeCount: _MechJobsTabState._demoActive.length,
          doneCount: _MechJobsTabState._demoDone.length,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        switch (filter) {
          _JobFilter.fresh => Column(
              children: [
                for (final r in _MechJobsTabState._demoFresh) ...[
                  _IncomingCard(
                    request: r,
                    onTap: () => onTap(r),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          _JobFilter.active => Column(
              children: [
                for (final r in _MechJobsTabState._demoActive) ...[
                  _JobCard(
                    request: r,
                    busy: parent.busy,
                    onAdvance: parent.onAdvance,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          _JobFilter.done => Column(
              children: [
                for (final r in _MechJobsTabState._demoDone) ...[
                  _JobCard(
                    request: r,
                    busy: parent.busy,
                    onAdvance: parent.onAdvance,
                    showAction: false,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        },
      ],
    );
  }
}

/// Live content for the selected filter.
class _LiveBody extends StatelessWidget {
  final _JobFilter filter;
  final bool available;
  final List<ServiceRequest> fresh;
  final List<ServiceRequest> active;
  final List<ServiceRequest> done;
  final _MechJobsTab parent;
  final ValueChanged<ServiceRequest> onTap;
  const _LiveBody({
    required this.filter,
    required this.available,
    required this.fresh,
    required this.active,
    required this.done,
    required this.parent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      _JobFilter.fresh => (fresh.isEmpty || !available)
          ? _EmptyBox(
              text: available
                  ? 'No new requests right now.'
                  : 'Go online to receive requests.',
            )
          : Column(
              children: [
                for (final r in fresh) ...[
                  _IncomingCard(
                    request: r,
                    onTap: () => onTap(r),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      _JobFilter.active => active.isEmpty
          ? const _EmptyBox(text: 'Accepted jobs appear here.')
          : Column(
              children: [
                for (final r in active) ...[
                  _JobCard(
                    request: r,
                    busy: parent.busy,
                    onAdvance: parent.onAdvance,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      _JobFilter.done => done.isEmpty
          ? const _EmptyBox(text: 'Finished jobs appear here.')
          : Column(
              children: [
                for (final r in done) ...[
                  _JobCard(
                    request: r,
                    busy: parent.busy,
                    onAdvance: parent.onAdvance,
                    showAction: false,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    };
  }
}

class _FilterRow extends StatelessWidget {
  final _JobFilter filter;
  final int freshCount;
  final int activeCount;
  final int doneCount;
  final ValueChanged<_JobFilter> onChanged;
  const _FilterRow({
    required this.filter,
    required this.freshCount,
    required this.activeCount,
    required this.doneCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'New',
            count: freshCount,
            selected: filter == _JobFilter.fresh,
            onTap: () => onChanged(_JobFilter.fresh),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Active',
            count: activeCount,
            selected: filter == _JobFilter.active,
            onTap: () => onChanged(_JobFilter.active),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Done',
            count: doneCount,
            selected: filter == _JobFilter.done,
            onTap: () => onChanged(_JobFilter.done),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : const Color(0xFFE3E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.navyDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.fieldFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================== EARNINGS / CHAT ==============================

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) {
    return const EarningsDashboardScreen(showBack: false);
  }
}

/// Mechanic chat list: active assigned jobs open a driver thread.
class _MechChatTab extends StatelessWidget {
  final AppUser user;
  final AssistanceService assistance;
  const _MechChatTab({required this.user, required this.assistance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Talk to drivers on your active jobs.',
            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          const SizedBox(height: 14),
          if (!firebaseReady)
            const _EmptyBox(text: 'Driver chat threads will appear here.')
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: assistance.watchMechanicJobs(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _ErrorBox(error: snap.error);
                }
                final items = (snap.data ?? [])
                    .where((r) =>
                        r.status == RequestStatus.accepted ||
                        r.status == RequestStatus.onTheWay)
                    .toList();
                if (items.isEmpty) {
                  return const _EmptyBox(
                      text: 'Driver chat threads will appear here.');
                }
                return Column(
                  children: [
                    for (final r in items) ...[
                      _ChatThreadRow(
                        title: r.driverName.isEmpty ? 'Driver' : r.driverName,
                        subtitle: '${r.type.label} • ${r.refCode}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              request: r,
                              senderUid: user.uid,
                              senderName: user.name,
                              senderRole: 'mechanic',
                              peerName: r.driverName,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ChatThreadRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChatThreadRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                title.isEmpty ? '?' : title[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
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

// ============================== CARDS ==============================

/// Tappable job card — opens the Request Details page (no inline button).
class _IncomingCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;
  const _IncomingCard({required this.request, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.type.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        '${request.driverName} • ${request.refCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDE0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.type.eta,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppColors.greyText,
                ),
              ],
            ),
            if (request.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 15, color: AppColors.greyText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final ServiceRequest request;
  final bool busy;
  final ValueChanged<ServiceRequest> onAdvance;
  final bool showAction;
  const _JobCard({
    required this.request,
    required this.busy,
    required this.onAdvance,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final nextLabel = request.status == RequestStatus.accepted
        ? 'Start — On the way'
        : 'Mark Completed';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.type.label} • ${request.refCode}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              _StatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.driverName} • ${request.address}',
            style:
                const TextStyle(fontSize: 12.5, color: AppColors.greyText),
          ),
          if (showAction) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: busy ? null : () => onAdvance(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22B573),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  nextLabel,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == RequestStatus.completed
        ? const Color(0xFF22B573)
        : status == RequestStatus.pending
            ? AppColors.orange
            : const Color(0xFF2F7DE1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.greyText, fontSize: 13),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final Object? error;
  const _ErrorBox({this.error});

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
        'Could not load jobs.\n$error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB02A37), fontSize: 12.5),
      ),
    );
  }
}
