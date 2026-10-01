import 'package:flutter/material.dart';
import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/role_selector.dart';
import 'role_home.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  final AuthService? authService;
  const SignUpScreen({super.key, this.authService});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  AppRole _role = AppRole.driver;
  bool _loading = false;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _goSignIn() async {
    // If we came from Sign In, just pop. Otherwise push Sign In.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      final didPop = await navigator.maybePop();
      if (!didPop && mounted) {
        navigator.push(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    } else {
      navigator.push(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter your full name.';
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      return 'Please enter a valid email address.';
    }
    if (_phone.text.trim().isEmpty) return 'Please enter your phone number.';
    if (_password.text.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!firebaseReady) {
      _show('Firebase not connected yet. Add google-services files first.');
      return;
    }
    final error = _validate();
    if (error != null) {
      _show(error);
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.signUp(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleHome(user: user)),
        (_) => false,
      );
    } catch (e) {
      _show(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Create Account!',
                subtitle: 'Join RoadMate for 24/7 rescue & telemetry',
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
                    const AuthLabel(text: 'Full Name'),
                    AuthTextField(
                      hint: 'Alex Driver',
                      prefix: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      controller: _name,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Email Address'),
                    AuthTextField(
                      hint: 'alex.driver@example.com',
                      prefix: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Phone Number'),
                    AuthTextField(
                      hint: '+94 77 123 4567',
                      prefix: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Password'),
                    AuthTextField(
                      hint: 'Create a strong password',
                      prefix: Icons.lock_outline_rounded,
                      obscure: true,
                      showToggle: true,
                      controller: _password,
                    ),
                    const SizedBox(height: 16),
                    PrimaryAuthButton(
                      text: 'Sign Up',
                      isLoading: _loading,
                      onPressed: _signUp,
                    ),
                    const OrDivider(),
                    const SocialAuthButton(
                      text: 'Continue with Google',
                      icon: GoogleBadge(),
                    ),
                    const SizedBox(height: 10),
                    const SocialAuthButton(
                      text: 'Continue with Apple',
                      icon: Icon(
                        Icons.apple,
                        size: 22,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 13.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _goSignIn,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.navy,
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
