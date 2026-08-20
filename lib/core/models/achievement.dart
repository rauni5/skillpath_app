import 'package:flutter/material.dart' show IconData, Icons;

import 'admin_achievement.dart';
export 'admin_achievement.dart'
    show AchievementCriteriaType, AchievementCriteriaTypeLabel;
class AchievementDestination {
  final String route;
  final String label;
  const AchievementDestination(this.route, this.label);
}

AchievementDestination? achievementDestinationFor(
  AchievementCriteriaType type,
) {
  switch (type) {
    case AchievementCriteriaType.roadmapStepsCompleted:
    case AchievementCriteriaType.roadmapPercentComplete:
    case AchievementCriteriaType.skillChecksPassed:
    case AchievementCriteriaType.streakDays:
      return const AchievementDestination('/roadmap', 'View Roadmap');
    case AchievementCriteriaType.projectsJoined:
    case AchievementCriteriaType.projectsCreated:
      return const AchievementDestination('/projects', 'View Projects');
    case AchievementCriteriaType.tutorMessagesSent:
      return const AchievementDestination('/roadmap', 'Open a Tutor Chat');
  }
}

class Achievement {
  final String code;
  final String title;
  final String description;
  final String icon;
  final String category;
  final bool unlocked;
  final DateTime? unlockedAt;
  final AchievementCriteriaType criteriaType;
  final int criteriaValue;

  Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.unlocked,
    this.unlockedAt,
    required this.criteriaType,
    required this.criteriaValue,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlockedAtRaw = json['unlockedAt'] as String?;
    return Achievement(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      category: json['category'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: unlockedAtRaw == null
          ? null
          : DateTime.tryParse(unlockedAtRaw),
      criteriaType: achievementCriteriaTypeFromString(
        json['criteriaType'] as String?,
      ),
      criteriaValue: json['criteriaValue'] as int? ?? 1,
    );
  }

  /// Where this achievement's "Go to" button should point, if anywhere.
  AchievementDestination? get destination =>
      achievementDestinationFor(criteriaType);

  /// Maps the backend's icon name (from the achievements catalog) to a
  /// concrete Material icon. Falls back to a trophy if unrecognized. Shared
  /// with the admin achievement picker so both stay in sync.
  IconData get iconData => iconForName(icon);

  static IconData iconForName(String icon) {
    switch (icon) {
      case 'flag':
        return Icons.flag_outlined;
      case 'trending_up':
        return Icons.trending_up;
      case 'rocket_launch':
        return Icons.rocket_launch_outlined;
      case 'timelapse':
        return Icons.timelapse;
      case 'emoji_events':
        return Icons.emoji_events_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'workspace_premium':
        return Icons.workspace_premium_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
      case 'whatshot':
        return Icons.whatshot;
      case 'bolt':
        return Icons.bolt;
      case 'groups':
        return Icons.groups_outlined;
      case 'campaign':
        return Icons.campaign_outlined;
      case 'forum':
        return Icons.forum_outlined;
      case 'star':
        return Icons.star_outline;
      case 'celebration':
        return Icons.celebration_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}
