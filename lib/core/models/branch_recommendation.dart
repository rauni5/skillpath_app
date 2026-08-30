class SkillRef {
  final int id;
  final String name;
  final int importance;

  SkillRef({required this.id, required this.name, required this.importance});

  factory SkillRef.fromJson(Map<String, dynamic> json) {
    return SkillRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      importance: json['importance'] as int? ?? 0,
    );
  }
}

class BranchRecommendation {
  final int branchId;
  final String name;
  final String? description;
  final double matchScore; // 0-100
  final List<SkillRef> knownSkills;
  final List<SkillRef> missingSkills;

  BranchRecommendation({
    required this.branchId,
    required this.name,
    this.description,
    required this.matchScore,
    this.knownSkills = const [],
    this.missingSkills = const [],
  });

  factory BranchRecommendation.fromJson(Map<String, dynamic> json) {
    return BranchRecommendation(
      branchId: json['branchId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
      knownSkills: (json['knownSkills'] as List<dynamic>? ?? [])
          .map((e) => SkillRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      missingSkills: (json['missingSkills'] as List<dynamic>? ?? [])
          .map((e) => SkillRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
