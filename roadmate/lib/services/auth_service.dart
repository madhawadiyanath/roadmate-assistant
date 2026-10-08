import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// All Firebase Auth + Firestore user logic lives here.
///
/// Instances are resolved lazily ([FirebaseAuth.instance] throws when
/// Firebase isn't initialised, e.g. widget tests), so constructing this
/// class is always safe — only calling a method needs Firebase.
class AuthService {
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _authOverride = auth,
        _dbOverride = db;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  /// Firebase-Auth session stream. Null = logged out.
  /// Accessing it needs Firebase, so the gate checks `firebaseReady` first.
  Stream<User?> authChanges() => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Create Auth account + `users/{uid}` profile doc with the chosen role.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AppRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
    );

    try {
      await _users.doc(user.uid).set(user.toMap());
      await cred.user!.updateDisplayName(user.name);
    } catch (_) {
      await cred.user?.delete();
      rethrow;
    }
    // Verification mail is best-effort: a failed send must not undo the
    // sign-up — the verify screen has a "Resend email" button.
    try {
      await cred.user!.sendEmailVerification();
    } catch (_) {}
    return user;
  }

  // ------------------------ Email verification ------------------------

  /// Accounts created before this moment are never asked to verify their
  /// email (they signed up before verification existed).
  static final DateTime emailVerificationCutoff =
      DateTime.utc(2026, 10, 7, 8, 0);

  /// Whether [user] must verify their email before using the app: a
  /// password account (Google accounts are already verified), not yet
  /// verified, created after [emailVerificationCutoff].
  static bool userNeedsEmailVerification(User? user) {
    if (user == null || user.emailVerified) return false;
    if (!user.providerData.any((p) => p.providerId == 'password')) {
      return false;
    }
    final created = user.metadata.creationTime;
    return created != null && created.isAfter(emailVerificationCutoff);
  }

  /// [userNeedsEmailVerification] for the currently signed-in user.
  bool get needsEmailVerification =>
      userNeedsEmailVerification(_auth.currentUser);

  /// (Re)send the verification email to the signed-in user.
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You are signed out. Please sign in again.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Refresh the signed-in user from Firebase and report whether their
  /// email is verified now (they may have just tapped the link).
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // --------------------------- Password reset ---------------------------

  /// Send Firebase's password-reset email (the link opens Firebase's hosted
  /// "set a new password" page).
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // -------------------------- Change password --------------------------

  /// Whether the signed-in account has a password (false for accounts that
  /// only ever signed in with Google — they have none to change).
  bool get hasPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  /// Change the signed-in user's password: re-authenticate with
  /// [currentPassword] first, then set [newPassword].
  ///
  /// Throws [FirebaseAuthException]: `wrong-password` / `invalid-credential`
  /// when the current password is wrong (see [isWrongPassword]),
  /// `weak-password` when Firebase rejects the new one.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You are signed out. Please sign in again.',
      );
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
    await user.updatePassword(newPassword);
  }

  /// True for the error codes Firebase uses when a password is wrong.
  static bool isWrongPassword(Object e) =>
      e is FirebaseAuthException &&
      (e.code == 'wrong-password' || e.code == 'invalid-credential');

  /// Email/password login. Profile (with role) is read from `users/{uid}`.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await getProfile(cred.user!.uid);
    if (profile == null) {
      final user = AppUser(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? '',
        email: cred.user!.email ?? email.trim(),
        phone: '',
        role: AppRole.driver,
      );
      await _users.doc(user.uid).set(user.toMap());
      return user;
    }
    return profile;
  }

  Future<AppUser?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// Live list of every user (admin oversight — rules allow admins only).
  Stream<List<AppUser>> watchAllUsers() {
    return _users.limit(100).snapshots().map(
          (s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  /// Update the editable profile fields (name and phone only — vehicles
  /// live in `users/{uid}/vehicles`), return the fresh profile. Other
  /// fields on the doc are left untouched.
  Future<AppUser> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _users.doc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
    });
    final fresh = await getProfile(uid);
    return fresh ??
        AppUser(
          uid: uid,
          name: name.trim(),
          email: '',
          phone: phone.trim(),
          role: AppRole.driver,
        );
  }

  // ------------------------- Google sign-in -------------------------

  /// "Continue with Google" via Firebase's own provider flow (no extra
  /// package). Returns the existing profile, or — for someone signing in
  /// for the first time — a [GoogleSignInOutcome.newUser] that still needs
  /// a role: nothing is written to `users/{uid}` until [createProfile] runs.
  ///
  /// If the Google email already has an email/password account Firebase
  /// links them (default behaviour) and that account's profile is returned.
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    final cred = await _auth.signInWithProvider(GoogleAuthProvider());
    final fbUser = cred.user;
    if (fbUser == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Google sign-in did not return a user.',
      );
    }
    final profile = await getProfile(fbUser.uid);
    if (profile != null) return GoogleSignInOutcome.existing(profile);
    return GoogleSignInOutcome.newUser(
      uid: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
    );
  }

  /// Create the `users/{uid}` doc for a signed-in user that has none yet
  /// (Google sign-in, after they picked a role).
  Future<AppUser> createProfile({
    required String uid,
    required String name,
    required String email,
    required AppRole role,
    String phone = '',
  }) async {
    final user = AppUser(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
    );
    await _users.doc(uid).set(user.toMap());
    return user;
  }

  /// True when the user simply closed/cancelled the Google sheet.
  static bool isCancelled(Object e) =>
      e is FirebaseAuthException &&
      (e.code == 'canceled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request');

  Future<void> signOut() => _auth.signOut();

  /// Human-readable message for auth errors shown in SnackBars.
  static String friendlyMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try Sign In.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password. Try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Try again in a minute.';
        case 'network-request-failed':
          return 'No internet connection. Check and retry.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. '
              'Sign in with your password instead.';
        case 'canceled':
        case 'web-context-canceled':
          return 'Sign-in was cancelled.';
        case 'permission-denied':
          return 'Database access denied. Check Firestore rules.';
        default:
          return e.message ?? 'Something went wrong. Try again.';
      }
    }
    if (e is FirebaseException) {
      return e.message ?? 'Database error. Try again.';
    }
    return 'Something went wrong. Try again.';
  }
}

/// Result of [AuthService.signInWithGoogle]: either a returning user
/// ([profile] set) or a first-time user who still has to choose a role.
class GoogleSignInOutcome {
  final AppUser? profile;
  final String uid;
  final String name;
  final String email;

  const GoogleSignInOutcome._({
    this.profile,
    required this.uid,
    required this.name,
    required this.email,
  });

  factory GoogleSignInOutcome.existing(AppUser profile) => GoogleSignInOutcome._(
        profile: profile,
        uid: profile.uid,
        name: profile.name,
        email: profile.email,
      );

  const GoogleSignInOutcome.newUser({
    required String uid,
    required String name,
    required String email,
  }) : this._(uid: uid, name: name, email: email);

  bool get isNewUser => profile == null;
}
