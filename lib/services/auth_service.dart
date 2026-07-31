import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    List<String> interests = const [],
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Updates the current student's areas of interest, used to rank staff
  /// profiles by overlap on the browse screen.
  Future<void> updateInterests({
    required String uid,
    required List<String> interests,
  });
}

/// Real Firebase implementation. Email/password identity comes from
/// Firebase Auth; the user's role (student/staff) and name are kept in a
/// `users` collection in Firestore, keyed by uid.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap(_mapUser);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    List<String> interests = const [],
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await credentials.user?.updateDisplayName(name);

      final uid = credentials.user!.uid;

      await _usersCollection.doc(uid).set({
        'name': name,
        'email': normalizedEmail,
        'role': role.name,
        'interests': interests,
      });

      return AppUser(
        uid: uid,
        email: normalizedEmail,
        name: name,
        role: role,
        interests: interests,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists. Log in instead.');
      }

      rethrow;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final credentials = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = await _mapUser(credentials.user);
      return user!;
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        throw Exception('No account exists for this email. Please sign up first.');
      }

      if (error.code == 'wrong-password' || error.code == 'invalid-credential') {
        throw Exception('Incorrect email or password.');
      }

      rethrow;
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  @override
  Future<void> updateInterests({
    required String uid,
    required List<String> interests,
  }) {
    return _usersCollection.doc(uid).update({'interests': interests});
  }

  Future<AppUser?> _mapUser(firebase_auth.User? user) async {
    if (user == null) {
      return null;
    }

    final doc = await _usersCollection.doc(user.uid).get();
    final data = doc.data();

    return AppUser(
      uid: user.uid,
      email: user.email ?? data?['email'] as String? ?? '',
      name: user.displayName ?? data?['name'] as String? ?? 'User',
      role: userRoleFromString(data?['role'] as String?),
      interests: List<String>.from(
        (data?['interests'] as List<dynamic>?) ?? const [],
      ),
    );
  }
}

/// In-memory fallback used when Firebase isn't configured, so the app is
/// still fully usable (with local-only data) straight after checkout.
class LocalAuthService implements AuthService {
  LocalAuthService({this.onUserChanged});

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  final Map<String, ({String name, String password, UserRole role, List<String> interests})>
      _users = {};

  /// Called whenever a user is created or edited, so an external directory
  /// (e.g. for the admin dashboard) can keep a list of all local accounts.
  final void Function(AppUser user)? onUserChanged;

  AppUser? _currentUser;

  // A plain broadcast stream only reaches subscribers who are already
  // listening when an event is added — it doesn't replay anything to a
  // listener that shows up later. AuthGate's StreamBuilder subscribes
  // once, when it first builds, so if any sign-in/out happened before
  // that (or even just unlucky timing), it would otherwise be stuck
  // showing the loading spinner forever, having missed the one event
  // that would've told it who's signed in. Yielding the current value
  // first means every new subscriber gets the real state immediately,
  // no matter when they start listening.
  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    List<String> interests = const [],
  }) async {
    final lowerEmail = email.toLowerCase();

    if (_users.containsKey(lowerEmail)) {
      throw Exception('An account with this email already exists.');
    }

    _users[lowerEmail] =
        (name: name, password: password, role: role, interests: interests);

    _currentUser = AppUser(
      uid: lowerEmail,
      email: lowerEmail,
      name: name,
      role: role,
      interests: interests,
    );

    _controller.add(_currentUser);
    onUserChanged?.call(_currentUser!);
    return _currentUser!;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final lowerEmail = email.toLowerCase();
    final user = _users[lowerEmail];

    if (user == null) {
      throw Exception('No account exists for this email. Please sign up first.');
    }

    if (user.password != password) {
      throw Exception('Incorrect email or password.');
    }

    _currentUser = AppUser(
      uid: lowerEmail,
      email: lowerEmail,
      name: user.name,
      role: user.role,
      interests: user.interests,
    );

    _controller.add(_currentUser);
    onUserChanged?.call(_currentUser!);
    return _currentUser!;
  }

  @override
  Future<void> updateInterests({
    required String uid,
    required List<String> interests,
  }) async {
    final existing = _users[uid];
    if (existing == null) return;

    _users[uid] = (
      name: existing.name,
      password: existing.password,
      role: existing.role,
      interests: interests,
    );

    if (_currentUser?.uid == uid) {
      _currentUser = _currentUser!.copyWith(interests: interests);
      _controller.add(_currentUser);
    }

    onUserChanged?.call(
      AppUser(uid: uid, email: uid, name: existing.name, role: existing.role, interests: interests),
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
