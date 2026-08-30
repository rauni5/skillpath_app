class AdminRoleSummary {
  final int id;
  final String name;
  final String? description;
  final int requirementsCount;
  final int popularity;

  AdminRoleSummary({
    required this.id,
    required this.name,
    this.description,
    required this.requirementsCount,
    required this.popularity,
  });

  factory AdminRoleSummary.fromJson(Map<String, dynamic> json) {
    return AdminRoleSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      requirementsCount: json['requirementsCount'] as int? ?? 0,
      popularity: json['popularity'] as int? ?? 0,
    );
  }
}
