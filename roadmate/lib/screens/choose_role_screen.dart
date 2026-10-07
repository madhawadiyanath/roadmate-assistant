import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/role_selector.dart';
import 'role_home.dart';

/// Shown to someone who is signed in with Google but has no
/// `users/{uid}` profile yet: pick Driver / Mechanic (and optionally a
/// phone number), then the profile is created. Cancelling signs the
/// Firebase account out again so no half-registered account is left.
class ChooseRoleScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String email;
  final AppRole initialRole;
  final AuthService? authService;

  const ChooseRoleScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
    this.initialRole = AppRole.driver,
    this.authService,
  });

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  final _phone = TextEditingController();
  late AppRole _role = widget.initialRole;
  String? _phoneError;
  bool _saving = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Phone is optional; when given it needs 7–15 digits.
  bool _validate() {
    final text = _phone.text.trim();
    final digits = text.replaceAll(RegExp(r'\D'), '').length;
    setState(() {
      _phoneError =
          text.isNotEmpty && (digits < 7 || digits > 15)
              ? 'Enter a valid phone number'
              : null;
    });
    return _phoneError == null;
  }

  Future<void> _continue() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final user = await _auth.createProfile(
        uid: widget.uid,
        name: widget.name,
        email: widget.email,
        role: _role,
        phone: _phone.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleHome(user: user)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Sign the half-registered Google account out and leave.
  Future<void> _cancel() async {
    if (_saving) return;
    try {
      await _auth.signOut();
    } catch (_) {
      // Leaving anyway.
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.name.trim().isEmpty
        ? ''
        : ', ${widget.name.trim().split(' ').first}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 18),
                AuthHeader(
                  title: 'Welcome$first!',
                  subtitle: 'Tell us how you will use RoadMate',
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFEDF1F7),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthLabel(text: 'I am a'),
                      RoleSelector(
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: 14),
                      const AuthLabel(text: 'Phone Number (optional)'),
                      AuthTextField(
                        hint: '+94 77 123 4567',
                        prefix: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        controller: _phone,
                        errorText: _phoneError,
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      PrimaryAuthButton(
                        text: 'Continue',
                        isLoading: _saving,
                        onPressed: _continue,
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: _saving ? null : _cancel,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
