class DashboardSummary {
  final String content;
  final DateTime generatedAt;

  DashboardSummary({required this.content, required this.generatedAt});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      content: json['content'] as String? ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}