class RecommendedMember {
  final int userId;
  final String name;
  final String? avatarUrl;
  final double matchScore;

  RecommendedMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.matchScore,
  });

  factory RecommendedMember.fromJson(Map<String, dynamic> json) {
    return RecommendedMember(
      userId: json['userId'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
