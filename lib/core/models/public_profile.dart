import 'achievement.dart';
import 'portfolio.dart';
import 'project.dart';
import 'user.dart';

/// A deliberately smaller shape than [PortfolioData] — mirrors the
/// backend's `PublicProfileResponse`, which never includes email, phone
/// number, or location (see that class's doc comment). Reuses the same
/// nested model classes as [PortfolioData] since the JSON shapes for
/// skills/achievements/projects/portfolio items/certifications/education
/// are identical either way — that's also what lets [toPortfolioData]
/// hand this straight to the same `PortfolioBody` widget the authenticated
/// portfolio screen uses, so both screens share one real layout instead of
/// two hand-maintained copies of it.
class PublicProfileData {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final List<String> softSkills;
  final ExperienceLevel experienceLevel;
  final bool availability;
  final String? githubUrl;
  final String? linkedinUrl;
  final DateTime? memberSince;

  final String? careerGoalRoleName;
  final int careerProgressPercent;

  final List<SkillWithProficiency> skills;
  final List<Achievement> achievements;
  final List<Project> projects;
  final List<PortfolioItem> portfolioItems;
  final List<Certification> certifications;
  final List<Education> education;

  PublicProfileData({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.softSkills = const [],
    required this.experienceLevel,
    required this.availability,
    this.githubUrl,
    this.linkedinUrl,
    this.memberSince,
    this.careerGoalRoleName,
    required this.careerProgressPercent,
    required this.skills,
    required this.achievements,
    this.projects = const [],
    required this.portfolioItems,
    this.certifications = const [],
    this.education = const [],
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

  /// Maps this into a [PortfolioData]-shaped object with the fields this
  /// screen never had (email, phone, location) left empty/null, so it can
  /// be rendered by the exact same `PortfolioBody` widget the authenticated
  /// portfolio screen uses.
  PortfolioData toPortfolioData() {
    return PortfolioData(
      userId: userId,
      name: name,
      email: '',
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      softSkills: softSkills,
      bio: bio,
      avatarUrl: avatarUrl,
      experienceLevel: experienceLevel,
      availability: availability,
      memberSince: memberSince,
      careerGoalRoleName: careerGoalRoleName,
      careerProgressPercent: careerProgressPercent,
      skills: skills,
      projects: projects,
      portfolioItems: portfolioItems,
      certifications: certifications,
      education: education,
    );
  }

  factory PublicProfileData.fromJson(Map<String, dynamic> json) {
    return PublicProfileData(
      userId: json['userId'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      softSkills: (json['softSkills'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      experienceLevel: experienceLevelFromString(
        json['experienceLevel'] as String?,
      ),
      availability: json['availability'] as bool? ?? true,
      githubUrl: json['githubUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      memberSince: json['memberSince'] == null
          ? null
          : DateTime.tryParse(json['memberSince'] as String),
      careerGoalRoleName: json['careerGoalRoleName'] as String?,
      careerProgressPercent: json['careerProgressPercent'] as int? ?? 0,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => SkillWithProficiency.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
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
      education: (json['education'] as List<dynamic>? ?? [])
          .map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The share-settings shape returned by the authenticated
/// enable/disable/regenerate/get endpoints. `link` is derived client-side
/// from [token] rather than sent by the backend, since the backend
/// shouldn't need to know its own public base URL.
class PublicProfileSettings {
  final bool enabled;
  final String? token;

  PublicProfileSettings({required this.enabled, this.token});

  factory PublicProfileSettings.fromJson(Map<String, dynamic> json) {
    return PublicProfileSettings(
      enabled: json['enabled'] as bool? ?? false,
      token: json['token'] as String?,
    );
  }
}
