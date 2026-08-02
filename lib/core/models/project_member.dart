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
    );
  }
}
