import 'project.dart';
import 'skill.dart';
import 'user.dart';

class SkillWithProficiency {
  final int id;
  final String name;
  final SkillCategory category;
  final SkillProficiency proficiency;

  SkillWithProficiency({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiency,
  });

  factory SkillWithProficiency.fromJson(Map<String, dynamic> json) {
    return SkillWithProficiency(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: skillCategoryFromString(json['category'] as String?),
      proficiency: skillProficiencyFromString(json['proficiency'] as String?),
    );
  }
}

class PortfolioItem {
  final int id;
  final int? projectId;
  final String? projectName;
  final String? githubUrl;
  final String? description;
  final String? userRole;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    this.projectId,
    this.projectName,
    this.githubUrl,
    this.description,
    this.userRole,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] as int,
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String?,
      githubUrl: json['githubUrl'] as String?,
      description: json['description'] as String?,
      userRole: json['userRole'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}

class Certification {
  final int id;
  final String name;
  final String? issuer;
  final String? credentialUrl;
  final DateTime? earnedOn;

  Certification({
    required this.id,
    required this.name,
    this.issuer,
    this.credentialUrl,
    this.earnedOn,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String?,
      credentialUrl: json['credentialUrl'] as String?,
      earnedOn: json['earnedOn'] == null
          ? null
          : DateTime.tryParse(json['earnedOn'] as String),
    );
  }
}

class PortfolioData {
  final int userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? location;
  final List<String> softSkills;
  final String? bio;
  final String? avatarUrl;
  final ExperienceLevel experienceLevel;
  final bool availability;
  final DateTime? memberSince;

  final String? careerGoalRoleName;
  final int careerProgressPercent;

  final List<SkillWithProficiency> skills;
  final List<Project> projects;
  final List<PortfolioItem> portfolioItems;
  final List<Certification> certifications;

  PortfolioData({
    required this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.githubUrl,
    this.linkedinUrl,
    this.location,
    this.softSkills = const [],
    this.bio,
    this.avatarUrl,
    required this.experienceLevel,
    required this.availability,
    this.memberSince,
    this.careerGoalRoleName,
    required this.careerProgressPercent,
    required this.skills,
    required this.projects,
    required this.portfolioItems,
    this.certifications = const [],
  });

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

  factory PortfolioData.fromJson(Map<String, dynamic> json) {
    return PortfolioData(
      userId: json['userId'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      githubUrl: json['githubUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      location: json['location'] as String?,
      softSkills: (json['softSkills'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      experienceLevel: experienceLevelFromString(
        json['experienceLevel'] as String?,
      ),
      availability: json['availability'] as bool? ?? true,
      memberSince: json['memberSince'] == null
          ? null
          : DateTime.tryParse(json['memberSince'] as String),
      careerGoalRoleName: json['careerGoalRoleName'] as String?,
      careerProgressPercent: json['careerProgressPercent'] as int? ?? 0,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => SkillWithProficiency.fromJson(e as Map<String, dynamic>))
          .toList(),
      projects: (json['projects'] as List<dynamic>? ?? [])
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList(),
      portfolioItems: (json['portfolioItems'] as List<dynamic>? ?? [])
          .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      certifications: (json['certifications'] as List<dynamic>? ?? [])
          .map((e) => Certification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Turns a profile URL into just the handle/username for display -
/// "https://github.com/rauni5" -> "rauni5", "https://linkedin.com/in/rauni5/"
/// -> "rauni5". Falls back to the cleaned-up URL if nothing better can be
/// pulled out (e.g. an unexpected shape), and returns null for blank input.
String? extractProfileUsername(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final cleaned = url.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(cleaned);
  final segments = uri?.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments != null && segments.isNotEmpty) {
    // linkedin.com/in/<username> - skip the "in" path segment.
    if (segments.length >= 2 && segments.first.toLowerCase() == 'in') {
      return segments[1];
    }
    return segments.last;
  }
  return cleaned.replaceFirst(RegExp(r'^https?://'), '');
}
