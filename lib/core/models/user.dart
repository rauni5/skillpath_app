enum ExperienceLevel { beginner, intermediate, advanced }

ExperienceLevel experienceLevelFromString(String? value) {
  switch (value) {
    case 'INTERMEDIATE':
      return ExperienceLevel.intermediate;
    case 'ADVANCED':
      return ExperienceLevel.advanced;
    case 'BEGINNER':
    default:
      return ExperienceLevel.beginner;
  }
}

String experienceLevelToApiString(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return 'BEGINNER';
    case ExperienceLevel.intermediate:
      return 'INTERMEDIATE';
    case ExperienceLevel.advanced:
      return 'ADVANCED';
  }
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? location;
  final String? softSkills;
  final String? bio;
  final ExperienceLevel experienceLevel;
  final bool availability;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isAdmin;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.githubUrl,
    this.linkedinUrl,
    this.location,
    this.softSkills,
    this.bio,
    required this.experienceLevel,
    required this.availability,
    this.avatarUrl,
    this.createdAt,
    required this.isAdmin,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      githubUrl: json['githubUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      location: json['location'] as String?,
      softSkills: json['softSkills'] as String?,
      bio: json['bio'] as String?,
      experienceLevel: experienceLevelFromString(
        json['experienceLevel'] as String?,
      ),
      availability: json['availability'] as bool? ?? true,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      isAdmin: json['admin'] as bool? ?? false,
    );
  }
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
