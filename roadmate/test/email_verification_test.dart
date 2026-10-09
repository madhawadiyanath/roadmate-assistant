import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/auth_gate.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/forgot_password_screen.dart';
import 'package:roadmate/screens/onboarding_screen.dart';
import 'package:roadmate/screens/sign_in_screen.dart';
import 'package:roadmate/screens/sign_up_screen.dart';
import 'package:roadmate/screens/verify_email_screen.dart';
import 'package:roadmate/services/auth_service.dart';

final _after = AuthService.emailVerificationCutoff.add(const Duration(hours: 1));
final _before =
    AuthService.emailVerificationCutoff.subtract(const Duration(days: 30));

class _FakeInfo extends Fake implements UserInfo {
  _FakeInfo(this.providerId);
  @override
  final String providerId;
}

class _FakeMeta extends Fake implements UserMetadata {
  _FakeMeta(this.creationTime);
  @override
  final DateTime? creationTime;
}

class _FakeUser extends Fake implements User {
  _FakeUser({
    this.email = 'kasun@example.com',
    this.emailVerified = false,
    List<String> providers = const ['password'],
    DateTime? created,
    this.verifiedAfterReload = false,
  })  : providerData = [for (final p in providers) _FakeInfo(p)],
        metadata = _FakeMeta(created);

  @override
  String get uid => 'u1';
  @override
  final String? email;
  @override
  bool emailVerified;
  @override
  final List<UserInfo> providerData;
  @override
  final UserMetadata metadata;

  /// What a `reload()` will reveal (the user tapped the mailed link).
  bool verifiedAfterReload;
  bool failSend = false;
  int sends = 0;
  int reloads = 0;
  bool deleted = false;

  @override
  Future<void> reload() async {
    reloads++;
    if (verifiedAfterReload) emailVerified = true;
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    if (failSend) throw FirebaseAuthException(code: 'network-request-failed');
    sends++;
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> delete() async => deleted = true;
}

class _FakeCred extends Fake implements UserCredential {
  _FakeCred(this._user);
  final User? _user;
  @override
  User? get user => _user;
}

/// FirebaseAuth stand-in. [leaveFirebaseReady] style flip: once the app
/// has signed in/up, `firebaseReady` goes off so dashboards that open
/// afterwards run in offline mode instead of touching a real Firebase.
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({this.user, this.resetError, this.failSend = false});

  /// New accounts created through this auth fail to send the email.
  final bool failSend;

  _FakeUser? user;
  Object? resetError;
  bool signedOut = false;
  final resetEmails = <String>[];

  @override
  User? get currentUser => user;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    firebaseReady = false;
    user = _FakeUser(email: email, created: _after)..failSend = failSend;
    return _FakeCred(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    firebaseReady = false;
    return _FakeCred(user);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmails.add(email);
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    user = null;
  }

  @override
  Stream<User?> authStateChanges() {
    firebaseReady = false; // after AuthGate's own check
    return Stream.value(user);
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

const _appUser = AppUser(
  uid: 'u1',
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '',
  role: AppRole.driver,
);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    firebaseReady = false;
  });
  tearDown(() => firebaseReady = false);

  group('who needs to verify', () {
    test('only unverified password accounts created after the cutoff', () {
      bool needs(_FakeUser? u) => AuthService.userNeedsEmailVerification(u);

      expect(needs(null), isFalse);
      expect(needs(_FakeUser(created: _after)), isTrue);
      // Already verified.
      expect(needs(_FakeUser(created: _after, emailVerified: true)), isFalse);
      // Old accounts (e.g. as@gmail.com) are grandfathered.
      expect(needs(_FakeUser(created: _before)), isFalse);
      expect(needs(_FakeUser(created: null)), isFalse);
      // Google-only accounts skip it.
      expect(needs(_FakeUser(created: _after, providers: ['google.com'])),
          isFalse);
      // Password + Google linked, still unverified → asked.
      expect(
          needs(_FakeUser(created: _after, providers: ['google.com', 'password'])),
          isTrue);
    });
  });

  group('AuthService', () {
    test('signUp writes the profile and sends the verification email',
        () async {
      final fake = _FakeAuth();
      final auth = AuthService(auth: fake, db: db);

      final user = await auth.signUp(
        name: ' Kasun Perera ',
        email: 'kasun@example.com',
        phone: '0771234567',
        password: 'secret1',
        role: AppRole.mechanic,
      );

      expect(user.role, AppRole.mechanic);
      expect((await db.collection('users').doc('u1').get()).data()!['role'],
          'mechanic');
      expect(fake.user!.sends, 1);
      expect(auth.needsEmailVerification, isTrue);
    });

    test('a failed verification send does not undo the sign-up', () async {
      final fake = _FakeAuth(failSend: true);
      final auth = AuthService(auth: fake, db: db);

      final result = await auth.signUp(
        name: 'K',
        email: 'k@e.com',
        phone: '0771234567',
        password: 'secret1',
        role: AppRole.driver,
      );

      expect(result.uid, 'u1');
      expect(fake.user!.sends, 0); // the send threw
      expect(fake.user!.deleted, isFalse); // account kept
      expect((await db.collection('users').doc('u1').get()).exists, isTrue);
    });

    test('isEmailVerified reloads the user and reports the result', () async {
      final user = _FakeUser(created: _after, verifiedAfterReload: false);
      final auth = AuthService(auth: _FakeAuth(user: user), db: db);

      expect(await auth.isEmailVerified(), isFalse);
      expect(user.reloads, 1);

      user.verifiedAfterReload = true; // tapped the link
      expect(await auth.isEmailVerified(), isTrue);
      expect(auth.needsEmailVerification, isFalse);

      expect(await AuthService(auth: _FakeAuth(), db: db).isEmailVerified(),
          isFalse);
    });

    test('sendVerificationEmail needs a signed-in user', () async {
      final user = _FakeUser(created: _after);
      await AuthService(auth: _FakeAuth(user: user), db: db)
          .sendVerificationEmail();
      expect(user.sends, 1);

      expect(AuthService(auth: _FakeAuth(), db: db).sendVerificationEmail(),
          throwsA(isA<FirebaseAuthException>()));
    });

    test('sendPasswordReset trims the address', () async {
      final fake = _FakeAuth();
      await AuthService(auth: fake, db: db)
          .sendPasswordReset('  kasun@example.com ');
      expect(fake.resetEmails, ['kasun@example.com']);
    });
  });

  group('Verify email screen', () {
    Future<_FakeAuth> pumpVerify(
      WidgetTester tester, {
      bool justSent = false,
      bool verifiedAfterReload = false,
    }) async {
      _phone(tester);
      final fake = _FakeAuth(
          user: _FakeUser(created: _after, verifiedAfterReload: verifiedAfterReload));
      await tester.pumpWidget(MaterialApp(
        home: VerifyEmailScreen(
          user: _appUser,
          authService: AuthService(auth: fake, db: db),
          justSent: justSent,
        ),
      ));
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('shows the address and the three actions', (tester) async {
      await pumpVerify(tester);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('kasun@example.com'), findsOneWidget);
      expect(find.text("I've verified, continue"), findsOneWidget);
      expect(find.text('Resend email'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Resend: 60s cooldown after sign-up and after each resend',
        (tester) async {
      final fake = await pumpVerify(tester, justSent: true);
      expect(find.text('Resend email (60s)'), findsOneWidget);

      // Disabled during the cooldown: tapping sends nothing.
      await tester.tap(find.textContaining('Resend email'));
      await tester.pump();
      expect(fake.user!.sends, 0);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Resend email (30s)'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Resend email'), findsOneWidget);

      await tester.tap(find.text('Resend email'));
      await tester.pump();
      await tester.pump();
      expect(fake.user!.sends, 1);
      expect(find.text('Verification email sent to kasun@example.com.'),
          findsOneWidget);
      expect(find.text('Resend email (60s)'), findsOneWidget); // restarted
      // Let the timer run out so no timer is left pending.
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('not verified yet → message, stays on the page',
        (tester) async {
      final fake = await pumpVerify(tester);
      await tester.tap(find.text("I've verified, continue"));
      await tester.pumpAndSettle();

      expect(fake.user!.reloads, 1);
      expect(find.textContaining("isn't verified yet"), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(DriverDashboardScreen), findsNothing);
    });

    testWidgets('verified → dashboard', (tester) async {
      await pumpVerify(tester, verifiedAfterReload: true);
      await tester.tap(find.text("I've verified, continue"));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailScreen), findsNothing);
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    testWidgets('returning from the mail app re-checks by itself',
        (tester) async {
      await pumpVerify(tester, verifiedAfterReload: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    testWidgets('resume while still unverified is silent', (tester) async {
      await pumpVerify(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });

    testWidgets('Sign out (wrong email) leaves for onboarding',
        (tester) async {
      final fake = await pumpVerify(tester);
      await _tapVisible(tester, find.text('Sign out'));
      expect(fake.signedOut, isTrue);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });

  group('routing', () {
    testWidgets('Sign Up → Verify your email (email already sent)',
        (tester) async {
      _phone(tester);
      final fake = _FakeAuth();
      await tester.pumpWidget(MaterialApp(
        home: SignUpScreen(authService: AuthService(auth: fake, db: db)),
      ));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kasun Perera');
      await tester.enterText(fields.at(1), 'new@example.com');
      await tester.enterText(fields.at(2), '0771234567');
      await tester.enterText(fields.at(3), 'secret1');
      firebaseReady = true;
      await _tapVisible(tester, find.text('Sign Up'));

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.text('new@example.com'), findsOneWidget);
      expect(fake.user!.sends, 1);
      expect(find.byType(DriverDashboardScreen), findsNothing);
      expect(find.text('Resend email (60s)'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    Future<void> signIn(WidgetTester tester, _FakeUser user) async {
      _phone(tester);
      await db.collection('users').doc('u1').set({
        'name': 'Kasun Perera',
        'email': 'kasun@example.com',
        'phone': '',
        'role': 'driver',
      });
      await tester.pumpWidget(MaterialApp(
        home: SignInScreen(
            authService: AuthService(auth: _FakeAuth(user: user), db: db)),
      ));
      await tester.pumpAndSettle();
      firebaseReady = true;
      await _tapVisible(tester, find.text('Login'));
    }

    testWidgets('Sign In: new unverified account → verify screen',
        (tester) async {
      await signIn(tester, _FakeUser(created: _after));
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(DriverDashboardScreen), findsNothing);
      expect(find.text('Resend email'), findsOneWidget); // none just sent
    });

    testWidgets('Sign In: old (grandfathered) account → dashboard',
        (tester) async {
      await signIn(tester, _FakeUser(created: _before));
      expect(find.byType(VerifyEmailScreen), findsNothing);
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    testWidgets('Sign In: verified account → dashboard', (tester) async {
      await signIn(tester, _FakeUser(created: _after, emailVerified: true));
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    Future<void> gate(WidgetTester tester, _FakeUser user) async {
      _phone(tester);
      firebaseReady = true;
      await db.collection('users').doc('u1').set({
        'name': 'Kasun Perera',
        'email': 'kasun@example.com',
        'phone': '',
        'role': 'driver',
      });
      await tester.pumpWidget(MaterialApp(
        home: AuthGate(
            authService: AuthService(auth: _FakeAuth(user: user), db: db)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('AuthGate: unverified new account resumes on verify screen',
        (tester) async {
      await gate(tester, _FakeUser(created: _after));
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(DriverDashboardScreen), findsNothing);
    });

    testWidgets('AuthGate: grandfathered account goes straight in',
        (tester) async {
      await gate(tester, _FakeUser(created: _before));
      expect(find.byType(VerifyEmailScreen), findsNothing);
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    testWidgets('AuthGate: Google account is never asked', (tester) async {
      await gate(tester,
          _FakeUser(created: _after, providers: ['google.com'], emailVerified: true));
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });
  });

  group('Forgot password', () {
    Future<_FakeAuth> pumpForgot(WidgetTester tester,
        {Object? error, String email = ''}) async {
      _phone(tester);
      final fake = _FakeAuth(resetError: error);
      await tester.pumpWidget(MaterialApp(
        home: ForgotPasswordScreen(
          initialEmail: email,
          authService: AuthService(auth: fake, db: db),
        ),
      ));
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('Sign In "Forgot Password?" opens it with the email prefilled',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Forgot Password?'));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      // The login form's pre-filled email is carried over.
      expect(find.byWidgetPredicate((w) =>
          w is EditableText && w.controller.text == 'alex.driver@example.com'),
          findsOneWidget);
    });

    testWidgets('invalid email is rejected locally', (tester) async {
      final fake = await pumpForgot(tester);
      firebaseReady = true;
      await tester.enterText(find.byType(TextField), 'not-an-email');
      await _tapVisible(tester, find.text('Send Reset Link'));
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(fake.resetEmails, isEmpty);
    });

    testWidgets('success shows the neutral message', (tester) async {
      final fake = await pumpForgot(tester);
      firebaseReady = true;
      await tester.enterText(find.byType(TextField), ' kasun@example.com ');
      await _tapVisible(tester, find.text('Send Reset Link'));

      expect(fake.resetEmails, ['kasun@example.com']);
      expect(find.text(ForgotPasswordScreen.neutralMessage), findsOneWidget);
      expect(find.text('Send Reset Link'), findsNothing);
    });

    testWidgets('unknown email looks exactly like success', (tester) async {
      final fake = await pumpForgot(tester,
          error: FirebaseAuthException(code: 'user-not-found'));
      firebaseReady = true;
      await tester.enterText(find.byType(TextField), 'nobody@example.com');
      await _tapVisible(tester, find.text('Send Reset Link'));

      expect(fake.resetEmails, ['nobody@example.com']);
      expect(find.text(ForgotPasswordScreen.neutralMessage), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
      expect(find.textContaining('No account'), findsNothing);
    });

    testWidgets('real failures (offline) are reported', (tester) async {
      await pumpForgot(tester,
          error: FirebaseAuthException(code: 'network-request-failed'));
      firebaseReady = true;
      await tester.enterText(find.byType(TextField), 'kasun@example.com');
      await _tapVisible(tester, find.text('Send Reset Link'));

      expect(find.text('No internet connection. Check and retry.'),
          findsOneWidget);
      expect(find.text(ForgotPasswordScreen.neutralMessage), findsNothing);
    });

    testWidgets('without Firebase: hint, nothing sent', (tester) async {
      final fake = await pumpForgot(tester, email: 'kasun@example.com');
      await _tapVisible(tester, find.text('Send Reset Link'));
      expect(find.textContaining('Firebase not connected'), findsOneWidget);
      expect(fake.resetEmails, isEmpty);
    });

    testWidgets('"Use a different email" returns to the form',
        (tester) async {
      await pumpForgot(tester);
      firebaseReady = true;
      await tester.enterText(find.byType(TextField), 'kasun@example.com');
      await _tapVisible(tester, find.text('Send Reset Link'));
      await _tapVisible(tester, find.text('Use a different email'));
      expect(find.text('Send Reset Link'), findsOneWidget);
    });
  });
}
