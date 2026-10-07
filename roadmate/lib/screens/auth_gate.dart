import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'choose_role_screen.dart';
import 'onboarding_screen.dart';
import 'role_home.dart';

/// Decides the first screen: logged-in users resume their dashboard,
/// everyone else (or no Firebase config) sees onboarding.
class AuthGate extends StatelessWidget {
  final AuthService? authService;
  const AuthGate({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();
    if (!firebaseReady) return const OnboardingScreen();
    return StreamBuilder<User?>(
      stream: auth.authChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
          );
        }
        final fbUser = snap.data;
        if (fbUser == null) return const OnboardingScreen();
        return FutureBuilder<AppUser?>(
          future: auth.getProfile(fbUser.uid),
          builder: (context, prof) {
            if (prof.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.navy),
                ),
              );
            }
            final profile = prof.data;
            if (profile == null) {
              // Signed in (e.g. Google) but never picked a role.
              return ChooseRoleScreen(
                uid: fbUser.uid,
                name: fbUser.displayName ?? '',
                email: fbUser.email ?? '',
                authService: authService,
              );
            }
            return RoleHome(user: profile);
          },
        );
      },
    );
  }
}
