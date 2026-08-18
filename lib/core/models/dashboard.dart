import 'project.dart';
import 'skill.dart';

class DashboardData {
  final int careerProgressPercent;
  final int knownSkillCount;
  final int requiredSkillCount;
  final int roadmapCompletedSteps;
  final int roadmapTotalSteps;
  final String? careerRoleName;
  final List<Project> activeProjects;
  final List<Skill> nextSkillsToLearn;

  DashboardData({
    required this.careerProgressPercent,
    required this.knownSkillCount,
    required this.requiredSkillCount,
    required this.roadmapCompletedSteps,
    required this.roadmapTotalSteps,
    this.careerRoleName,
    required this.activeProjects,
    required this.nextSkillsToLearn,
  });

  double get roadmapProgress =>
      roadmapTotalSteps == 0 ? 0 : roadmapCompletedSteps / roadmapTotalSteps;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      careerProgressPercent: json['careerProgressPercent'] as int? ?? 0,
      knownSkillCount: json['knownSkillCount'] as int? ?? 0,
      requiredSkillCount: json['requiredSkillCount'] as int? ?? 0,
      roadmapCompletedSteps: json['roadmapCompletedSteps'] as int? ?? 0,
      roadmapTotalSteps: json['roadmapTotalSteps'] as int? ?? 0,
      careerRoleName: json['careerRoleName'] as String?,
      activeProjects: (json['activeProjects'] as List<dynamic>? ?? [])
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextSkillsToLearn: (json['nextSkillsToLearn'] as List<dynamic>? ?? [])
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
