import 'skill.dart';

enum MemberStatus { pending, accepted, rejected, unknown }

MemberStatus memberStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'PENDING':
      return MemberStatus.pending;
    case 'ACCEPTED':
      return MemberStatus.accepted;
    case 'REJECTED':
      return MemberStatus.rejected;
    default:
      return MemberStatus.unknown;
  }
}

class ProjectMember {
  final int userId;
  final String name;
  final String? email;
  final String? avatarUrl;
  final MemberStatus status;
  final String? role;
  final bool invitedByOwner;

  ProjectMember({
    required this.userId,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.status,
    this.role,
    this.invitedByOwner = false,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['userId'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: memberStatusFromString(json['status'] as String?),
      role: json['role'] as String?,
      invitedByOwner: json['invitedByOwner'] as bool? ?? false,
    );
  }
}

class ProjectInvite {
  final int projectId;
  final String projectName;
  final String? description;
  final String? difficulty;
  final int? teamSize;
  final int? memberCount;
  final int? ownerId;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final List<Skill> requiredSkills;
  final DateTime? invitedAt;

  ProjectInvite({
    required this.projectId,
    required this.projectName,
    this.description,
    this.difficulty,
    this.teamSize,
    this.memberCount,
    this.ownerId,
    this.ownerName,
    this.ownerAvatarUrl,
    this.requiredSkills = const [],
    this.invitedAt,
  });

  String get ownerInitials {
    final name = ownerName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory ProjectInvite.fromJson(Map<String, dynamic> json) {
    return ProjectInvite(
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String? ?? '',
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      teamSize: json['teamSize'] as int?,
      memberCount: json['memberCount'] as int?,
      ownerId: json['ownerId'] as int?,
      ownerName: json['ownerName'] as String?,
      ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
      requiredSkills: (json['requiredSkills'] as List<dynamic>? ?? [])
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      invitedAt: json['invitedAt'] == null
          ? null
          : DateTime.tryParse(json['invitedAt'] as String),
    );
  }
}

class ProjectJoinRequest {
  final int projectId;
  final String projectName;
  final int requesterId;
  final String requesterName;
  final String? requesterAvatarUrl;
  final List<Skill> requesterSkills;

  ProjectJoinRequest({
    required this.projectId,
    required this.projectName,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    this.requesterSkills = const [],
  });

  String get requesterInitials {
    final name = requesterName.trim();
    if (name.isEmpty) return '?';
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory ProjectJoinRequest.fromJson(Map<String, dynamic> json) {
    return ProjectJoinRequest(
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String? ?? '',
      requesterId: json['requesterId'] as int,
      requesterName: json['requesterName'] as String? ?? '',
      requesterAvatarUrl: json['requesterAvatarUrl'] as String?,
      requesterSkills: (json['requesterSkills'] as List<dynamic>? ?? [])
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MembershipStatusEntry {
  final int projectId;
  final String projectName;
  final MemberStatus status;

  MembershipStatusEntry({
    required this.projectId,
    required this.projectName,
    required this.status,
  });

  factory MembershipStatusEntry.fromJson(Map<String, dynamic> json) {
    return MembershipStatusEntry(
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String? ?? '',
      status: memberStatusFromString(json['status'] as String?),
    );
  }
}
