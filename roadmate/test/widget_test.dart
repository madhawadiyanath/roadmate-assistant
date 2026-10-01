import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/main.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/location_screen.dart';
import 'package:roadmate/screens/role_home.dart';

void main() {
  testWidgets('Onboarding screen shows on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Help on the road, always with you.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Get Started navigates to Sign In', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Sign In links to Sign Up and back', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Go to Sign Up via link
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account!'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('I am a'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Mechanic'), findsOneWidget);

    // Back to Sign In via AppBar back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('Driver dashboard shows all sections', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '+94771234567',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardScreen(user: user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Kasun'), findsOneWidget);
    expect(find.text('24/7 Priority Dispatch Active'), findsOneWidget);
    expect(find.text("Stuck on the road? We're here!"), findsOneWidget);
    expect(find.text('Request Assistance'), findsOneWidget);
    expect(find.text('Quick Services'), findsOneWidget);
    expect(find.text('Flat Tyre'), findsOneWidget);
    expect(find.text('Jump Start'), findsOneWidget);
    expect(find.text('Fuel Drop'), findsOneWidget);
    expect(find.text('Toyota Prius • CAB-8492'), findsOneWidget);
    expect(find.text('Recent Requests'), findsOneWidget);
    expect(find.text('Towing Service'), findsOneWidget);
  });

  testWidgets('Select Service opens full service page', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardScreen(user: user)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Select Service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select Service'));
    await tester.pumpAndSettle();

    expect(find.text('What do you need help with?'), findsOneWidget);
    expect(find.text('Flat Tyre'), findsWidgets);
    expect(find.text('Battery Jump Start'), findsOneWidget);
    expect(find.text('Fuel Delivery'), findsOneWidget);
    expect(find.text('Towing Service'), findsWidgets);
    expect(find.text('Puncture repair or tyre change'), findsOneWidget);
    expect(find.text('Immediate Dispatch?'), findsOneWidget);
    expect(find.text('LIVE DISPATCH'), findsOneWidget);
  });

  testWidgets('Location page shows map, GPS and address tools', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationScreen(
          user: user,
          serviceType: AssistanceType.flatTyre,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Location'), findsOneWidget);
    expect(find.text('Confirm your current location'), findsOneWidget);
    expect(find.text('Use Current Location'), findsOneWidget);
    expect(find.text('RECENT:'), findsOneWidget);
    expect(find.text('Outer Circular Hwy'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tapping Next without Firebase shows the setup hint.
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.textContaining('Firebase not connected'), findsOneWidget);
  });

  testWidgets('RoleHome routes driver to dashboard, mechanic to jobs', (
    WidgetTester tester,
  ) async {
    const driver = AppUser(
      uid: 'u1',
      name: 'Kasun',
      email: 'k@e.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: RoleHome(user: driver)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quick Services'), findsOneWidget);

    const mech = AppUser(
      uid: 'u2',
      name: 'Nimal',
      email: 'n@e.com',
      phone: '',
      role: AppRole.mechanic,
    );
    await tester.pumpWidget(const MaterialApp(home: RoleHome(user: mech)));
    await tester.pumpAndSettle();
    expect(find.text('My Jobs'), findsOneWidget);
  });
}
