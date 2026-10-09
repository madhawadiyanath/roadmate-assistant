import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/payments.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../widgets/admin_charts.dart';
import 'digital_receipt_screen.dart';
import 'profile_screen.dart';

/// Admin home: platform stats, every request, every user.
/// Admins log in with email + password like everyone else — the account
/// itself is created in the Firebase console (never via app sign-up).
class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  final AssistanceService? assistanceService;
  final PaymentService? paymentService;

  const AdminDashboardScreen({
    super.key,
    required this.user,
    this.authService,
    this.assistanceService,
    this.paymentService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();
  AuthService get _auth => widget.authService ?? AuthService();
  PaymentService get _pay =>
      widget.paymentService ?? PaymentService();

  String get _firstName {
    final n = widget.user.name.trim();
    return n.isEmpty ? 'Admin' : n.split(' ').first;
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: widget.user,
          authService: widget.authService,
        ),
      ),
    );
  }

  static const _wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminHomeTab(
        firstName: _firstName,
        assistance: _assist,
        auth: _auth,
        onOpenProfile: _openProfile,
        onViewRequests: () => setState(() => _tab = 1),
        onViewUsers: () => setState(() => _tab = 2),
      ),
      _AdminRequestsTab(assistance: _assist),
      _AdminUsersTab(auth: _auth),
      _AdminPaymentsTab(pay: _pay),
    ];
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wide screens (web/desktop admin): side nav rail.
            if (constraints.maxWidth >= _wideBreakpoint) {
              final extended = constraints.maxWidth >= 1200;
              return Row(
                children: [
                  NavigationRail(
                    extended: extended,
                    selectedIndex: _tab,
                    onDestinationSelected: (i) =>
                        setState(() => _tab = i),
                    backgroundColor: Colors.white,
                    selectedIconTheme: const IconThemeData(
                        color: AppColors.orange),
                    selectedLabelTextStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greyText,
                    ),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded,
                              color: AppColors.navy, size: 24),
                          SizedBox(width: 6),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon:
                            Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                            Icons.receipt_long_outlined),
                        selectedIcon:
                            Icon(Icons.receipt_long_rounded),
                        label: Text('Requests'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.group_outlined),
                        selectedIcon: Icon(Icons.group_rounded),
                        label: Text('Users'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                            Icons.payments_outlined),
                        selectedIcon:
                            Icon(Icons.payments_rounded),
                        label: Text('Payments'),
                      ),
                    ],
                  ),
                  const VerticalDivider(
                      thickness: 1, width: 1, color: Color(0xFFEDF1F7)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 860),
                        child: IndexedStack(
                          index: _tab,
                          children: pages,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            // Phones/tablets: bottom nav.
            return IndexedStack(index: _tab, children: pages);
          },
        ),
      ),
      bottomNavigationBar: _AdminBottomNav(
        index: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Bottom nav is hidden on wide screens where the side rail shows.
/// Rendered with zero size there so tab indices stay aligned.
class _AdminBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _AdminBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Inside Scaffold.bottomNavigationBar constraints are unbounded;
        // use screen width instead.
        final wide =
            MediaQuery.sizeOf(context).width >=
                _AdminDashboardScreenState._wideBreakpoint;
        if (wide) return const SizedBox.shrink();
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
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments_rounded),
              label: 'Payments',
            ),
          ],
        );
      },
    );
  }
}

// ============================== HOME TAB ==============================

class _AdminHomeTab extends StatelessWidget {
  final String firstName;
  final AssistanceService assistance;
  final AuthService auth;
  final VoidCallback onOpenProfile;
  final VoidCallback onViewRequests;
  final VoidCallback onViewUsers;

  const _AdminHomeTab({
    required this.firstName,
    required this.assistance,
    required this.auth,
    required this.onOpenProfile,
    required this.onViewRequests,
    required this.onViewUsers,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded,
                      size: 22, color: AppColors.navy),
                  SizedBox(width: 6),
                  Text(
                    'RoadMate Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onOpenProfile,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    firstName.isEmpty ? 'A' : firstName[0].toUpperCase(),
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
          Text(
            'Hello, $firstName 🛠️',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const Text(
            'Platform overview at a glance.',
            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          const SizedBox(height: 14),
          if (!firebaseReady)
            const Column(
              children: [
                _DemoStats(),
                SizedBox(height: 14),
                _DemoAnalytics(),
              ],
            )
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: assistance.watchAllRequests(),
              builder: (context, reqSnap) => StreamBuilder<List<AppUser>>(
                stream: auth.watchAllUsers(),
                builder: (context, userSnap) {
                  if (reqSnap.connectionState == ConnectionState.waiting ||
                      userSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final reqs = reqSnap.data ?? [];
                  final users = userSnap.data ?? [];
                  return Column(
                    children: [
                      _StatGrid(
                        totalUsers: users.length,
                        drivers: users
                            .where((u) => u.role == AppRole.driver)
                            .length,
                        mechanics: users
                            .where((u) => u.role == AppRole.mechanic)
                            .length,
                        pending: reqs
                            .where(
                                (r) => r.status == RequestStatus.pending)
                            .length,
                      ),
                      const SizedBox(height: 14),
                      _AnalyticsSection(
                        byStatus: statusSegments(reqs),
                        byRole: roleSegments(users),
                        byType: typeSegments(reqs),
                        weekly: weeklyCounts(reqs),
                        total: reqs.length,
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NavCard(
                  title: 'All Requests',
                  subtitle: 'Monitor every rescue',
                  icon: Icons.receipt_long_outlined,
                  onTap: onViewRequests,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NavCard(
                  title: 'All Users',
                  subtitle: 'Drivers & mechanics',
                  icon: Icons.group_outlined,
                  onTap: onViewUsers,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Aggregation helpers for the analytics section.
List<DonutSegment> statusSegments(List<ServiceRequest> reqs) => [
      for (final s in RequestStatus.values)
        DonutSegment(
          label: s.label,
          value: reqs.where((r) => r.status == s).length,
          color: switch (s) {
            RequestStatus.pending => AppColors.orange,
            RequestStatus.accepted => const Color(0xFF2F7DE1),
            RequestStatus.onTheWay => AppColors.navy,
            RequestStatus.completed => const Color(0xFF22B573),
            RequestStatus.cancelled => AppColors.greyText,
          },
        ),
    ];

List<DonutSegment> typeSegments(List<ServiceRequest> reqs) => [
      for (final t in AssistanceType.values)
        DonutSegment(
          label: t.label,
          value: reqs.where((r) => r.type == t).length,
          color: switch (t) {
            AssistanceType.flatTyre => AppColors.orange,
            AssistanceType.jumpStart => const Color(0xFF2F7DE1),
            AssistanceType.fuelDrop => AppColors.navy,
            AssistanceType.towing => const Color(0xFF22B573),
            AssistanceType.general => AppColors.greyText,
          },
        ),
    ];

List<DonutSegment> roleSegments(List<AppUser> users) => [
      DonutSegment(
        label: 'Drivers',
        value: users.where((u) => u.role == AppRole.driver).length,
        color: const Color(0xFF2F7DE1),
      ),
      DonutSegment(
        label: 'Mechanics',
        value: users.where((u) => u.role == AppRole.mechanic).length,
        color: AppColors.orange,
      ),
      DonutSegment(
        label: 'Admins',
        value: users.where((u) => u.role == AppRole.admin).length,
        color: AppColors.navy,
      ),
    ];

/// Requests per day, oldest → newest (7 entries).
List<int> weeklyCounts(List<ServiceRequest> reqs) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    return reqs.where((r) {
      final c = r.createdAt;
      return c != null &&
          c.year == day.year &&
          c.month == day.month &&
          c.day == day.day;
    }).length;
  });
}

class _AnalyticsSection extends StatelessWidget {
  final List<DonutSegment> byStatus;
  final List<DonutSegment> byRole;
  final List<DonutSegment> byType;
  final List<int> weekly;
  final int total;
  const _AnalyticsSection({
    required this.byStatus,
    required this.byRole,
    required this.byType,
    required this.weekly,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Requests by Status',
          subtitle: '$total total requests',
          child: DonutChart(segments: byStatus),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'This Week',
          subtitle: 'Requests per day',
          child: WeeklyBars(values: weekly),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Requests by Service',
          subtitle: 'Most needed help',
          child: TypeBars(segments: byType),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Users by Role',
          subtitle: 'Platform mix',
          child: DonutChart(segments: byRole),
        ),
      ],
    );
  }
}

class _DemoAnalytics extends StatelessWidget {
  const _DemoAnalytics();

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsSection(
      byStatus: [
        DonutSegment(
            label: 'Pending', value: 5, color: AppColors.orange),
        DonutSegment(
            label: 'Accepted',
            value: 3,
            color: Color(0xFF2F7DE1)),
        DonutSegment(
            label: 'On the way', value: 2, color: AppColors.navy),
        DonutSegment(
            label: 'Completed',
            value: 12,
            color: Color(0xFF22B573)),
        DonutSegment(
            label: 'Cancelled',
            value: 1,
            color: AppColors.greyText),
      ],
      byRole: [
        DonutSegment(
            label: 'Drivers',
            value: 96,
            color: Color(0xFF2F7DE1)),
        DonutSegment(
            label: 'Mechanics', value: 32, color: AppColors.orange),
        DonutSegment(label: 'Admins', value: 2, color: AppColors.navy),
      ],
      byType: [
        DonutSegment(
            label: 'Flat Tyre', value: 8, color: AppColors.orange),
        DonutSegment(
            label: 'Jump Start',
            value: 5,
            color: Color(0xFF2F7DE1)),
        DonutSegment(
            label: 'Fuel Drop', value: 3, color: AppColors.navy),
        DonutSegment(
            label: 'Towing Service',
            value: 6,
            color: Color(0xFF22B573)),
        DonutSegment(
            label: 'Request Assistance',
            value: 1,
            color: AppColors.greyText),
      ],
      weekly: [3, 5, 2, 6, 4, 7, 5],
      total: 23,
    );
  }
}

class _StatGrid extends StatelessWidget {
  final int totalUsers;
  final int drivers;
  final int mechanics;
  final int pending;
  const _StatGrid({
    required this.totalUsers,
    required this.drivers,
    required this.mechanics,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
            value: '$totalUsers',
            label: 'Total Users',
            icon: Icons.group_outlined,
            iconBg: const Color(0xFFE3EEFF),
            iconColor: const Color(0xFF2F7DE1)),
        _StatCard(
            value: '$pending',
            label: 'Pending Requests',
            icon: Icons.emergency_outlined,
            iconBg: const Color(0xFFFFEDE0),
            iconColor: AppColors.orange),
        _StatCard(
            value: '$drivers',
            label: 'Drivers',
            icon: Icons.directions_car_outlined,
            iconBg: const Color(0xFFE6F7EE),
            iconColor: const Color(0xFF22B573)),
        _StatCard(
            value: '$mechanics',
            label: 'Mechanics',
            icon: Icons.build_outlined,
            iconBg: const Color(0xFFFFF3DC),
            iconColor: AppColors.orange),
      ],
    );
  }
}

class _DemoStats extends StatelessWidget {
  const _DemoStats();

  @override
  Widget build(BuildContext context) {
    return const _StatGrid(
      totalUsers: 128,
      drivers: 96,
      mechanics: 32,
      pending: 5,
    );
  }
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

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================== REQUESTS TAB ==============================

class _AdminRequestsTab extends StatelessWidget {
  final AssistanceService assistance;
  const _AdminRequestsTab({required this.assistance});

  void _snack(BuildContext context, String msg) {
    // Replace any current message so fresh feedback is never queued
    // invisibly behind a stale snackbar.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Manage sheet: cancel an active request or delete it permanently.
  Future<void> _manage(BuildContext context, ServiceRequest r) async {
    final active = r.status != RequestStatus.completed &&
        r.status != RequestStatus.cancelled;
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${r.type.label} • ${r.refCode.isEmpty ? '—' : r.refCode}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Status: ${r.status.label}'),
            ),
            if (active)
              ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: AppColors.orange),
                title: const Text('Cancel request'),
                onTap: () => Navigator.pop(context, 'cancel'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red),
              title: const Text('Delete request',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    try {
      if (action == 'cancel') {
        await assistance.cancelRequest(r.id);
        if (!context.mounted) return;
        _snack(context, 'Request cancelled.');
      } else if (action == 'delete') {
        final yes = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete request?'),
            content: const Text(
                'This permanently removes the request and its chat.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (yes != true || !context.mounted) return;
        await assistance.deleteRequest(r.id);
        if (!context.mounted) return;
        _snack(context, 'Request deleted.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'All Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          if (!firebaseReady)
            const Column(
              children: [
                _AdminRequestRow(
                  title: 'Flat Tyre • #RM1058',
                  subtitle: 'Kasun Perera → Nimal • Accepted',
                ),
                SizedBox(height: 10),
                _AdminRequestRow(
                  title: 'Towing Service • #RM1024',
                  subtitle: 'Amal Silva • Pending',
                ),
              ],
            )
          else
            StreamBuilder<List<ServiceRequest>>(
              stream: assistance.watchAllRequests(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _AdminErrorBox(error: snap.error);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const _AdminEmptyBox(text: 'No requests yet.');
                }
                return Column(
                  children: [
                    for (final r in items) ...[
                      _AdminRequestRow(
                        title:
                            '${r.type.label} • ${r.refCode.isEmpty ? '—' : r.refCode}',
                        subtitle:
                            '${r.driverName.isEmpty ? 'Driver' : r.driverName}'
                            '${r.mechanicName.isEmpty ? '' : ' → ${r.mechanicName}'}'
                            ' • ${r.status.label}',
                        onTap: () => _manage(context, r),
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

class _AdminRequestRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _AdminRequestRow({
    required this.title,
    required this.subtitle,
    this.onTap,
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.navy,
                size: 22,
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
                      fontSize: 14.5,
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
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.greyText,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================== USERS TAB ==============================

class _AdminUsersTab extends StatelessWidget {
  final AuthService auth;
  const _AdminUsersTab({required this.auth});

  void _snack(BuildContext context, String msg) {
    // Replace any current message so fresh feedback is never queued
    // invisibly behind a stale snackbar.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Change a user's role (driver / mechanic / admin).
  Future<void> _changeRole(BuildContext context, AppUser user) async {
    final picked = await showModalBottomSheet<AppRole>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                user.name.isEmpty ? user.email : user.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Current: ${user.role.value}'),
            ),
            for (final r in AppRole.values)
              ListTile(
                leading: Icon(
                  r == AppRole.admin
                      ? Icons.shield_rounded
                      : r == AppRole.mechanic
                          ? Icons.build_rounded
                          : Icons.directions_car_filled_rounded,
                  color: r == user.role
                      ? AppColors.orange
                      : AppColors.greyText,
                ),
                title: Text(
                    '${r.value[0].toUpperCase()}${r.value.substring(1)}'),
                trailing: r == user.role
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.orange)
                    : null,
                onTap: () => Navigator.pop(context, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked == user.role) return;
    try {
      await auth.adminUpdateRole(uid: user.uid, role: picked);
      if (!context.mounted) return;
      _snack(context, 'Role changed to ${picked.value}.');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'All Users',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admins are created in the Firebase console only.',
            style: TextStyle(fontSize: 12.5, color: AppColors.greyText),
          ),
          const SizedBox(height: 10),
          if (!firebaseReady)
            const Column(
              children: [
                _AdminUserRow(
                  name: 'Kasun Perera',
                  email: 'kasun@example.com',
                  role: 'driver',
                ),
                SizedBox(height: 10),
                _AdminUserRow(
                  name: 'Nimal Fernando',
                  email: 'nimal@example.com',
                  role: 'mechanic',
                ),
              ],
            )
          else
            StreamBuilder<List<AppUser>>(
              stream: auth.watchAllUsers(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _AdminErrorBox(error: snap.error);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const _AdminEmptyBox(text: 'No users yet.');
                }
                return Column(
                  children: [
                    for (final u in items) ...[
                      _AdminUserRow(
                        name: u.name.isEmpty ? '—' : u.name,
                        email: u.email,
                        role: u.role.value,
                        onTap: () => _changeRole(context, u),
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

class _AdminUserRow extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback? onTap;
  const _AdminUserRow({
    required this.name,
    required this.email,
    required this.role,
    this.onTap,
  });

  Color get _roleColor => switch (role) {
        'admin' => AppColors.navy,
        'mechanic' => AppColors.orange,
        _ => const Color(0xFF2F7DE1),
      };

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
              radius: 20,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _roleColor,
              ),
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

// ============================== PAYMENTS TAB ==============================

/// Payment analysis: revenue totals, paid-vs-pending, method split,
/// daily revenue and every transaction with receipts.
class _AdminPaymentsTab extends StatelessWidget {
  final PaymentService pay;
  const _AdminPaymentsTab({required this.pay});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text(
            'Payments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          if (!firebaseReady)
            const _DemoPayments()
          else
            StreamBuilder<List<TxnRecord>>(
              stream: pay.watchAllTransactions(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _AdminErrorBox(error: snap.error);
                }
                return _PaymentsBody(txns: snap.data ?? []);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PaymentsBody extends StatelessWidget {
  final List<TxnRecord> txns;
  const _PaymentsBody({required this.txns});

  @override
  Widget build(BuildContext context) {
    final paid = txns.where((t) => t.isPaid).toList();
    final pending = txns.where((t) => !t.isPaid).toList();
    final paidSum = paid.fold<double>(0, (s, t) => s + t.amount).toInt();
    final pendingSum =
        pending.fold<double>(0, (s, t) => s + t.amount).toInt();
    final cardSum = paid
        .where((t) => t.method.toLowerCase().contains('card'))
        .fold<double>(0, (s, t) => s + t.amount)
        .toInt();
    final cashSum = paid
        .where((t) => !t.method.toLowerCase().contains('card'))
        .fold<double>(0, (s, t) => s + t.amount)
        .toInt();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MoneyStat(
                label: 'Revenue (paid)',
                value: 'Rs. $paidSum',
                icon: Icons.payments_rounded,
                iconBg: const Color(0xFFE6F7EE),
                iconColor: const Color(0xFF22B573),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyStat(
                label: 'Pending',
                value: 'Rs. $pendingSum',
                icon: Icons.schedule_outlined,
                iconBg: const Color(0xFFFFEDE0),
                iconColor: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Paid vs Pending',
          subtitle: 'By value',
          child: DonutChart(
            segments: [
              DonutSegment(
                  label: 'Paid',
                  value: paidSum,
                  color: const Color(0xFF22B573)),
              DonutSegment(
                  label: 'Pending',
                  value: pendingSum,
                  color: AppColors.orange),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Revenue by Method',
          subtitle: 'Paid transactions',
          child: DonutChart(
            segments: [
              DonutSegment(
                  label: 'Card',
                  value: cardSum,
                  color: const Color(0xFF2F7DE1)),
              DonutSegment(
                  label: 'Cash',
                  value: cashSum,
                  color: AppColors.navy),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnalyticsCard(
          title: 'Daily Revenue',
          subtitle: 'Last 7 days (Rs.)',
          child: WeeklyBars(values: _dailyRevenue(txns)),
        ),
        const SizedBox(height: 10),
        if (txns.isEmpty)
          const _AdminEmptyBox(text: 'No transactions yet.')
        else
          for (final t in txns.take(12)) ...[
            _AdminTxnRow(txn: t),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  static List<int> _dailyRevenue(List<TxnRecord> txns) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return txns
          .where((t) =>
              t.isPaid &&
              t.createdAt != null &&
              t.createdAt!.year == day.year &&
              t.createdAt!.month == day.month &&
              t.createdAt!.day == day.day)
          .fold<double>(0, (s, t) => s + t.amount)
          .toInt();
    });
  }
}

class _MoneyStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _MoneyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AdminTxnRow extends StatelessWidget {
  final TxnRecord txn;
  const _AdminTxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DigitalReceiptScreen(
            transaction: txn.toPaymentTransaction(),
          ),
        ),
      ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${txn.type} • ${txn.refCode}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    '${txn.payerName} → ${txn.payeeName.isEmpty ? 'unassigned' : txn.payeeName} • ${txn.method}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${txn.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  txn.isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: txn.isPaid
                        ? const Color(0xFF22B573)
                        : AppColors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPayments extends StatelessWidget {
  const _DemoPayments();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: _MoneyStat(
                label: 'Revenue (paid)',
                value: 'Rs. 24500',
                icon: Icons.payments_rounded,
                iconBg: Color(0xFFE6F7EE),
                iconColor: Color(0xFF22B573),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MoneyStat(
                label: 'Pending',
                value: 'Rs. 7000',
                icon: Icons.schedule_outlined,
                iconBg: Color(0xFFFFEDE0),
                iconColor: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const AnalyticsCard(
          title: 'Paid vs Pending',
          subtitle: 'By value',
          child: DonutChart(
            segments: [
              DonutSegment(
                  label: 'Paid',
                  value: 24500,
                  color: Color(0xFF22B573)),
              DonutSegment(
                  label: 'Pending',
                  value: 7000,
                  color: AppColors.orange),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const AnalyticsCard(
          title: 'Revenue by Method',
          subtitle: 'Paid transactions',
          child: DonutChart(
            segments: [
              DonutSegment(
                  label: 'Card',
                  value: 17500,
                  color: Color(0xFF2F7DE1)),
              DonutSegment(
                  label: 'Cash', value: 7000, color: AppColors.navy),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const AnalyticsCard(
          title: 'Daily Revenue',
          subtitle: 'Last 7 days (Rs.)',
          child: WeeklyBars(values: [1200, 3500, 0, 7000, 2800, 8500, 4200]),
        ),
      ],
    );
  }
}

class _AdminEmptyBox extends StatelessWidget {
  final String text;
  const _AdminEmptyBox({required this.text});

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

class _AdminErrorBox extends StatelessWidget {
  final Object? error;
  const _AdminErrorBox({this.error});

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
        'Could not load data.\n$error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB02A37), fontSize: 12.5),
      ),
    );
  }
}
