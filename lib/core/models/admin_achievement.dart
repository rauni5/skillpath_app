enum AchievementCriteriaType {
  roadmapStepsCompleted,
  roadmapPercentComplete,
  skillChecksPassed,
  streakDays,
  projectsJoined,
  projectsCreated,
  tutorMessagesSent,
}

AchievementCriteriaType achievementCriteriaTypeFromString(String? value) {
  switch (value) {
    case 'ROADMAP_PERCENT_COMPLETE':
      return AchievementCriteriaType.roadmapPercentComplete;
    case 'SKILL_CHECKS_PASSED':
      return AchievementCriteriaType.skillChecksPassed;
    case 'STREAK_DAYS':
      return AchievementCriteriaType.streakDays;
    case 'PROJECTS_JOINED':
      return AchievementCriteriaType.projectsJoined;
    case 'PROJECTS_CREATED':
      return AchievementCriteriaType.projectsCreated;
    case 'TUTOR_MESSAGES_SENT':
      return AchievementCriteriaType.tutorMessagesSent;
    case 'ROADMAP_STEPS_COMPLETED':
    default:
      return AchievementCriteriaType.roadmapStepsCompleted;
  }
}

String achievementCriteriaTypeToApiString(AchievementCriteriaType type) {
  switch (type) {
    case AchievementCriteriaType.roadmapStepsCompleted:
      return 'ROADMAP_STEPS_COMPLETED';
    case AchievementCriteriaType.roadmapPercentComplete:
      return 'ROADMAP_PERCENT_COMPLETE';
    case AchievementCriteriaType.skillChecksPassed:
      return 'SKILL_CHECKS_PASSED';
    case AchievementCriteriaType.streakDays:
      return 'STREAK_DAYS';
    case AchievementCriteriaType.projectsJoined:
      return 'PROJECTS_JOINED';
    case AchievementCriteriaType.projectsCreated:
      return 'PROJECTS_CREATED';
    case AchievementCriteriaType.tutorMessagesSent:
      return 'TUTOR_MESSAGES_SENT';
  }
}

extension AchievementCriteriaTypeLabel on AchievementCriteriaType {
  String get label {
    switch (this) {
      case AchievementCriteriaType.roadmapStepsCompleted:
        return 'Roadmap steps completed';
      case AchievementCriteriaType.roadmapPercentComplete:
        return 'Roadmap percent complete';
      case AchievementCriteriaType.skillChecksPassed:
        return 'Skill checks passed';
      case AchievementCriteriaType.streakDays:
        return 'Activity streak (days)';
      case AchievementCriteriaType.projectsJoined:
        return 'Projects joined';
      case AchievementCriteriaType.projectsCreated:
        return 'Projects created';
      case AchievementCriteriaType.tutorMessagesSent:
        return 'Tutor chat messages sent';
    }
  }

  /// Short phrase used to build a live "unlocks when …" preview in the form.
  String unlockHint(int value) {
    switch (this) {
      case AchievementCriteriaType.roadmapStepsCompleted:
        return 'Unlocks after completing $value roadmap step${value == 1 ? '' : 's'}.';
      case AchievementCriteriaType.roadmapPercentComplete:
        return 'Unlocks at $value% roadmap completion.';
      case AchievementCriteriaType.skillChecksPassed:
        return 'Unlocks after passing $value skill check${value == 1 ? '' : 's'}.';
      case AchievementCriteriaType.streakDays:
        return 'Unlocks at a $value-day activity streak.';
      case AchievementCriteriaType.projectsJoined:
        return 'Unlocks after joining $value project${value == 1 ? '' : 's'}.';
      case AchievementCriteriaType.projectsCreated:
        return 'Unlocks after creating $value project${value == 1 ? '' : 's'}.';
      case AchievementCriteriaType.tutorMessagesSent:
        return 'Unlocks after sending $value tutor chat message${value == 1 ? '' : 's'}.';
    }
  }
}

/// Fixed set of icon names the achievements catalog supports — kept in
/// sync with the mapping in `core/models/achievement.dart`.
const List<String> achievementIconOptions = [
  'flag',
  'trending_up',
  'rocket_launch',
  'timelapse',
  'emoji_events',
  'quiz',
  'workspace_premium',
  'local_fire_department',
  'whatshot',
  'bolt',
  'groups',
  'campaign',
  'forum',
  'star',
  'celebration',
];

class AdminAchievement {
  final int id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final String category;
  final AchievementCriteriaType criteriaType;
  final int criteriaValue;
  final bool enabled;
  final int unlockedByCount;

  AdminAchievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.criteriaType,
    required this.criteriaValue,
    required this.enabled,
    required this.unlockedByCount,
  });

  factory AdminAchievement.fromJson(Map<String, dynamic> json) {
    return AdminAchievement(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      category: json['category'] as String? ?? '',
      criteriaType: achievementCriteriaTypeFromString(
        json['criteriaType'] as String?,
      ),
      criteriaValue: json['criteriaValue'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? true,
      unlockedByCount: json['unlockedByCount'] as int? ?? 0,
    );
  }
}

/// Result of a delete attempt — either it was actually removed, or (if
/// someone had already earned it) disabled instead so their badge stays.
class AchievementDeletionResult {
  final bool deleted;
  final String message;
  final AdminAchievement? achievement;

  AchievementDeletionResult({
    required this.deleted,
    required this.message,
    this.achievement,
  });

  factory AchievementDeletionResult.fromJson(Map<String, dynamic> json) {
    final achievementJson = json['achievement'] as Map<String, dynamic>?;
    return AchievementDeletionResult(
      deleted: json['deleted'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      achievement: achievementJson == null
          ? null
          : AdminAchievement.fromJson(achievementJson),
    );
  }
}
