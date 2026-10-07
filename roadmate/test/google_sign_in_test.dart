import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/auth_gate.dart';
import 'package:roadmate/screens/choose_role_screen.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/mechanic_dashboard_screen.dart';
import 'package:roadmate/screens/sign_in_screen.dart';
import 'package:roadmate/screens/sign_up_screen.dart';
import 'package:roadmate/services/auth_service.dart';
import 'package:roadmate/widgets/role_selector.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'g1';
  @override
  String? get displayName => 'Kasun Perera';
  @override
  String? get email => 'kasun@gmail.com';
}

class _FakeCred extends Fake implements UserCredential {
  _FakeCred(this._user);
  final User? _user;
  @override
  User? get user => _user;
}

/// Stand-in for FirebaseAuth: no network, records what was asked of it.
///
/// [leaveFirebaseReady] flips the global `firebaseReady` flag off once the
/// auth call has happened, so the dashboards that open afterwards use
/// their offline mode instead of touching a real Firebase.
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({this.user, this.error});

  User? user;
  Object? error;
  bool signedOut = false;
  int providerCalls = 0;
  AuthProvider? lastProvider;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    providerCalls++;
    lastProvider = provider;
    if (error != null) throw error!;
    firebaseReady = false;
    return _FakeCred(user);
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

void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    firebaseReady = false;
  });
  tearDown(() => firebaseReady = false);

  Future<Map<String, dynamic>?> userDoc(String uid) async =>
      (await db.collection('users').doc(uid).get()).data();

  group('AuthService', () {
    test('first-time Google user: no profile written until a role is chosen',
        () async {
      final fake = _FakeAuth(user: _FakeUser());
      final auth = AuthService(auth: fake, db: db);

      final outcome = await auth.signInWithGoogle();

      expect(fake.providerCalls, 1);
      expect(fake.lastProvider, isA<GoogleAuthProvider>());
      expect(outcome.isNewUser, isTrue);
      expect(outcome.uid, 'g1');
      expect(outcome.name, 'Kasun Perera');
      expect(outcome.email, 'kasun@gmail.com');
      expect(await userDoc('g1'), isNull);

      final user = await auth.createProfile(
        uid: outcome.uid,
        name: outcome.name,
        email: outcome.email,
        role: AppRole.mechanic,
        phone: ' +94771234567 ',
      );
      expect(user.role, AppRole.mechanic);
      final doc = (await userDoc('g1'))!;
      expect(doc['role'], 'mechanic');
      expect(doc['name'], 'Kasun Perera');
      expect(doc['email'], 'kasun@gmail.com');
      expect(doc['phone'], '+94771234567');
      expect(doc.containsKey('vehicle'), isFalse);
    });

    test('returning user (incl. linked email account) gets their profile',
        () async {
      await db.collection('users').doc('g1').set({
        'name': 'Existing',
        'email': 'kasun@gmail.com',
        'phone': '0771',
        'role': 'driver',
      });
      final auth = AuthService(auth: _FakeAuth(user: _FakeUser()), db: db);

      final outcome = await auth.signInWithGoogle();

      expect(outcome.isNewUser, isFalse);
      expect(outcome.profile!.name, 'Existing');
      expect(outcome.profile!.role, AppRole.driver);
    });

    test('phone is optional', () async {
      final auth = AuthService(auth: _FakeAuth(), db: db);
      await auth.createProfile(
          uid: 'g2', name: 'A', email: 'a@b.c', role: AppRole.driver);
      expect((await userDoc('g2'))!['phone'], '');
    });

    test('cancel codes and friendly messages', () {
      expect(
          AuthService.isCancelled(
              FirebaseAuthException(code: 'web-context-canceled')),
          isTrue);
      expect(AuthService.isCancelled(FirebaseAuthException(code: 'canceled')),
          isTrue);
      expect(
          AuthService.isCancelled(FirebaseAuthException(code: 'network-request-failed')),
          isFalse);
      expect(AuthService.isCancelled(StateError('x')), isFalse);
      expect(
          AuthService.friendlyMessage(FirebaseAuthException(
              code: 'account-exists-with-different-credential')),
          contains('already exists'));
    });
  });

  group('Sign In screen', () {
    Future<_FakeAuth> pumpSignIn(WidgetTester tester,
        {_FakeAuth? fake}) async {
      _phone(tester);
      final f = fake ?? _FakeAuth(user: _FakeUser());
      await tester.pumpWidget(MaterialApp(
        home: SignInScreen(authService: AuthService(auth: f, db: db)),
      ));
      await tester.pumpAndSettle();
      return f;
    }

    testWidgets('without Firebase: hint, no auth call', (tester) async {
      final fake = await pumpSignIn(tester);
      await _tapVisible(tester, find.text('Continue with Google'));
      expect(find.textContaining('Firebase not connected'), findsOneWidget);
      expect(fake.providerCalls, 0);
    });

    testWidgets('new user → role picker → profile created → dashboard',
        (tester) async {
      final fake = await pumpSignIn(tester);
      firebaseReady = true;
      await _tapVisible(tester, find.text('Continue with Google'));

      expect(fake.providerCalls, 1);
      expect(find.byType(ChooseRoleScreen), findsOneWidget);
      expect(find.text('Welcome, Kasun!'), findsOneWidget);
      expect(await userDoc('g1'), isNull); // nothing yet

      await tester.tap(find.text('Mechanic'));
      await tester.pump();
      await _tapVisible(tester, find.text('Continue'));

      expect(find.byType(MechanicDashboardScreen), findsOneWidget);
      expect((await userDoc('g1'))!['role'], 'mechanic');
    });

    testWidgets('returning user goes straight to their dashboard',
        (tester) async {
      await db.collection('users').doc('g1').set({
        'name': 'Kasun Perera',
        'email': 'kasun@gmail.com',
        'phone': '',
        'role': 'driver',
      });
      await pumpSignIn(tester);
      firebaseReady = true;
      await _tapVisible(tester, find.text('Continue with Google'));

      expect(find.byType(ChooseRoleScreen), findsNothing);
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
    });

    testWidgets('closing the Google sheet is silent', (tester) async {
      final fake = await pumpSignIn(
        tester,
        fake: _FakeAuth(
            error: FirebaseAuthException(code: 'web-context-canceled')),
      );
      firebaseReady = true;
      await _tapVisible(tester, find.text('Continue with Google'));

      expect(fake.providerCalls, 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('other failures show a friendly message', (tester) async {
      await pumpSignIn(
        tester,
        fake: _FakeAuth(
            error: FirebaseAuthException(code: 'network-request-failed')),
      );
      firebaseReady = true;
      await _tapVisible(tester, find.text('Continue with Google'));
      expect(find.text('No internet connection. Check and retry.'),
          findsOneWidget);
      expect(find.byType(ChooseRoleScreen), findsNothing);
    });
  });

  group('Role picker', () {
    Future<_FakeAuth> openPicker(WidgetTester tester) async {
      _phone(tester);
      final fake = _FakeAuth(user: _FakeUser());
      await tester.pumpWidget(MaterialApp(
        home: SignInScreen(authService: AuthService(auth: fake, db: db)),
      ));
      await tester.pumpAndSettle();
      firebaseReady = true;
      await _tapVisible(tester, find.text('Continue with Google'));
      expect(find.byType(ChooseRoleScreen), findsOneWidget);
      return fake;
    }

    testWidgets('invalid phone is rejected, valid/blank accepted',
        (tester) async {
      await openPicker(tester);
      await tester.enterText(find.byType(TextField), '12');
      await _tapVisible(tester, find.text('Continue'));
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(await userDoc('g1'), isNull);

      await tester.enterText(find.byType(TextField), '+94 77 123 4567');
      await _tapVisible(tester, find.text('Continue'));
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
      expect((await userDoc('g1'))!['role'], 'driver'); // default selection
      expect((await userDoc('g1'))!['phone'], '+94 77 123 4567');
    });

    testWidgets('Cancel signs out, creates nothing, returns to Sign In',
        (tester) async {
      final fake = await openPicker(tester);
      await _tapVisible(tester, find.text('Cancel'));

      expect(fake.signedOut, isTrue);
      expect(await userDoc('g1'), isNull);
      expect(find.byType(ChooseRoleScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('system back also signs out', (tester) async {
      final fake = await openPicker(tester);
      await tester.binding.handlePopRoute(); // Android back button
      await tester.pumpAndSettle();

      expect(fake.signedOut, isTrue);
      expect(await userDoc('g1'), isNull);
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  testWidgets('Sign Up: the role picked above pre-selects the picker',
      (tester) async {
    _phone(tester);
    final fake = _FakeAuth(user: _FakeUser());
    await tester.pumpWidget(MaterialApp(
      home: SignUpScreen(authService: AuthService(auth: fake, db: db)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mechanic'));
    await tester.pump();
    firebaseReady = true;
    await _tapVisible(tester, find.text('Continue with Google'));

    expect(find.byType(ChooseRoleScreen), findsOneWidget);
    expect(tester.widget<RoleSelector>(find.byType(RoleSelector)).selected,
        AppRole.mechanic);
  });

  group('AuthGate', () {
    testWidgets('signed in without a profile → role picker, not a silent driver',
        (tester) async {
      _phone(tester);
      firebaseReady = true;
      final fake = _FakeAuth(user: _FakeUser());
      await tester.pumpWidget(MaterialApp(
        home: AuthGate(authService: AuthService(auth: fake, db: db)),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseRoleScreen), findsOneWidget);
      expect(find.byType(DriverDashboardScreen), findsNothing);
      expect(await userDoc('g1'), isNull);

      // Cancelling here (root route) signs out.
      await _tapVisible(tester, find.text('Cancel'));
      expect(fake.signedOut, isTrue);
    });

    testWidgets('signed in with a profile → their dashboard', (tester) async {
      _phone(tester);
      firebaseReady = true;
      await db.collection('users').doc('g1').set({
        'name': 'Sampath',
        'email': 'kasun@gmail.com',
        'phone': '',
        'role': 'mechanic',
      });
      await tester.pumpWidget(MaterialApp(
        home: AuthGate(
            authService:
                AuthService(auth: _FakeAuth(user: _FakeUser()), db: db)),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseRoleScreen), findsNothing);
      expect(find.byType(MechanicDashboardScreen), findsOneWidget);
    });
  });
}
