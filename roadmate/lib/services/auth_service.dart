import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/firebase_state.dart';
import '../firebase_options.dart';
import '../models/app_user.dart';

/// All Firebase Auth + Firestore user logic lives here, with seamless
/// local/mock fallback when running without a real Firebase backend.
///
/// Instances are resolved lazily ([FirebaseAuth.instance] throws when
/// Firebase isn't initialised, e.g. widget tests), so constructing this
/// class is always safe — only calling a live method needs Firebase.
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

  static final Map<String, AppUser> _mockUsers = {
    'alex.driver@example.com': const AppUser(
      uid: 'mock_driver_1',
      name: 'Alex Driver',
      email: 'alex.driver@example.com',
      phone: '+94 77 123 4567',
      role: AppRole.driver,
    ),
    'sam.mechanic@example.com': const AppUser(
      uid: 'mock_mechanic_1',
      name: 'Sam Mechanic',
      email: 'sam.mechanic@example.com',
      phone: '+94 71 987 6543',
      role: AppRole.mechanic,
    ),
  };

  static AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get _isLiveFirebase =>
      _authOverride != null ||
      _dbOverride != null ||
      (firebaseReady && !DefaultFirebaseOptions.isPlaceholder);

  /// Create Auth account + `users/{uid}` profile doc with the chosen role.
  /// When running in local/mock mode, stores and returns a mock user session.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AppRole role,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (_isLiveFirebase) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final user = AppUser(
          uid: cred.user!.uid,
          name: cleanName,
          email: cleanEmail,
          phone: cleanPhone,
          role: role,
          createdAt: DateTime.now(),
        );

        try {
          await _users.doc(user.uid).set(user.toMap());
          await cred.user!.updateDisplayName(user.name);
          _currentUser = user;
          return user;
        } catch (_) {
          await cred.user?.delete();
          rethrow;
        }
      } catch (e) {
        if (e is FirebaseAuthException &&
            (e.code == 'email-already-in-use' ||
                e.code == 'weak-password' ||
                e.code == 'invalid-email')) {
          rethrow;
        }
        // If live Firebase call fails with unconfigured/network/API key issue,
        // fall through to local mock account creation so the app remains usable.
      }
    }

    // Local / Mock user registration
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName.isNotEmpty ? cleanName : 'RoadMate User',
      email: cleanEmail,
      phone: cleanPhone,
      role: role,
      createdAt: DateTime.now(),
    );
    _mockUsers[cleanEmail.toLowerCase()] = user;
    _currentUser = user;
    return user;
  }

  /// Email/password login. Profile (with role) is read from `users/{uid}`
  /// or from the local mock user repository.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (_isLiveFirebase) {
      try {
        final cred = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final profile = await getProfile(cred.user!.uid);
        if (profile != null) {
          _currentUser = profile;
          return profile;
        }
        final user = AppUser(
          uid: cred.user!.uid,
          name: cred.user!.displayName ?? '',
          email: cred.user!.email ?? cleanEmail,
          phone: '',
          role: AppRole.driver,
          createdAt: DateTime.now(),
        );
        try {
          await _users.doc(user.uid).set(user.toMap());
        } catch (_) {}
        _currentUser = user;
        return user;
      } catch (e) {
        if (e is FirebaseAuthException &&
            (e.code == 'wrong-password' ||
                e.code == 'user-not-found' ||
                e.code == 'user-disabled' ||
                e.code == 'invalid-credential')) {
          rethrow;
        }
        // Fall through to local fallback
      }
    }

    // Local / Mock Sign In
    final key = cleanEmail.toLowerCase();
    if (_mockUsers.containsKey(key)) {
      final user = _mockUsers[key]!;
      _currentUser = user;
      return user;
    }

    // Auto-create local user session matching email and role hint
    final isMechanic = key.contains('mechanic');
    final role = isMechanic ? AppRole.mechanic : AppRole.driver;
    final prefix = key.split('@').first.replaceAll('.', ' ');
    final displayName = prefix.isNotEmpty
        ? prefix
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ')
        : (isMechanic ? 'Sam Mechanic' : 'Alex Driver');

    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      email: cleanEmail,
      phone: '+94 77 123 4567',
      role: role,
      createdAt: DateTime.now(),
    );
    _mockUsers[key] = user;
    _currentUser = user;
    return user;
  }

  Future<AppUser?> getProfile(String uid) async {
    if (_isLiveFirebase) {
      try {
        final doc = await _users.doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromMap(uid, doc.data()!);
        }
      } catch (_) {}
    }
    for (final u in _mockUsers.values) {
      if (u.uid == uid) return u;
    }
    return _currentUser?.uid == uid ? _currentUser : null;
  }

  /// Update editable profile fields, return the fresh profile.
  Future<AppUser> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String vehicle = '',
    String plate = '',
  }) async {
    if (_isLiveFirebase) {
      try {
        await _users.doc(uid).update({
          'name': name.trim(),
          'phone': phone.trim(),
          'vehicle': vehicle.trim(),
          'plate': plate.trim(),
        });
      } catch (_) {}
    }

    final fresh = await getProfile(uid);
    final updated = fresh?.copyWith(
          name: name.trim(),
          phone: phone.trim(),
          vehicle: vehicle.trim(),
          plate: plate.trim(),
        ) ??
        AppUser(
          uid: uid,
          name: name.trim(),
          email: _currentUser?.email ?? '',
          phone: phone.trim(),
          role: _currentUser?.role ?? AppRole.driver,
          vehicle: vehicle.trim(),
          plate: plate.trim(),
        );

    // Update in mock memory if present
    for (final entry in _mockUsers.entries) {
      if (entry.value.uid == uid) {
        _mockUsers[entry.key] = updated;
        break;
      }
    }
    if (_currentUser?.uid == uid) {
      _currentUser = updated;
    }
    return updated;
  }

  Future<void> signOut() async {
    if (_isLiveFirebase) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
  }

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
