import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../providers/discussion_provider.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.projectId,
    required this.postId,
  });

  final int projectId;
  final int postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _load() {
    context.read<DiscussionProvider>().loadPostDetail(
      widget.projectId,
      widget.postId,
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    final ok = await context.read<DiscussionProvider>().addComment(
      widget.projectId,
      widget.postId,
      text,
    );
    if (!ok && mounted) {
      final err = context.read<DiscussionProvider>().commentError;
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This removes the post and all its comments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<DiscussionProvider>().deletePost(
      widget.projectId,
      widget.postId,
    );
    if (ok && mounted) context.pop();
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final discussionProvider = context.read<DiscussionProvider>();
    await discussionProvider.deleteComment(
      widget.projectId,
      widget.postId,
      commentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final discussion = context.watch<DiscussionProvider>();
    final post = discussion.selectedPost;

    return Scaffold(
      backgroundColor: p.surface0,
      appBar: AppBar(
        title: const Text('Post'),
        elevation: 0,
        actions: [
          if (post != null && post.canDelete)
            IconButton(
              tooltip: 'Delete post',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, discussion),
            ),
          ),
          if (post != null)
            _CommentComposer(
              controller: _commentCtrl,
              focusNode: _commentFocus,
              onSend: _sendComment,
              isSending: discussion.isCommenting,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    DiscussionProvider discussion,
  ) {
    switch (discussion.detailState) {
      case PostDetailLoadState.initial:
      case PostDetailLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case PostDetailLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: discussion.detailError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case PostDetailLoadState.loaded:
        final post = discussion.selectedPost!;
        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _PostHeader(
              post: post,
              onLike: () =>
                  discussion.togglePostLikeInDetail(widget.projectId, post.id),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  'COMMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${discussion.comments.length}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (discussion.comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 24,
                      color: p.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No comments yet — say something!',
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  ],
                ),
              )
            else
              ...discussion.comments.map(
                (c) => _CommentTile(
                  comment: c,
                  onLike: () => discussion.toggleCommentLike(
                    widget.projectId,
                    post.id,
                    c.id,
                  ),
                  onDelete: c.canDelete ? () => _deleteComment(c.id) : null,
                ),
              ),
          ],
        );
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onLike});
  final DiscussionPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (accent, _) = _tagColors(p, post.tag);

    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored sidebar accent strip on the main post card
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TagChip(tag: post.tag),
                        const Spacer(),
                        Text(
                          '${post.createdAt.month}/${post.createdAt.day}/${post.createdAt.year}',
                          style: TextStyle(fontSize: 11, color: p.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          context.push('/users/${post.authorId}/portfolio'),
                      child: Row(
                        children: [
                          UserAvatar(
                            avatarUrl: post.authorAvatarUrl,
                            initials: _initials(post.authorName),
                            radius: 13,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.authorName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      post.body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: post.likedByMe
                              ? p.redLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.likedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: post.likedByMe ? p.red : p.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.likeCount} like${post.likeCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: post.likedByMe ? p.red : p.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed
      .split(RegExp(r'\s+'))
      .map((s) => s[0])
      .take(2)
      .join()
      .toUpperCase();
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLike,
    this.onDelete,
  });

  final DiscussionComment comment;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.push('/users/${comment.authorId}/portfolio'),
                  child: Row(
                    children: [
                      UserAvatar(
                        avatarUrl: comment.authorAvatarUrl,
                        initials: _initials(comment.authorName),
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          comment.authorName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Heart / Like button aligned to the right side
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: comment.likedByMe ? p.red : p.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.likeCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: comment.likedByMe ? p.red : p.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: TextStyle(fontSize: 13, height: 1.4, color: p.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final PostTag tag;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (fg, bg) = _tagColors(p, tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isSending,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isSending ? null : onSend(),
                  style: TextStyle(fontSize: 13.5, color: p.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: TextStyle(color: p.textMuted, fontSize: 13.5),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: isSending ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: p.indigo,
                  disabledBackgroundColor: p.border,
                  minimumSize: const Size(38, 38),
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kept in sync with the same helper in project_discussion_screen.dart so
/// the feed and this detail screen agree on one color per tag. Small
/// enough that duplicating it beats a shared file for one six-line
/// function — pull it into core/theme if a third screen ever needs it.
(Color, Color) _tagColors(AppPalette p, PostTag tag) {
  return switch (tag) {
    PostTag.question => (p.indigo, p.indigoLight),
    PostTag.update => (p.greenText, p.greenLight),
    PostTag.announcement => (p.amberText, p.amberLight),
    PostTag.general => (p.textMuted, p.surface1),
  };
}
