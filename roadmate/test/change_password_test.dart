import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/change_password_screen.dart';
import 'package:roadmate/screens/coming_soon_screen.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/services/auth_service.dart';

class _FakeInfo extends Fake implements UserInfo {
  _FakeInfo(this.providerId);
  @override
  final String providerId;
}

/// A signed-in user whose real password is [password]; records what the
/// app asks of it.
class _FakeUser extends Fake implements User {
  _FakeUser({
    List<String> providers = const ['password'],
    this.updateError,
  }) : providerData = [for (final p in providers) _FakeInfo(p)];

  String password = 'oldpass1';
  final Object? updateError;

  @override
  String? get email => 'kasun@example.com';
  @override
  final List<UserInfo> providerData;

  final reauthAttempts = <String>[];
  final updates = <String>[];

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    final c = credential as EmailAuthCredential;
    expect(c.email, 'kasun@example.com');
    reauthAttempts.add(c.password!);
    if (c.password != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return _FakeCred();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (updateError != null) throw updateError!;
    updates.add(newPassword);
    password = newPassword;
  }
}

class _FakeCred extends Fake implements UserCredential {}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.user);
  final _FakeUser? user;
  @override
  User? get currentUser => user;
}

const _profileUser = AppUser(
  uid: 'u1',
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '',
  role: AppRole.driver,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  late FakeFirebaseFirestore db;
  setUp(() {
    db = FakeFirebaseFirestore();
    firebaseReady = false;
  });

  group('AuthService', () {
    test('hasPassword: password accounts yes, Google-only no', () {
      expect(AuthService(auth: _FakeAuth(_FakeUser()), db: db).hasPassword,
          isTrue);
      expect(
          AuthService(
                  auth: _FakeAuth(_FakeUser(providers: ['google.com'])), db: db)
              .hasPassword,
          isFalse);
      expect(
          AuthService(
                  auth: _FakeAuth(_FakeUser(providers: ['google.com', 'password'])),
                  db: db)
              .hasPassword,
          isTrue);
      expect(AuthService(auth: _FakeAuth(null), db: db).hasPassword, isFalse);
    });

    test('changePassword re-authenticates first, then updates', () async {
      final user = _FakeUser();
      await AuthService(auth: _FakeAuth(user), db: db)
          .changePassword(currentPassword: 'oldpass1', newPassword: 'newpass2');
      expect(user.reauthAttempts, ['oldpass1']);
      expect(user.updates, ['newpass2']);
    });

    test('wrong current password: nothing is updated', () async {
      final user = _FakeUser();
      final auth = AuthService(auth: _FakeAuth(user), db: db);
      await expectLater(
        auth.changePassword(currentPassword: 'nope', newPassword: 'newpass2'),
        throwsA(predicate(AuthService.isWrongPassword)),
      );
      expect(user.updates, isEmpty);
      expect(user.password, 'oldpass1');
    });

    test('signed out → clear error', () async {
      final auth = AuthService(auth: _FakeAuth(null), db: db);
      await expectLater(
        auth.changePassword(currentPassword: 'a', newPassword: 'bbbbbb'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('isWrongPassword covers both Firebase codes', () {
      expect(AuthService.isWrongPassword(FirebaseAuthException(code: 'wrong-password')), isTrue);
      expect(AuthService.isWrongPassword(FirebaseAuthException(code: 'invalid-credential')), isTrue);
      expect(AuthService.isWrongPassword(FirebaseAuthException(code: 'weak-password')), isFalse);
      expect(AuthService.isWrongPassword(StateError('x')), isFalse);
    });
  });

  group('Change Password screen', () {
    Future<_FakeUser> pump(
      WidgetTester tester, {
      _FakeUser? user,
      bool viaProfile = false,
    }) async {
      _phone(tester);
      final u = user ?? _FakeUser();
      final auth = AuthService(auth: _FakeAuth(u), db: db);
      await tester.pumpWidget(MaterialApp(
        home: viaProfile
            ? ProfileScreen(user: _profileUser, authService: auth)
            : ChangePasswordScreen(authService: auth),
      ));
      await tester.pumpAndSettle();
      if (viaProfile) {
        await tester.tap(find.text('Change Password'));
        await tester.pumpAndSettle();
      }
      return u;
    }

    Future<void> fill(WidgetTester tester,
        {String cur = 'oldpass1',
        String next = 'newpass2',
        String? confirm}) async {
      final f = find.byType(TextField);
      await tester.enterText(f.at(0), cur);
      await tester.enterText(f.at(1), next);
      await tester.enterText(f.at(2), confirm ?? next);
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Update Password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
    }

    testWidgets('three obscured fields with eye toggles and the button',
        (tester) async {
      await pump(tester);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      final fields = find.byType(TextField);
      for (var i = 0; i < 3; i++) {
        expect(tester.widget<TextField>(fields.at(i)).obscureText, isTrue);
      }
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump();
      expect(tester.widget<TextField>(fields.at(0)).obscureText, isFalse);
      expect(tester.widget<TextField>(fields.at(1)).obscureText, isTrue);
    });

    testWidgets('validation: empty, too short, same as current, mismatch',
        (tester) async {
      final user = await pump(tester);

      await submit(tester);
      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Password should be at least 6 characters.'),
          findsOneWidget);

      await fill(tester, next: '12345');
      await submit(tester);
      expect(find.text('Password should be at least 6 characters.'),
          findsOneWidget);

      await fill(tester, cur: 'samepass', next: 'samepass');
      await submit(tester);
      expect(find.text('New password must be different from current password'),
          findsOneWidget);

      await fill(tester, confirm: 'different');
      await submit(tester);
      expect(find.text('Passwords do not match'), findsOneWidget);

      expect(user.reauthAttempts, isEmpty); // nothing reached Firebase
    });

    testWidgets('wrong current password → error under that field only',
        (tester) async {
      final user = await pump(tester);
      await fill(tester, cur: 'wrongpass');
      await submit(tester);

      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(user.updates, isEmpty);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);

      // Typing again clears it.
      await tester.enterText(find.byType(TextField).at(0), 'oldpass1');
      await tester.pump();
      expect(find.text('Current password is incorrect'), findsNothing);
    });

    testWidgets('success: updated, snackbar, back to Profile',
        (tester) async {
      final user = await pump(tester, viaProfile: true);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.byType(ComingSoonScreen), findsNothing);

      await fill(tester);
      await submit(tester);

      expect(user.reauthAttempts, ['oldpass1']);
      expect(user.updates, ['newpass2']);
      expect(find.byType(ChangePasswordScreen), findsNothing);
      expect(find.text('Personal Information'), findsOneWidget); // Profile
      expect(find.text('Password updated successfully'), findsOneWidget);
    });

    testWidgets('server says weak-password → shown under the new field',
        (tester) async {
      await pump(tester,
          user: _FakeUser(
              updateError: FirebaseAuthException(code: 'weak-password')));
      await fill(tester);
      await submit(tester);
      expect(find.text('Password should be at least 6 characters.'),
          findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('other failures: neutral snackbar, stays on the form',
        (tester) async {
      await pump(tester,
          user: _FakeUser(
              updateError:
                  FirebaseAuthException(code: 'network-request-failed')));
      await fill(tester);
      await submit(tester);
      expect(find.text('No internet connection. Check and retry.'),
          findsOneWidget);
      expect(find.text('Current password is incorrect'), findsNothing);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('Google-only account: explanation instead of the form',
        (tester) async {
      await pump(tester, user: _FakeUser(providers: ['google.com']));
      expect(
          find.text("Your account uses Google Sign-In, so there's no password "
              'to change.'),
          findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Update Password'), findsNothing);
      expect(find.text('Change Password'), findsOneWidget); // title stays
    });

    testWidgets('back arrow returns to Profile', (tester) async {
      await pump(tester, viaProfile: true);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsNothing);
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('without Firebase: not-connected message', (tester) async {
      _phone(tester);
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Firebase not connected'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
