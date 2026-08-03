import 'career_role.dart';
import 'project_member.dart';
import 'skill.dart';

enum ProjectStatus { open, full, completed, cancelled, unknown }

ProjectStatus projectStatusFromString(String? value) {
  switch (value) {
    case 'OPEN':
      return ProjectStatus.open;
    case 'FULL':
      return ProjectStatus.full;
    case 'COMPLETED':
      return ProjectStatus.completed;
    case 'CANCELLED':
      return ProjectStatus.cancelled;
    default:
      return ProjectStatus.unknown;
  }
}

class Project {
  final int id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? link;
  final int teamSize;
  final ProjectStatus status;
  final int ownerId;
  final List<Skill> requiredSkills;
  final List<CareerRole> requiredRoles;
  final DateTime? createdAt;

  /// The current viewer's own membership status on this project — null if
  /// they've never requested to join or been invited.
  final MemberStatus? viewerMembershipStatus;

  /// True if the pending status above is an owner-sent invite rather than
  /// a join request the viewer sent themselves.
  final bool viewerInvitedByOwner;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.link,
    required this.teamSize,
    required this.status,
    required this.ownerId,
    required this.requiredSkills,
    this.requiredRoles = const [],
    this.createdAt,
    this.viewerMembershipStatus,
    this.viewerInvitedByOwner = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      link: json['link'] as String?,
      teamSize: json['teamSize'] as int? ?? 0,
      status: projectStatusFromString(json['status'] as String?),
      ownerId: json['ownerId'] as int? ?? 0,
      requiredSkills: (json['requiredSkills'] as List<dynamic>? ?? [])
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiredRoles: (json['requiredRoles'] as List<dynamic>? ?? [])
          .map((e) => CareerRole.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      viewerMembershipStatus: json['viewerMembershipStatus'] == null
          ? null
          : memberStatusFromString(json['viewerMembershipStatus'] as String?),
      viewerInvitedByOwner: json['viewerInvitedByOwner'] as bool? ?? false,
    );
  }
}
