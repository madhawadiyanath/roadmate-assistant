import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/emergency_contact_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/striped_placeholder.dart';
import 'change_password_screen.dart';
import 'coming_soon_screen.dart';
import 'emergency_contacts_screen.dart';
import 'manage_methods_screen.dart';
import 'onboarding_screen.dart';
import 'saved_vehicles_screen.dart';
import 'transactions_screen.dart';

/// Profile: photo, name, role and a menu (view mode); "Personal
/// Information" opens the name/phone edit mode. Vehicles live in
/// Saved Vehicles, not here. Pops the updated [AppUser] after a save.
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;

  /// Injectable for tests/previews; default to the real services.
  final VehicleService? vehicleService;
  final EmergencyContactService? contactService;

  const ProfileScreen({
    super.key,
    required this.user,
    this.authService,
    this.vehicleService,
    this.contactService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _phone;

  AuthService get _auth => widget.authService ?? AuthService();
  bool get _isDriver => widget.user.role == AppRole.driver;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// Leave edit mode and discard anything typed.
  void _cancelEdit() {
    _name.text = widget.user.name;
    _phone.text = widget.user.phone;
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Please enter your full name.');
      return;
    }
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _auth.updateProfile(
        uid: widget.user.uid,
        name: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      _snack('Profile updated.');
      Navigator.pop(context, updated);
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
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
      backgroundColor: _editing ? AppColors.pageBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateTopBar(onBack: _editing ? null : () => Navigator.pop(context)),
            if (_editing)
              RoadMatePageTitle(title: 'Edit Profile', onBack: _cancelEdit),
            Expanded(child: _editing ? _editBody() : _viewBody()),
          ],
        ),
      ),
    );
  }

  // ---------------------------- view mode ----------------------------

  Widget _viewBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        children: [
          const SizedBox(height: 4),
          const StripedPlaceholder(
            label: 'profile photo',
            width: 104,
            height: 104,
            circle: true,
          ),
          const SizedBox(height: 12),
          Text(
            widget.user.name.isEmpty ? '—' : widget.user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          _RoleBadge(
            label: switch (widget.user.role) {
              AppRole.driver => 'Driver',
              AppRole.mechanic => 'Mechanic',
              AppRole.admin => 'ADMIN',
            },
          ),
          const SizedBox(height: 18),
          _MenuRow(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            onTap: () => setState(() => _editing = true),
          ),
          if (widget.user.role == AppRole.mechanic)
            _MenuRow(
              icon: Icons.build_outlined,
              title: 'Services Offered',
              onTap: () => _push(const ComingSoonScreen(
                title: 'Services Offered',
                icon: Icons.build_outlined,
              )),
            ),
          if (_isDriver)
            _MenuRow(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle Information',
              onTap: () => _push(SavedVehiclesScreen(
                uid: widget.user.uid,
                service: widget.vehicleService,
              )),
            ),
          if (_isDriver)
            _MenuRow(
              icon: Icons.contacts_outlined,
              title: 'Emergency Contacts',
              onTap: () => _push(EmergencyContactsScreen(
                uid: widget.user.uid,
                service: widget.contactService,
              )),
            ),
          if (_isDriver)
            _MenuRow(
              icon: Icons.credit_card_outlined,
              title: 'Payment Methods',
              onTap: () => _push(ManageMethodsScreen(uid: widget.user.uid)),
            ),
          if (widget.user.role != AppRole.admin)
            _MenuRow(
              icon: Icons.receipt_long_outlined,
              title: _isDriver ? 'Transaction History' : 'Income History',
              onTap: () => _push(TransactionsScreen(
                uid: widget.user.uid,
                mode: _isDriver ? TxnMode.payer : TxnMode.payee,
              )),
            ),
          _MenuRow(
            icon: Icons.description_outlined,
            title: 'Documents',
            onTap: () => _push(const ComingSoonScreen(
              title: 'Documents',
              icon: Icons.description_outlined,
            )),
          ),
          _MenuRow(
            icon: Icons.verified_user_outlined,
            title: 'Change Password',
            onTap: () =>
                _push(ChangePasswordScreen(authService: widget.authService)),
          ),
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: _logout,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
            icon: const Icon(Icons.logout_rounded, size: 22),
            label: const Text(
              'Logout',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- edit mode ----------------------------

  Widget _editBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _PhotoEditor(
            onTap: () => _snack('Photo upload is not available yet.'),
          ),
          const SizedBox(height: 4),
          _SectionCard(
            title: 'Personal Details',
            children: [
              _Field(
                label: 'Full Name',
                controller: _name,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Phone Number',
                controller: _phone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: '+94 77 123 4567',
              ),
              const SizedBox(height: 12),
              _ReadOnlyRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email Address',
                value: widget.user.email,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 21),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: _saving ? null : _cancelEdit,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.fieldFill,
                foregroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Green pill under the name ("Driver" / "Mechanic").
class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFE8D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 17, color: Color(0xFF1C8C5A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C8C5A),
            ),
          ),
        ],
      ),
    );
  }
}

/// One profile menu line: icon, title, chevron, thin divider below.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE3E8F5))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 27, color: AppColors.navy),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 26, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }
}

/// Edit-mode photo block: striped placeholder, camera badge and a
/// "Change photo" link. Upload itself is not built yet.
class _PhotoEditor extends StatelessWidget {
  final VoidCallback onTap;
  const _PhotoEditor({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change photo',
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const StripedPlaceholder(
                    label: 'profile photo',
                    width: 104,
                    height: 104,
                    circle: true,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: 19, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Change photo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final String? hint;
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.greyText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14.5, color: AppColors.navyDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.fieldHint, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: AppColors.greyText),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE3E8F0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.greyText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.greyText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 14.5, color: AppColors.navyDark),
                ),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.fieldHint),
            ],
          ),
        ),
      ],
    );
  }
}
