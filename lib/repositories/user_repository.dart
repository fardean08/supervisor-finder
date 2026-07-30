import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Read-only directory of every account in the system, used by the admin
/// dashboard to list staff and students.
abstract class UserRepository {
  Future<List<AppUser>> fetchAllUsers();
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<AppUser>> fetchAllUsers() async {
    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser(
        uid: doc.id,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? 'User',
        role: userRoleFromString(data['role'] as String?),
        interests: List<String>.from(
          (data['interests'] as List<dynamic>?) ?? const [],
        ),
      );
    }).toList();
  }
}

/// In-memory directory backing the local/demo auth flow. [LocalAuthService]
/// pushes every signed-up or updated user into this via its
/// `onUserChanged` callback so the admin dashboard can see them.
class MemoryUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};

  void upsert(AppUser user) {
    _users[user.uid] = user;
  }

  @override
  Future<List<AppUser>> fetchAllUsers() async {
    return List<AppUser>.from(_users.values);
  }
}
