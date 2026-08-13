class BranchRecommendation {
  final int branchId;
  final String name;
  final String? description;
  final double matchScore; // 0-100

  BranchRecommendation({
    required this.branchId,
    required this.name,
    this.description,
    required this.matchScore,
  });

  factory BranchRecommendation.fromJson(Map<String, dynamic> json) {
    return BranchRecommendation(
      branchId: json['branchId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
