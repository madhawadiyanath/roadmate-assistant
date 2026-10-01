import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'driver_dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Landing page after login / sign-up. Shows driver or mechanic UI
/// based on the Firestore role.
class RoleHome extends StatelessWidget {
  final AppUser user;
  final AuthService? authService;
  const RoleHome({super.key, required this.user, this.authService});

  @override
  Widget build(BuildContext context) {
    if (user.role == AppRole.driver) {
      return DriverDashboardScreen(user: user, authService: authService);
    }
    return _MechanicHome(user: user, authService: authService);
  }
}

class _MechanicHome extends StatelessWidget {
  final AppUser user;
  final AuthService? authService;
  const _MechanicHome({required this.user, this.authService});

  Future<void> _logout(BuildContext context) async {
    try {
      await (authService ?? AuthService()).signOut();
    } catch (_) {
      // Still leave — local session ends regardless.
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('RoadMate Mechanic'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${user.name.isEmpty ? 'Mechanic' : user.name}! 🔧',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Jobs near you will appear here. Stay ready!',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Logged in as ${user.role.value} • ${user.email}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ActionCard(
              icon: Icons.work_history_rounded,
              title: 'My Jobs',
              subtitle: 'Accept and track rescue jobs',
            ),
            const SizedBox(height: 12),
            const _ActionCard(
              icon: Icons.payments_outlined,
              title: 'Earnings',
              subtitle: 'Completed jobs & payouts',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.navy, size: 26),
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
            size: 16,
            color: AppColors.greyText,
          ),
        ],
      ),
    );
  }
}
