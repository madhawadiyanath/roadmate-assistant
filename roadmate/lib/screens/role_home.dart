import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'mechanic_dashboard_screen.dart';

/// Landing page after login / sign-up. Shows driver, mechanic or admin UI
/// based on the Firestore role.
class RoleHome extends StatelessWidget {
  final AppUser user;
  final AuthService? authService;
  const RoleHome({super.key, required this.user, this.authService});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case AppRole.driver:
        return DriverDashboardScreen(user: user, authService: authService);
      case AppRole.mechanic:
        return MechanicDashboardScreen(user: user, authService: authService);
      case AppRole.admin:
        return AdminDashboardScreen(user: user, authService: authService);
    }
  }
}
