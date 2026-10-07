import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/services/auth_service.dart';

void main() {
  const user = AppUser(
    uid: 'u1',
    name: 'Nimal Perera',
    email: 'nimal@example.com',
    phone: '0771234567',
    role: AppRole.driver,
  );

  testWidgets('shows name, email, phone and role', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen(user: user)));
    await tester.pumpAndSettle();

    expect(find.text('Nimal Perera'), findsWidgets);
    expect(find.text('nimal@example.com'), findsOneWidget);
    expect(find.text('0771234567'), findsOneWidget);
    expect(find.text('Driver'), findsWidgets);
    expect(find.text('NP'), findsOneWidget);
  });

  testWidgets('refreshes from Firestore and shows a dash for blanks',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'name': 'Kamal Silva',
      'email': 'kamal@example.com',
      'phone': '',
      'role': 'mechanic',
    });
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(user: user, authService: AuthService(db: db)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kamal Silva'), findsWidgets);
    expect(find.text('Mechanic'), findsWidgets);
    expect(find.text('—'), findsOneWidget);
  });
}
