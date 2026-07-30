import 'project_idea.dart';

class StaffProfile {
  const StaffProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.bio,
    required this.areasOfInterest,
    required this.projectIdeas,
  });

  final String uid;
  final String name;
  final String email;
  final String department;
  final String bio;
  final List<String> areasOfInterest;
  final List<ProjectIdea> projectIdeas;

  factory StaffProfile.empty({
    required String uid,
    required String name,
    required String email,
  }) {
    return StaffProfile(
      uid: uid,
      name: name,
      email: email,
      department: '',
      bio: '',
      areasOfInterest: const [],
      projectIdeas: const [],
    );
  }

  factory StaffProfile.fromMap(
    String uid,
    Map<String, dynamic> data,
    List<ProjectIdea> projectIdeas,
  ) {
    return StaffProfile(
      uid: uid,
      name: data['name'] as String? ?? 'Staff member',
      email: data['email'] as String? ?? '',
      department: data['department'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      areasOfInterest: List<String>.from(
        (data['areasOfInterest'] as List<dynamic>? ?? const []),
      ),
      projectIdeas: projectIdeas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'bio': bio,
      'areasOfInterest': areasOfInterest,
    };
  }

  StaffProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    String? bio,
    List<String>? areasOfInterest,
    List<ProjectIdea>? projectIdeas,
  }) {
    return StaffProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      bio: bio ?? this.bio,
      areasOfInterest: areasOfInterest ?? this.areasOfInterest,
      projectIdeas: projectIdeas ?? this.projectIdeas,
    );
  }
}
