class AdminRoleSummary {
  final int id;
  final String name;
  final String? description;
  final int branchCount;
  final int requirementsCount;
  final int popularity;

  AdminRoleSummary({
    required this.id,
    required this.name,
    this.description,
    this.branchCount = 0,
    this.requirementsCount = 0,
    this.popularity = 0,
  });

  factory AdminRoleSummary.fromJson(Map<String, dynamic> json) {
    return AdminRoleSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      branchCount: json['branchCount'] as int? ?? 0,
      requirementsCount: json['requirementsCount'] as int? ?? 0,
      popularity: json['popularity'] as int? ?? 0,
    );
  }
}
