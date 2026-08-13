import 'package:flutter/foundation.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/models/page_projects.dart';
import '../../../core/network/api_exception.dart';
import '../data/discussion_repository.dart';

enum BoardLoadState { initial, loading, loaded, error }

enum PostDetailLoadState { initial, loading, loaded, error }

class DiscussionProvider extends ChangeNotifier {
  DiscussionProvider({DiscussionRepository? repository})
    : _repo = repository ?? DiscussionRepository();

  final DiscussionRepository _repo;

  // --- Board feed ---
  BoardLoadState boardState = BoardLoadState.initial;
  String? boardError;
  List<DiscussionPost> posts = [];
  int _page = 0;
  bool hasMore = true;
  bool isLoadingMore = false;
  int? _loadedProjectId;
  DiscussionChannel? _loadedChannel;

  Future<void> loadBoard(int projectId, DiscussionChannel channel) async {
    _loadedProjectId = projectId;
    _loadedChannel = channel;
    boardState = BoardLoadState.loading;
    _page = 0;
    posts = [];
    notifyListeners();
    try {
      final result = await _repo.listPosts(projectId, channel, page: 0);
      posts = result.content;
      hasMore = !result.last;
      boardState = BoardLoadState.loaded;
    } catch (e) {
      boardError = e is ApiException ? e.message : 'Could not load this board.';
      boardState = BoardLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;
    final projectId = _loadedProjectId;
    final channel = _loadedChannel;
    if (projectId == null || channel == null) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final result = await _repo.listPosts(projectId, channel, page: next);
      posts = [...posts, ...result.content];
      _page = next;
      hasMore = !result.last;
    } catch (_) {
      // Silent — the board is already showing content; a failed "load
      // more" isn't worth interrupting the user over.
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  bool isCreatingPost = false;
  String? createPostError;

  Future<DiscussionPost?> createPost(
    int projectId, {
    required DiscussionChannel channel,
    required PostTag tag,
    required String title,
    required String body,
  }) async {
    isCreatingPost = true;
    createPostError = null;
    notifyListeners();
    try {
      final post = await _repo.createPost(
        projectId,
        channel: channel,
        tag: tag,
        title: title,
        body: body,
      );
      if (_loadedProjectId == projectId && _loadedChannel == channel) {
        posts = [post, ...posts];
      }
      return post;
    } catch (e) {
      createPostError = e is ApiException
          ? e.message
          : 'Could not publish that post.';
      return null;
    } finally {
      isCreatingPost = false;
      notifyListeners();
    }
  }

  Future<void> togglePostLikeInFeed(int projectId, int postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final original = posts[index];
    // Optimistic update.
    posts[index] = original.copyWith(
      likedByMe: !original.likedByMe,
      likeCount: original.likedByMe
          ? original.likeCount - 1
          : original.likeCount + 1,
    );
    notifyListeners();
    try {
      final result = await _repo.togglePostLike(projectId, postId);
      final i = posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        posts[i] = posts[i].copyWith(
          likedByMe: result.liked,
          likeCount: result.likeCount,
        );
        notifyListeners();
      }
    } catch (_) {
      final i = posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        posts[i] = original;
        notifyListeners();
      }
    }
  }

  // --- Single post + comments ---
  PostDetailLoadState detailState = PostDetailLoadState.initial;
  String? detailError;
  DiscussionPost? selectedPost;
  List<DiscussionComment> comments = [];
  bool isCommenting = false;
  String? commentError;

  Future<void> loadPostDetail(int projectId, int postId) async {
    detailState = PostDetailLoadState.loading;
    selectedPost = null;
    comments = [];
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getPost(projectId, postId),
        _repo.listComments(projectId, postId),
      ]);
      selectedPost = results[0] as DiscussionPost;
      comments = (results[1] as Page<DiscussionComment>).content;
      detailState = PostDetailLoadState.loaded;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not load this post.';
      detailState = PostDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<void> togglePostLikeInDetail(int projectId, int postId) async {
    final original = selectedPost;
    if (original == null || original.id != postId) return;
    selectedPost = original.copyWith(
      likedByMe: !original.likedByMe,
      likeCount: original.likedByMe
          ? original.likeCount - 1
          : original.likeCount + 1,
    );
    notifyListeners();
    try {
      final result = await _repo.togglePostLike(projectId, postId);
      if (selectedPost?.id == postId) {
        selectedPost = selectedPost!.copyWith(
          likedByMe: result.liked,
          likeCount: result.likeCount,
        );
        notifyListeners();
      }
    } catch (_) {
      if (selectedPost?.id == postId) {
        selectedPost = original;
        notifyListeners();
      }
    }
  }

  Future<bool> addComment(int projectId, int postId, String body) async {
    isCommenting = true;
    commentError = null;
    notifyListeners();
    try {
      final comment = await _repo.addComment(projectId, postId, body);
      comments = [...comments, comment];
      if (selectedPost?.id == postId) {
        selectedPost = selectedPost!.copyWith(
          commentCount: selectedPost!.commentCount + 1,
        );
      }
      return true;
    } catch (e) {
      commentError = e is ApiException
          ? e.message
          : 'Could not post that comment.';
      return false;
    } finally {
      isCommenting = false;
      notifyListeners();
    }
  }

  Future<void> toggleCommentLike(
    int projectId,
    int postId,
    int commentId,
  ) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;
    final original = comments[index];
    comments[index] = original.copyWith(
      likedByMe: !original.likedByMe,
      likeCount: original.likedByMe
          ? original.likeCount - 1
          : original.likeCount + 1,
    );
    notifyListeners();
    try {
      final result = await _repo.toggleCommentLike(
        projectId,
        postId,
        commentId,
      );
      final i = comments.indexWhere((c) => c.id == commentId);
      if (i != -1) {
        comments[i] = comments[i].copyWith(
          likedByMe: result.liked,
          likeCount: result.likeCount,
        );
        notifyListeners();
      }
    } catch (_) {
      final i = comments.indexWhere((c) => c.id == commentId);
      if (i != -1) {
        comments[i] = original;
        notifyListeners();
      }
    }
  }

  Future<bool> deletePost(int projectId, int postId) async {
    try {
      await _repo.deletePost(projectId, postId);
      posts = posts.where((p) => p.id != postId).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not delete this post.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(int projectId, int postId, int commentId) async {
    try {
      await _repo.deleteComment(projectId, postId, commentId);
      comments = comments.where((c) => c.id != commentId).toList();
      if (selectedPost?.id == postId) {
        selectedPost = selectedPost!.copyWith(
          commentCount: (selectedPost!.commentCount - 1).clamp(0, 1 << 30),
        );
      }
      return true;
    } catch (e) {
      commentError = e is ApiException
          ? e.message
          : 'Could not delete this comment.';
      notifyListeners();
      return false;
    }
  }
}
