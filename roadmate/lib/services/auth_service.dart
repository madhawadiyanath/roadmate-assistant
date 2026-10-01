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
      return user;
    } catch (_) {
      await cred.user?.delete();
      rethrow;
    }
  }

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
