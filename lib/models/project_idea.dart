class ProjectIdea {
  const ProjectIdea({
    required this.id,
    required this.title,
    required this.description,
    this.area = '',
  });

  final String id;
  final String title;
  final String description;

  /// Optional tag linking the idea to one of the staff member's areas of
  /// interest, e.g. "Graph theory".
  final String area;

  factory ProjectIdea.fromMap(String id, Map<String, dynamic> data) {
    return ProjectIdea(
      id: id,
      title: data['title'] as String? ?? 'Untitled idea',
      description: data['description'] as String? ?? '',
      area: data['area'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'area': area,
    };
  }

  ProjectIdea copyWith({
    String? id,
    String? title,
    String? description,
    String? area,
  }) {
    return ProjectIdea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      area: area ?? this.area,
    );
  }
}
