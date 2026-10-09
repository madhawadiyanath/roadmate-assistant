import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/mechanic_dashboard_screen.dart';
import 'package:roadmate/screens/sign_in_screen.dart';
import 'package:roadmate/screens/sign_up_screen.dart';
import 'package:roadmate/services/auth_service.dart';

void main() {
  group('Sign Up & Authentication Flow Tests', () {
    testWidgets('Sign Up validation: checks full name required',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pump();

      expect(find.text('Please enter your full name.'), findsOneWidget);
    });

    testWidgets('Sign Up validation: checks valid email required',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Alex Perera');

      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Sign Up validation: checks phone required', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Alex Perera');
      await tester.enterText(textFields.at(1), 'alex@example.com');

      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pump();

      expect(find.text('Please enter your phone number.'), findsOneWidget);
    });

    testWidgets('Sign Up validation: checks password minimum length',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Alex Perera');
      await tester.enterText(textFields.at(1), 'alex@example.com');
      await tester.enterText(textFields.at(2), '+94 77 123 4567');
      await tester.enterText(textFields.at(3), '123');

      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pump();

      expect(find.text('Password should be at least 6 characters.'),
          findsOneWidget);
    });

    testWidgets(
        'Complete Sign Up flow: Driver selected, fills fields, navigates to Driver Dashboard without error',
        (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(authService: auth),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial screen state
      expect(find.text('Create Account!'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);

      // Fill in all four fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.enterText(textFields.at(1), 'john.doe@example.com');
      await tester.enterText(textFields.at(2), '+94 77 123 4567');
      await tester.enterText(textFields.at(3), 'secret123');
      await tester.pumpAndSettle();

      // Click "Sign Up" button
      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Confirm NO error snackbar was shown
      expect(find.textContaining('Firebase not connected'), findsNothing);
      expect(find.textContaining('Something went wrong'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);

      // Confirm successful navigation to Driver Dashboard
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
      expect(find.text('Hello, John'), findsOneWidget);
      expect(find.text('24/7 Priority Dispatch Active'), findsOneWidget);
      expect(find.text('Request Assistance'), findsOneWidget);
    });

    testWidgets(
        'Sign Up flow for Mechanic role navigates to Mechanic Dashboard',
        (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(authService: auth),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Mechanic role
      await tester.tap(find.text('Mechanic'));
      await tester.pumpAndSettle();

      // Fill fields
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Kamal Silva');
      await tester.enterText(textFields.at(1), 'kamal.mech@example.com');
      await tester.enterText(textFields.at(2), '+94 71 555 1234');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.pumpAndSettle();

      // Click Sign Up
      await tester.ensureVisible(find.text('Sign Up').first);
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Confirm NO error snackbar was shown
      expect(find.textContaining('Firebase not connected'), findsNothing);
      expect(find.textContaining('Something went wrong'), findsNothing);

      // Confirm navigation to Mechanic Dashboard
      expect(find.byType(MechanicDashboardScreen), findsOneWidget);
      expect(find.text('Kamal'), findsOneWidget);
    });

    testWidgets('Sign In flow works smoothly with local account',
        (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(authService: auth),
        ),
      );
      await tester.pumpAndSettle();

      // Default credentials are pre-filled (alex.driver@example.com)
      await tester.ensureVisible(find.text('Login').first);
      await tester.tap(find.text('Login').first);
      await tester.pumpAndSettle();

      // Navigates to Driver Dashboard
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
      expect(find.text('Hello, Alex'), findsOneWidget);
    });
  });
}
