import 'skill.dart';

class BranchRequirement {
  final int skillId;
  final String name;
  final SkillCategory category;
  final int importance;

  BranchRequirement({
    required this.skillId,
    required this.name,
    required this.category,
    required this.importance,
  });

  factory BranchRequirement.fromJson(Map<String, dynamic> json) {
    return BranchRequirement(
      skillId: json['skillId'] as int,
      name: json['name'] as String? ?? '',
      category: skillCategoryFromString(json['category'] as String?),
      importance: json['importance'] as int? ?? 1,
    );
  }
}
