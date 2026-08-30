import 'skill.dart';

enum RoadmapStepStatus { pending, inProgress, done }

RoadmapStepStatus roadmapStepStatusFromString(String? value) {
  switch (value) {
    case 'IN_PROGRESS':
      return RoadmapStepStatus.inProgress;
    case 'DONE':
      return RoadmapStepStatus.done;
    case 'PENDING':
    default:
      return RoadmapStepStatus.pending;
  }
}

class RoadmapStep {
  final int id;
  final int skillId;
  final String skillName;
  final SkillCategory skillCategory;
  final int stepOrder;
  final RoadmapStepStatus status;
  final DateTime? completedAt;

  RoadmapStep({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.skillCategory,
    required this.stepOrder,
    required this.status,
    this.completedAt,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      id: json['id'] as int,
      skillId: json['skillId'] as int,
      skillName: json['skillName'] as String? ?? '',
      skillCategory: skillCategoryFromString(json['skillCategory'] as String?),
      stepOrder: json['stepOrder'] as int? ?? 0,
      status: roadmapStepStatusFromString(json['status'] as String?),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }

  RoadmapStep copyWith({RoadmapStepStatus? status, DateTime? completedAt}) {
    return RoadmapStep(
      id: id,
      skillId: skillId,
      skillName: skillName,
      skillCategory: skillCategory,
      stepOrder: stepOrder,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
