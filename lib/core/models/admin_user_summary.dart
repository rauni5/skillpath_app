import '../../../core/models/user.dart';

/// A user row for the admin Users screen, enriched with per-user stats.
class AdminUserSummary {
  final AppUser user;
  final int skillsCount;
  final int ownedProjectsCount;
  final int achievementsCount;
  final bool careerGoalSet;

  AdminUserSummary({
    required this.user,
    required this.skillsCount,
    required this.ownedProjectsCount,
    required this.achievementsCount,
    required this.careerGoalSet,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      skillsCount: json['skillsCount'] as int? ?? 0,
      ownedProjectsCount: json['ownedProjectsCount'] as int? ?? 0,
      achievementsCount: json['achievementsCount'] as int? ?? 0,
      careerGoalSet: json['careerGoalSet'] as bool? ?? false,
    );
  }

  AdminUserSummary copyWith({AppUser? user}) {
    return AdminUserSummary(
      user: user ?? this.user,
      skillsCount: skillsCount,
      ownedProjectsCount: ownedProjectsCount,
      achievementsCount: achievementsCount,
      careerGoalSet: careerGoalSet,
    );
  }
}
