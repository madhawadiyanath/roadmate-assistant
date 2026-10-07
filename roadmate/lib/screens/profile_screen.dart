import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Read-only user profile: name, email, phone and role.
///
/// Shows the [AppUser] passed in from login immediately, then refreshes it
/// from `users/{uid}` (when Firebase is ready) so changes made elsewhere
/// show up.
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;

  const ProfileScreen({super.key, required this.user, this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppUser _user = widget.user;
  bool _loading = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    // Without Firebase (and no injected service) just keep the passed user.
    if (!firebaseReady && widget.authService == null) return;
    setState(() => _loading = true);
    try {
      final fresh = await _auth.getProfile(widget.user.uid);
      if (!mounted) return;
      if (fresh != null) setState(() => _user = fresh);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _initials {
    final parts =
        _user.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _orDash(String v) => v.trim().isEmpty ? '—' : v;

  @override
  Widget build(BuildContext context) {
    final roleLabel = _user.role == AppRole.driver ? 'Driver' : 'Mechanic';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.navyDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.navy,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user.name.trim().isEmpty
                            ? 'RoadMate user'
                            : _user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.peachBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Full name',
                    value: _orDash(_user.name)),
                _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _orDash(_user.email)),
                _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _orDash(_user.phone)),
                _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: roleLabel),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.greyText)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
