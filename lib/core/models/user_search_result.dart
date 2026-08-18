import 'user.dart' show ExperienceLevel, experienceLevelFromString;

class UserSearchResult {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final ExperienceLevel? experienceLevel;
  final bool availability;

  UserSearchResult({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.experienceLevel,
    required this.availability,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      experienceLevel: json['experienceLevel'] == null
          ? null
          : experienceLevelFromString(json['experienceLevel'] as String?),
      availability: json['availability'] as bool? ?? false,
    );
  }
}
