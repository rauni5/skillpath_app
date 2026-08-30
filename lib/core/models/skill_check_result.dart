import 'skill.dart';

class SkillCheckResult {
  final int score;
  final int maxScore;

  /// Null when the score didn't reach the Beginner threshold.
  final SkillProficiency? proficiency;
  final bool passed;
  final List<bool> correctness;

  SkillCheckResult({
    required this.score,
    required this.maxScore,
    required this.proficiency,
    required this.passed,
    required this.correctness,
  });

  factory SkillCheckResult.fromJson(Map<String, dynamic> json) {
    return SkillCheckResult(
      score: json['score'] as int? ?? 0,
      maxScore: json['maxScore'] as int? ?? 0,
      proficiency: json['proficiency'] == null
          ? null
          : skillProficiencyFromString(json['proficiency'] as String?),
      passed: json['passed'] as bool? ?? false,
      correctness: (json['correctness'] as List<dynamic>? ?? [])
          .map((e) => e as bool)
          .toList(),
    );
  }
}
