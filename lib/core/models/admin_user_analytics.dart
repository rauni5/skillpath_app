import 'daily_count.dart';

class AdminUserAnalytics {
  final int totalUsers;
  final int adminCount;
  final int availableCount;
  final int unavailableCount;
  final int usersWithCareerGoalSet;
  final double avgSkillsPerUser;
  final int newUsersLast7Days;
  final int newUsersLast30Days;
  final Map<String, int> byExperienceLevel;
  final List<DailyCount> signupTrend;

  AdminUserAnalytics({
    required this.totalUsers,
    required this.adminCount,
    required this.availableCount,
    required this.unavailableCount,
    required this.usersWithCareerGoalSet,
    required this.avgSkillsPerUser,
    required this.newUsersLast7Days,
    required this.newUsersLast30Days,
    required this.byExperienceLevel,
    required this.signupTrend,
  });

  factory AdminUserAnalytics.fromJson(Map<String, dynamic> json) {
    final byExperienceRaw =
        json['byExperienceLevel'] as Map<String, dynamic>? ?? {};
    return AdminUserAnalytics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      adminCount: json['adminCount'] as int? ?? 0,
      availableCount: json['availableCount'] as int? ?? 0,
      unavailableCount: json['unavailableCount'] as int? ?? 0,
      usersWithCareerGoalSet: json['usersWithCareerGoalSet'] as int? ?? 0,
      avgSkillsPerUser: (json['avgSkillsPerUser'] as num?)?.toDouble() ?? 0,
      newUsersLast7Days: json['newUsersLast7Days'] as int? ?? 0,
      newUsersLast30Days: json['newUsersLast30Days'] as int? ?? 0,
      byExperienceLevel: byExperienceRaw.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      signupTrend: (json['signupTrend'] as List<dynamic>? ?? [])
          .map((e) => DailyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
