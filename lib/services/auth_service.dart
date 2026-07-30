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
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
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
      });

      return AppUser(
        uid: uid,
        email: normalizedEmail,
        name: name,
        role: role,
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
    );
  }
}

/// In-memory fallback used when Firebase isn't configured, so the app is
/// still fully usable (with local-only data) straight after checkout.
class LocalAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  final Map<String, ({String name, String password, UserRole role})> _users = {};

  AppUser? _currentUser;

  LocalAuthService() {
    Future<void>.microtask(() => _controller.add(_currentUser));
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final lowerEmail = email.toLowerCase();

    if (_users.containsKey(lowerEmail)) {
      throw Exception('An account with this email already exists.');
    }

    _users[lowerEmail] = (name: name, password: password, role: role);

    _currentUser = AppUser(
      uid: lowerEmail,
      email: lowerEmail,
      name: name,
      role: role,
    );

    _controller.add(_currentUser);
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
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
