class CareerRole {
  final int id;
  final String name;
  final String? description;

  CareerRole({required this.id, required this.name, this.description});

  factory CareerRole.fromJson(Map<String, dynamic> json) {
    return CareerRole(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
