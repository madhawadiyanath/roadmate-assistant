import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'google_sign_in_flow.dart';
import 'role_home.dart';
import 'sign_up_screen.dart';
import 'verify_email_screen.dart';

class SignInScreen extends StatefulWidget {
  final AuthService? authService;
  const SignInScreen({super.key, this.authService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController(text: 'alex.driver@example.com');
  final _password = TextEditingController(text: 'password123');
  bool _loading = false;
  bool _googleBusy = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _email.text.trim(),
          authService: widget.authService,
        ),
      ),
    );
  }

  void _goSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      _show('Please enter a valid email address.');
      return;
    }
    if (_password.text.isEmpty) {
      _show('Please enter your password.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.signIn(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      final needsVerify = _auth.needsEmailVerification;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => needsVerify
              ? VerifyEmailScreen(user: user, authService: _auth)
              : RoleHome(user: user, authService: _auth),
        ),
        (_) => false,
      );
    } catch (e) {
      _show(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      await continueWithGoogle(context, auth: _auth);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 18),
              const AuthHeader(
                title: 'Welcome Back!',
                subtitle: 'Login to access real-time rescue & telemetry',
              ),
              const SizedBox(height: 18),

              // Form card
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
                    const AuthLabel(text: 'Email Address'),
                    AuthTextField(
                      hint: 'alex.driver@example.com',
                      prefix: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                    ),
                    const SizedBox(height: 14),
                    AuthLabel(
                      text: 'Password',
                      trailing: GestureDetector(
                        onTap: _forgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    AuthTextField(
                      hint: '••••••••••',
                      prefix: Icons.lock_outline_rounded,
                      obscure: true,
                      showToggle: true,
                      controller: _password,
                    ),
                    const SizedBox(height: 16),
                    PrimaryAuthButton(
                      text: 'Login',
                      isLoading: _loading,
                      onPressed: _login,
                    ),
                    const OrDivider(),
                    SocialAuthButton(
                      text: 'Continue with Google',
                      icon: const GoogleBadge(),
                      onPressed: _google,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Switch to sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 13.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _goSignUp,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const EmergencyBanner(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
