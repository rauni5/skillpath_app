enum DiscussionChannel { public, team }

DiscussionChannel discussionChannelFromString(String? value) {
  return value == 'TEAM' ? DiscussionChannel.team : DiscussionChannel.public;
}

String discussionChannelToApiString(DiscussionChannel channel) {
  return channel == DiscussionChannel.team ? 'TEAM' : 'PUBLIC';
}

enum PostTag { general, question, update, announcement }

PostTag postTagFromString(String? value) {
  switch (value) {
    case 'QUESTION':
      return PostTag.question;
    case 'UPDATE':
      return PostTag.update;
    case 'ANNOUNCEMENT':
      return PostTag.announcement;
    case 'GENERAL':
    default:
      return PostTag.general;
  }
}

String postTagToApiString(PostTag tag) {
  switch (tag) {
    case PostTag.question:
      return 'QUESTION';
    case PostTag.update:
      return 'UPDATE';
    case PostTag.announcement:
      return 'ANNOUNCEMENT';
    case PostTag.general:
      return 'GENERAL';
  }
}

extension PostTagLabel on PostTag {
  String get label {
    switch (this) {
      case PostTag.question:
        return 'Question';
      case PostTag.update:
        return 'Update';
      case PostTag.announcement:
        return 'Announcement';
      case PostTag.general:
        return 'General';
    }
  }
}

class DiscussionPost {
  final int id;
  final int projectId;
  final DiscussionChannel channel;
  final PostTag tag;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String body;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool canEdit;
  final bool canDelete;

  DiscussionPost({
    required this.id,
    required this.projectId,
    required this.channel,
    required this.tag,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    required this.body,
    required this.likeCount,
    required this.likedByMe,
    required this.commentCount,
    required this.createdAt,
    this.updatedAt,
    required this.canEdit,
    required this.canDelete,
  });

  factory DiscussionPost.fromJson(Map<String, dynamic> json) {
    return DiscussionPost(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      channel: discussionChannelFromString(json['channel'] as String?),
      tag: postTagFromString(json['tag'] as String?),
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      commentCount: json['commentCount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }

  DiscussionPost copyWith({
    int? likeCount,
    bool? likedByMe,
    int? commentCount,
  }) {
    return DiscussionPost(
      id: id,
      projectId: projectId,
      channel: channel,
      tag: tag,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      title: title,
      body: body,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      canEdit: canEdit,
      canDelete: canDelete,
    );
  }
}

class DiscussionComment {
  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final int likeCount;
  final bool likedByMe;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool canEdit;
  final bool canDelete;

  DiscussionComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    required this.likeCount,
    required this.likedByMe,
    required this.createdAt,
    this.updatedAt,
    required this.canEdit,
    required this.canDelete,
  });

  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id'] as int,
      postId: json['postId'] as int,
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      body: json['body'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }

  DiscussionComment copyWith({int? likeCount, bool? likedByMe}) {
    return DiscussionComment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAt: createdAt,
      updatedAt: updatedAt,
      canEdit: canEdit,
      canDelete: canDelete,
    );
  }
}
