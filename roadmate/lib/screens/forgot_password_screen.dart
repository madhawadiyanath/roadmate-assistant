import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

/// "Forgot Password": mails a Firebase reset link. The answer is always
/// the same neutral message, so the screen never reveals whether an
/// account exists for the address.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final AuthService? authService;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.authService,
  });

  static const neutralMessage =
      'If an account exists for this email, a reset link has been sent.';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  String? _error;
  bool _loading = false;
  bool _sent = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _looksLikeEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      // "No such user" must look the same as success.
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        if (mounted) setState(() => _sent = true);
      } else if (e is FirebaseAuthException && e.code == 'invalid-email') {
        if (mounted) setState(() => _error = 'Enter a valid email address');
      } else if (mounted) {
        _snack(AuthService.friendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Forgot Password?',
                subtitle: "Enter your email and we'll send a reset link",
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
                child: _sent ? _sentView() : _formView(),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthLabel(text: 'Email Address'),
        AuthTextField(
          hint: 'alex.driver@example.com',
          prefix: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          controller: _email,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 16),
        PrimaryAuthButton(
          text: 'Send Reset Link',
          isLoading: _loading,
          onPressed: _send,
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sentView() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F7EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 30, color: Color(0xFF1C8C5A)),
        ),
        const SizedBox(height: 14),
        const Text(
          ForgotPasswordScreen.neutralMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Open the link in the email to choose a new password. '
          'Check your spam folder if you cannot find it.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.greyText),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text(
            'Use a different email',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
