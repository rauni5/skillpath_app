import 'skill.dart';

class RoleRequirement {
  final int skillId;
  final String name;
  final SkillCategory category;
  final int importance;

  RoleRequirement({
    required this.skillId,
    required this.name,
    required this.category,
    required this.importance,
  });

  factory RoleRequirement.fromJson(Map<String, dynamic> json) {
    return RoleRequirement(
      skillId: json['skillId'] as int,
      name: json['name'] as String? ?? '',
      category: skillCategoryFromString(json['category'] as String?),
      importance: json['importance'] as int? ?? 1,
    );
  }
}
