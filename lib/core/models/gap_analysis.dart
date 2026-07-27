class MissingSkill {
  final int id;
  final String name;
  final int importance;

  MissingSkill({
    required this.id,
    required this.name,
    required this.importance,
  });

  factory MissingSkill.fromJson(Map<String, dynamic> json) {
    return MissingSkill(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      importance: json['importance'] as int? ?? 0,
    );
  }
}

class GapAnalysis {
  final String? careerRoleName;
  final int progressPercent;
  final int knownSkillCount;
  final int requiredSkillCount;
  final List<MissingSkill> missingSkills;

  GapAnalysis({
    this.careerRoleName,
    required this.progressPercent,
    required this.knownSkillCount,
    required this.requiredSkillCount,
    required this.missingSkills,
  });

  bool get hasGoalSet =>
      careerRoleName != null && careerRoleName!.trim().isNotEmpty;

  factory GapAnalysis.fromJson(Map<String, dynamic> json) {
    return GapAnalysis(
      careerRoleName: json['careerRoleName'] as String?,
      progressPercent: json['progressPercent'] as int? ?? 0,
      knownSkillCount: json['knownSkillCount'] as int? ?? 0,
      requiredSkillCount: json['requiredSkillCount'] as int? ?? 0,
      missingSkills:
          (json['missingSkills'] as List<dynamic>? ?? [])
              .map((e) => MissingSkill.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.importance.compareTo(a.importance)),
    );
  }

  static GapAnalysis empty() => GapAnalysis(
    careerRoleName: null,
    progressPercent: 0,
    knownSkillCount: 0,
    requiredSkillCount: 0,
    missingSkills: [],
  );
}
