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

class KnownSkill {
  final int id;
  final String name;
  final int importance;

  KnownSkill({required this.id, required this.name, required this.importance});

  factory KnownSkill.fromJson(Map<String, dynamic> json) {
    return KnownSkill(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      importance: json['importance'] as int? ?? 0,
    );
  }
}

class GapAnalysis {
  final String? careerRoleName;
  // Field names kept as branchId/branchName to match the API's JSON keys —
  // "Specialization" is a display-only label used in the UI, not a model rename.
  final int? branchId;
  final String? branchName;
  final int progressPercent;
  final int knownSkillCount;
  final int requiredSkillCount;
  final List<KnownSkill> knownSkills;
  final List<MissingSkill> missingSkills;

  GapAnalysis({
    this.careerRoleName,
    this.branchId,
    this.branchName,
    required this.progressPercent,
    required this.knownSkillCount,
    required this.requiredSkillCount,
    required this.knownSkills,
    required this.missingSkills,
  });

  bool get hasGoalSet =>
      careerRoleName != null && careerRoleName!.trim().isNotEmpty;

  factory GapAnalysis.fromJson(Map<String, dynamic> json) {
    return GapAnalysis(
      careerRoleName: json['careerRoleName'] as String?,
      branchId: json['branchId'] as int?,
      branchName: json['branchName'] as String?,
      progressPercent: json['progressPercent'] as int? ?? 0,
      knownSkillCount: json['knownSkillCount'] as int? ?? 0,
      requiredSkillCount: json['requiredSkillCount'] as int? ?? 0,
      knownSkills:
          (json['knownSkills'] as List<dynamic>? ?? [])
              .map((e) => KnownSkill.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.importance.compareTo(a.importance)),
      missingSkills:
          (json['missingSkills'] as List<dynamic>? ?? [])
              .map((e) => MissingSkill.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.importance.compareTo(a.importance)),
    );
  }

  static GapAnalysis empty() => GapAnalysis(
    careerRoleName: null,
    branchId: null,
    branchName: null,
    progressPercent: 0,
    knownSkillCount: 0,
    requiredSkillCount: 0,
    knownSkills: [],
    missingSkills: [],
  );
}
