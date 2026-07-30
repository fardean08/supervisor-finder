enum UserRole { student, staff, admin }

UserRole userRoleFromString(String? value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.student,
  );
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.interests = const [],
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;

  /// Areas of interest a student is looking for in a supervisor. Ignored
  /// for staff and admin accounts.
  final List<String> interests;

  bool get isStaff => role == UserRole.staff;
  bool get isStudent => role == UserRole.student;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    List<String>? interests,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      interests: interests ?? this.interests,
    );
  }
}
