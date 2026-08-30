import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../providers/discussion_provider.dart';

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

/// Reddit-style discussion for one project: a PUBLIC board anyone signed in
/// can read and post to, and a TEAM board restricted to accepted members.
class ProjectDiscussionScreen extends StatefulWidget {
  const ProjectDiscussionScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.isMember,
  });

  final int projectId;
  final String projectName;

  /// Whether the current user is the owner or an accepted member — controls
  /// whether the Team tab is shown at all.
  final bool isMember;

  @override
  State<ProjectDiscussionScreen> createState() =>
      _ProjectDiscussionScreenState();
}

class _ProjectDiscussionScreenState extends State<ProjectDiscussionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isMember ? 2 : 1,
      vsync: this,
    );
    _scrollController = ScrollController()..addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _load(DiscussionChannel.public),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _load(_currentChannel);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscussionProvider>().loadMore();
    }
  }

  DiscussionChannel get _currentChannel => _tabController.index == 1
      ? DiscussionChannel.team
      : DiscussionChannel.public;

  void _load(DiscussionChannel channel) {
    context.read<DiscussionProvider>().loadBoard(widget.projectId, channel);
  }

  void _newPost() {
    context.push(
      '/projects/${widget.projectId}/discussion/new',
      extra: _currentChannel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final discussion = context.watch<DiscussionProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/projects');
            }
          },
        ),
        title: Text(widget.projectName),
        bottom: widget.isMember
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Public'),
                  Tab(text: 'Team'),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newPost,
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, discussion),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    DiscussionProvider discussion,
  ) {
    switch (discussion.boardState) {
      case BoardLoadState.initial:
      case BoardLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case BoardLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: discussion.boardError ?? 'Something went wrong.',
          onRetry: () => _load(_currentChannel),
        );
      case BoardLoadState.loaded:
        if (discussion.posts.isEmpty) {
          return ListView(
            key: const ValueKey('empty'),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 60),
              Icon(
                _currentChannel == DiscussionChannel.public
                    ? Icons.forum_outlined
                    : Icons.groups_outlined,
                size: 36,
                color: p.textMuted,
              ),
              const SizedBox(height: 14),
              Text(
                _currentChannel == DiscussionChannel.public
                    ? 'No posts yet — be the first to start a discussion.'
                    : 'No team posts yet — this space is just for the team.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ],
          );
        }
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(_currentChannel),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: discussion.posts.length + (discussion.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i >= discussion.posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final post = discussion.posts[i];
              return _PostCard(
                projectId: widget.projectId,
                post: post,
                onTap: () => context.push(
                  '/projects/${widget.projectId}/discussion/post/${post.id}',
                ),
                onLike: () =>
                    discussion.togglePostLikeInFeed(widget.projectId, post.id),
              );
            },
          ),
        );
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.projectId,
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  final int projectId;
  final DiscussionPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.indigo.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TagChip(tag: post.tag),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/users/${post.authorId}/portfolio'),
                      child: Row(
                        children: [
                          UserAvatar(
                            avatarUrl: post.authorAvatarUrl,
                            initials: _initials(post.authorName),
                            radius: 10,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _relativeTime(post.createdAt),
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                post.body,
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
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
                            post.likedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: post.likedByMe ? p.red : p.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: post.likedByMe ? p.red : p.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 15,
                    color: p.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final PostTag tag;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (bg, fg) = switch (tag) {
      PostTag.question => (p.indigoLight, p.indigo),
      PostTag.update => (p.greenLight, p.greenText),
      PostTag.announcement => (p.amberLight, p.amberText),
      PostTag.general => (p.surface1, p.textMuted),
    };
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
