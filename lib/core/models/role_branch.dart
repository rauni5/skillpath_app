class RoleBranch {
  final int id;
  final int roleId;
  final String name;
  final String? description;

  RoleBranch({
    required this.id,
    required this.roleId,
    required this.name,
    this.description,
  });

  factory RoleBranch.fromJson(Map<String, dynamic> json) {
    return RoleBranch(
      id: json['id'] as int,
      roleId: json['roleId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
