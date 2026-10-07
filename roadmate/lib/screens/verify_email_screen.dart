import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart';
import 'role_home.dart';

/// Blocking "Verify your email" page for new email/password accounts.
///
/// The user opens the link Firebase mailed them, comes back and taps
/// "I've verified, continue" (we also re-check automatically when the app
/// returns to the foreground). Verification is a one-off: once the email
/// is verified, normal password login works as before.
class VerifyEmailScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;

  /// True right after sign-up (the email was sent a moment ago), so the
  /// Resend button starts on its cooldown.
  final bool justSent;

  static const resendCooldown = Duration(seconds: 60);

  const VerifyEmailScreen({
    super.key,
    required this.user,
    this.authService,
    this.justSent = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _cooldown = 0;
  bool _checking = false;
  bool _resending = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.justSent) _startCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// Back from the mail app: check quietly, no snackbar if still unverified.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(silent: true);
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = VerifyEmailScreen.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await _auth.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RoleHome(user: widget.user)),
          (_) => false,
        );
      } else if (!silent) {
        _snack("Your email isn't verified yet. Open the link in the email "
            'we sent, then tap again.');
      }
    } catch (e) {
      if (mounted && !silent) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await _auth.sendVerificationEmail();
      if (!mounted) return;
      _snack('Verification email sent to ${widget.user.email}.');
      _startCooldown();
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// Typo recovery: leave this account and start again.
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Leaving anyway.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _cooldown <= 0 && !_resending;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 18),
              const AuthHeader(
                title: 'Verify your email',
                subtitle: 'One last step before you get started',
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
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined,
                          size: 30, color: AppColors.navy),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'We sent a verification link to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Open the email, tap the link, then come back and '
                      'continue. Check your spam folder if you cannot find it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _checking ? null : () => _check(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "I've verified, continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: canResend ? _resend : null,
                      child: Text(
                        _cooldown > 0
                            ? 'Resend email (${_cooldown}s)'
                            : 'Resend email',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: canResend
                              ? AppColors.orange
                              : AppColors.fieldHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Wrong email? ',
                    style: TextStyle(color: AppColors.greyText, fontSize: 13.5),
                  ),
                  GestureDetector(
                    onTap: _signOut,
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
