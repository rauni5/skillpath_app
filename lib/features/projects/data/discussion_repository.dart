import '../../../core/models/discussion_post.dart';
import '../../../core/models/page_projects.dart';
import '../../../core/network/api_client.dart';

/// Reddit-style discussion boards for a project: PUBLIC (any authenticated
/// user) and TEAM (owner + accepted members only) — enforced server-side.
class DiscussionRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/projects/{projectId}/discussion/posts?channel=...
  Future<Page<DiscussionPost>> listPosts(
    int projectId,
    DiscussionChannel channel, {
    int page = 0,
    int size = 20,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/projects/$projectId/discussion/posts',
        queryParameters: {
          'channel': discussionChannelToApiString(channel),
          'page': page,
          'size': size,
        },
      ),
      (data) => Page<DiscussionPost>.fromJson(
        data as Map<String, dynamic>,
        DiscussionPost.fromJson,
      ),
    );
  }

  /// POST /api/v1/projects/{projectId}/discussion/posts
  Future<DiscussionPost> createPost(
    int projectId, {
    required DiscussionChannel channel,
    required PostTag tag,
    required String title,
    required String body,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/projects/$projectId/discussion/posts',
        data: {
          'channel': discussionChannelToApiString(channel),
          'tag': postTagToApiString(tag),
          'title': title,
          'body': body,
        },
      ),
      (data) => DiscussionPost.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/projects/{projectId}/discussion/posts/{postId}
  Future<DiscussionPost> getPost(int projectId, int postId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$projectId/discussion/posts/$postId'),
      (data) => DiscussionPost.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/projects/{projectId}/discussion/posts/{postId}
  Future<DiscussionPost> updatePost(
    int projectId,
    int postId, {
    required PostTag tag,
    required String title,
    required String body,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/projects/$projectId/discussion/posts/$postId',
        data: {'tag': postTagToApiString(tag), 'title': title, 'body': body},
      ),
      (data) => DiscussionPost.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/projects/{projectId}/discussion/posts/{postId}
  Future<void> deletePost(int projectId, int postId) {
    return _api.unwrap(
      (dio) =>
          dio.delete('/api/v1/projects/$projectId/discussion/posts/$postId'),
      (_) {},
    );
  }

  /// POST /api/v1/projects/{projectId}/discussion/posts/{postId}/like
  Future<({bool liked, int likeCount})> togglePostLike(
    int projectId,
    int postId,
  ) {
    return _api.unwrap(
      (dio) =>
          dio.post('/api/v1/projects/$projectId/discussion/posts/$postId/like'),
      (data) {
        final map = data as Map<String, dynamic>;
        return (
          liked: map['liked'] as bool? ?? false,
          likeCount: map['likeCount'] as int? ?? 0,
        );
      },
    );
  }

  /// GET /api/v1/projects/{projectId}/discussion/posts/{postId}/comments
  Future<Page<DiscussionComment>> listComments(
    int projectId,
    int postId, {
    int page = 0,
    int size = 50,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/projects/$projectId/discussion/posts/$postId/comments',
        queryParameters: {'page': page, 'size': size},
      ),
      (data) => Page<DiscussionComment>.fromJson(
        data as Map<String, dynamic>,
        DiscussionComment.fromJson,
      ),
    );
  }

  /// POST /api/v1/projects/{projectId}/discussion/posts/{postId}/comments
  Future<DiscussionComment> addComment(int projectId, int postId, String body) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/projects/$projectId/discussion/posts/$postId/comments',
        data: {'body': body},
      ),
      (data) => DiscussionComment.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT .../comments/{commentId}
  Future<DiscussionComment> updateComment(
    int projectId,
    int postId,
    int commentId,
    String body,
  ) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/projects/$projectId/discussion/posts/$postId/comments/$commentId',
        data: {'body': body},
      ),
      (data) => DiscussionComment.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE .../comments/{commentId}
  Future<void> deleteComment(int projectId, int postId, int commentId) {
    return _api.unwrap(
      (dio) => dio.delete(
        '/api/v1/projects/$projectId/discussion/posts/$postId/comments/$commentId',
      ),
      (_) {},
    );
  }

  /// POST .../comments/{commentId}/like
  Future<({bool liked, int likeCount})> toggleCommentLike(
    int projectId,
    int postId,
    int commentId,
  ) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/projects/$projectId/discussion/posts/$postId/comments/$commentId/like',
      ),
      (data) {
        final map = data as Map<String, dynamic>;
        return (
          liked: map['liked'] as bool? ?? false,
          likeCount: map['likeCount'] as int? ?? 0,
        );
      },
    );
  }
}
