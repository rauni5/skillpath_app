class SkillPopularity {
  final int skillId;
  final String name;
  final int userCount;

  SkillPopularity({
    required this.skillId,
    required this.name,
    required this.userCount,
  });

  factory SkillPopularity.fromJson(Map<String, dynamic> json) {
    return SkillPopularity(
      skillId: json['skillId'] as int,
      name: json['name'] as String? ?? '',
      userCount: json['userCount'] as int? ?? 0,
    );
  }
}
