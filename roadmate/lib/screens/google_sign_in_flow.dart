import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'choose_role_screen.dart';
import 'role_home.dart';

/// "Continue with Google", shared by the Sign In and Sign Up screens.
///
/// Returning users go straight to their dashboard. First-time users land
/// on [ChooseRoleScreen] (pre-selecting [initialRole]) and only get a
/// profile once they pick a role. A closed Google sheet is not an error.
Future<void> continueWithGoogle(
  BuildContext context, {
  required AuthService auth,
  AppRole initialRole = AppRole.driver,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (!firebaseReady) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Firebase not connected yet. Add google-services files first.'),
    ));
    return;
  }
  try {
    final outcome = await auth.signInWithGoogle();
    if (!context.mounted) return;
    final profile = outcome.profile;
    if (profile != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleHome(user: profile)),
        (_) => false,
      );
    } else {
      navigator.push(MaterialPageRoute(
        builder: (_) => ChooseRoleScreen(
          uid: outcome.uid,
          name: outcome.name,
          email: outcome.email,
          initialRole: initialRole,
          authService: auth,
        ),
      ));
    }
  } catch (e) {
    if (AuthService.isCancelled(e)) return;
    messenger.showSnackBar(
      SnackBar(content: Text(AuthService.friendlyMessage(e))),
    );
  }
}
