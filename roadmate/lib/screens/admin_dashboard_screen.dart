import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart';

/// Admin home: platform stats, every request, every user.
/// Admins log in with email + password like everyone else — the account
/// itself is created in the Firebase console (never via app sign-up).
class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  final AssistanceService? assistanceService;

  const AdminDashboardScreen({
    super.key,
    required this.user,
    this.authService,
    this.assistanceService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();
  AuthService get _auth => widget.authService ?? AuthService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
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
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group_rounded),
            label: 'Users',
          ),
        ],
      ),
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
            const _DemoStats()
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
                  return _StatGrid(
                    totalUsers: users.length,
                    drivers: users
                        .where((u) => u.role == AppRole.driver)
                        .length,
                    mechanics: users
                        .where((u) => u.role == AppRole.mechanic)
                        .length,
                    pending: reqs
                        .where((r) => r.status == RequestStatus.pending)
                        .length,
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
  const _AdminRequestRow({required this.title, required this.subtitle});

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
        ],
      ),
    );
  }
}

// ============================== USERS TAB ==============================

class _AdminUsersTab extends StatelessWidget {
  final AuthService auth;
  const _AdminUsersTab({required this.auth});

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
  const _AdminUserRow({
    required this.name,
    required this.email,
    required this.role,
  });

  Color get _roleColor => switch (role) {
        'admin' => AppColors.navy,
        'mechanic' => AppColors.orange,
        _ => const Color(0xFF2F7DE1),
      };

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
        ],
      ),
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
