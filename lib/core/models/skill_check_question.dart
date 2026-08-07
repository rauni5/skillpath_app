class SkillCheckQuestion {
  final int index;
  final String question;
  final List<String> options;

  SkillCheckQuestion({
    required this.index,
    required this.question,
    required this.options,
  });

  factory SkillCheckQuestion.fromJson(Map<String, dynamic> json) {
    return SkillCheckQuestion(
      index: json['index'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Response from POST .../skill-check/generate. Deliberately has no
/// answer-key field — the backend never sends one.
class SkillCheckGenerateResult {
  final int attemptId;
  final List<SkillCheckQuestion> questions;

  SkillCheckGenerateResult({required this.attemptId, required this.questions});

  factory SkillCheckGenerateResult.fromJson(Map<String, dynamic> json) {
    return SkillCheckGenerateResult(
      attemptId: json['attemptId'] as int,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => SkillCheckQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
