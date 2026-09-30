import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

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
                    const PrimaryAuthButton(text: 'Sign Up'),
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
