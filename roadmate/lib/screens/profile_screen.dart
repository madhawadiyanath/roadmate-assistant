import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'onboarding_screen.dart';

/// Driver / mechanic profile with CRUD for personal + vehicle details.
/// Pops the updated [AppUser] after a successful save.
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  const ProfileScreen({super.key, required this.user, this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _vehicle;
  late final TextEditingController _plate;

  AuthService get _auth => widget.authService ?? AuthService();
  bool get _isDriver => widget.user.role == AppRole.driver;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
    _vehicle = TextEditingController(
        text: widget.user.vehicle.isEmpty
            ? demoVehicleName
            : widget.user.vehicle);
    _plate = TextEditingController(
        text: widget.user.plate.isEmpty ? demoVehiclePlate : widget.user.plate);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    _plate.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        vehicle: _isDriver ? _vehicle.text : '',
        plate: _isDriver ? _plate.text : '',
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
    final initial = widget.user.name.trim().isEmpty
        ? '?'
        : widget.user.name.trim()[0].toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        actions: [
          if (_editing)
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() => _editing = false),
              child: const Text('Cancel'),
            )
          else
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.user.name.isEmpty ? '—' : widget.user.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      switch (widget.user.role) {
                        AppRole.driver => 'DRIVER',
                        AppRole.mechanic => 'MECHANIC',
                        AppRole.admin => 'ADMIN',
                      },
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Personal details
            _SectionCard(
              title: 'Personal Details',
              children: [
                _Field(
                  label: 'Full Name',
                  controller: _name,
                  editing: _editing,
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Phone Number',
                  controller: _phone,
                  editing: _editing,
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
            const SizedBox(height: 12),

            // Vehicle details (drivers only)
            if (_isDriver)
              _SectionCard(
                title: 'Vehicle Details',
                children: [
                  _Field(
                    label: 'Vehicle Model',
                    controller: _vehicle,
                    editing: _editing,
                    icon: Icons.directions_car_outlined,
                    hint: 'Toyota Axio',
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Plate Number',
                    controller: _plate,
                    editing: _editing,
                    icon: Icons.confirmation_number_outlined,
                    hint: 'ABC 1234',
                  ),
                ],
              ),
            if (_isDriver) const SizedBox(height: 12),

            // Save button in edit mode
            if (_editing)
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            if (_editing) const SizedBox(height: 12),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
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
  final bool editing;
  final IconData icon;
  final TextInputType keyboardType;
  final String? hint;
  const _Field({
    required this.label,
    required this.controller,
    required this.editing,
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
          enabled: editing,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14.5, color: AppColors.navyDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.fieldHint, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: AppColors.greyText),
            filled: true,
            fillColor:
                editing ? Colors.white : AppColors.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFE3E8F0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: editing
                      ? AppColors.navy
                      : const Color(0xFFE3E8F0),
                  width: 1.2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.navy, width: 1.4),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
