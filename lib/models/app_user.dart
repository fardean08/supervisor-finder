enum UserRole { student, staff }

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
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;

  bool get isStaff => role == UserRole.staff;
  bool get isStudent => role == UserRole.student;

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
