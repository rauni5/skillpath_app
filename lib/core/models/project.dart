import 'skill.dart';

enum ProjectStatus { open, full, completed, cancelled, unknown }

ProjectStatus projectStatusFromString(String? value) {
  switch (value) {
    case 'OPEN':
      return ProjectStatus.open;
    case 'FULL':
      return ProjectStatus.full;
    case 'COMPLETED':
      return ProjectStatus.completed;
    case 'CANCELLED':
      return ProjectStatus.cancelled;
    default:
      return ProjectStatus.unknown;
  }
}

class Project {
  final int id;
  final String name;
  final String? description;
  final String? difficulty;
  final int teamSize;
  final ProjectStatus status;
  final int ownerId;
  final List<Skill> requiredSkills;
  final DateTime? createdAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    required this.teamSize,
    required this.status,
    required this.ownerId,
    required this.requiredSkills,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      teamSize: json['teamSize'] as int? ?? 0,
      status: projectStatusFromString(json['status'] as String?),
      ownerId: json['ownerId'] as int? ?? 0,
      requiredSkills: (json['requiredSkills'] as List<dynamic>? ?? [])
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}
