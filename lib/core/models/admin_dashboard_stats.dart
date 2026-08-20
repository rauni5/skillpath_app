import 'daily_count.dart';
import 'recent_user.dart';
import 'skill_popularity.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int newUsersLast7Days;
  final int newUsersLast30Days;
  final int totalProjects;
  final int openProjects;
  final int completedProjects;
  final int totalSkills;
  final int totalCareerRoles;
  final int totalAchievements;
  final int achievementsUnlockedCount;
  final double avgSkillsPerUser;
  final List<SkillPopularity> topSkills;
  final List<DailyCount> userSignupTrend;
  final List<RecentUser> recentSignups;

  AdminDashboardStats({
    required this.totalUsers,
    required this.newUsersLast7Days,
    required this.newUsersLast30Days,
    required this.totalProjects,
    required this.openProjects,
    required this.completedProjects,
    required this.totalSkills,
    required this.totalCareerRoles,
    required this.totalAchievements,
    required this.achievementsUnlockedCount,
    required this.avgSkillsPerUser,
    required this.topSkills,
    required this.userSignupTrend,
    required this.recentSignups,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      newUsersLast7Days: json['newUsersLast7Days'] as int? ?? 0,
      newUsersLast30Days: json['newUsersLast30Days'] as int? ?? 0,
      totalProjects: json['totalProjects'] as int? ?? 0,
      openProjects: json['openProjects'] as int? ?? 0,
      completedProjects: json['completedProjects'] as int? ?? 0,
      totalSkills: json['totalSkills'] as int? ?? 0,
      totalCareerRoles: json['totalCareerRoles'] as int? ?? 0,
      totalAchievements: json['totalAchievements'] as int? ?? 0,
      achievementsUnlockedCount: json['achievementsUnlockedCount'] as int? ?? 0,
      avgSkillsPerUser: (json['avgSkillsPerUser'] as num?)?.toDouble() ?? 0,
      topSkills: (json['topSkills'] as List<dynamic>? ?? [])
          .map((e) => SkillPopularity.fromJson(e as Map<String, dynamic>))
          .toList(),
      userSignupTrend: (json['userSignupTrend'] as List<dynamic>? ?? [])
          .map((e) => DailyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSignups: (json['recentSignups'] as List<dynamic>? ?? [])
          .map((e) => RecentUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AdminDashboardStats copyWith({List<DailyCount>? userSignupTrend}) {
    return AdminDashboardStats(
      totalUsers: totalUsers,
      newUsersLast7Days: newUsersLast7Days,
      newUsersLast30Days: newUsersLast30Days,
      totalProjects: totalProjects,
      openProjects: openProjects,
      completedProjects: completedProjects,
      totalSkills: totalSkills,
      totalCareerRoles: totalCareerRoles,
      totalAchievements: totalAchievements,
      achievementsUnlockedCount: achievementsUnlockedCount,
      avgSkillsPerUser: avgSkillsPerUser,
      topSkills: topSkills,
      userSignupTrend: userSignupTrend ?? this.userSignupTrend,
      recentSignups: recentSignups,
    );
  }
}
