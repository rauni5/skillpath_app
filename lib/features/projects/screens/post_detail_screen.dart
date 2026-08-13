import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
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
      appBar: AppBar(
        title: const Text('Post'),
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
            const SizedBox(height: 20),
            Text(
              'COMMENTS (${discussion.comments.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            if (discussion.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No comments yet — say something!',
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: p.indigoLight,
              child: Text(
                _initials(post.authorName),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: p.indigo,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.authorName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
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
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          post.body,
          style: TextStyle(fontSize: 14, height: 1.5, color: p.textSecondary),
        ),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onLike,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
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
        const Divider(height: 24),
      ],
    );
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
              if (onDelete != null)
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: p.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.body,
            style: TextStyle(fontSize: 13, height: 1.4, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 13,
                  color: comment.likedByMe ? p.red : p.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${comment.likeCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: comment.likedByMe ? p.red : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: p.surface1,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isSending ? null : onSend(),
                decoration: const InputDecoration(
                  hintText: 'Add a comment…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: p.indigo,
                disabledBackgroundColor: p.border,
              ),
              icon: const Icon(Icons.arrow_upward, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
