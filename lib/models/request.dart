import 'package:meta/meta.dart';

enum RequestStatus { pending, accepted, declined }

RequestStatus requestStatusFromString(String? value) {
  return RequestStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => RequestStatus.pending,
  );
}

class ProjectRequest {
  const ProjectRequest({
    required this.id,
    required this.studentId,
    required this.staffId,
    required this.ideaId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String staffId;
  final String ideaId;
  final RequestStatus status;
  final DateTime? createdAt;

  factory ProjectRequest.fromMap(String id, Map<String, dynamic> data) {
    return ProjectRequest(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      staffId: data['staffId'] as String? ?? '',
      ideaId: data['ideaId'] as String? ?? '',
      status: requestStatusFromString(data['status'] as String?),
      createdAt: data['createdAt'] == null
          ? null
          : DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'staffId': staffId,
      'ideaId': ideaId,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ProjectRequest copyWith({
    String? id,
    String? studentId,
    String? staffId,
    String? ideaId,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return ProjectRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      staffId: staffId ?? this.staffId,
      ideaId: ideaId ?? this.ideaId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
