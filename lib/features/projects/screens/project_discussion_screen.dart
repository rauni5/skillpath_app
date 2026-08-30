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
  /// whether the Team channel is shown at all.
  final bool isMember;

  @override
  State<ProjectDiscussionScreen> createState() =>
      _ProjectDiscussionScreenState();
}

class _ProjectDiscussionScreenState extends State<ProjectDiscussionScreen> {
  late final ScrollController _scrollController;
  DiscussionChannel _channel = DiscussionChannel.public;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(_channel));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscussionProvider>().loadMore();
    }
  }

  void _selectChannel(DiscussionChannel channel) {
    if (channel == _channel) return;
    setState(() => _channel = channel);
    _load(channel);
  }

  void _load(DiscussionChannel channel) {
    context.read<DiscussionProvider>().loadBoard(widget.projectId, channel);
  }

  void _newPost() {
    context.push(
      '/projects/${widget.projectId}/discussion/new',
      extra: _channel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final discussion = context.watch<DiscussionProvider>();

    return Scaffold(
      backgroundColor: p.surface0,
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
        elevation: 0,
        bottom: widget.isMember
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _ChannelSwitcher(
                    selected: _channel,
                    onSelect: _selectChannel,
                  ),
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newPost,
        backgroundColor: p.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
          onRetry: () => _load(_channel),
        );
      case BoardLoadState.loaded:
        if (discussion.posts.isEmpty) {
          return _EmptyBoard(key: const ValueKey('empty'), channel: _channel);
        }
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          color: p.indigo,
          onRefresh: () async => _load(_channel),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: discussion.posts.length + (discussion.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i >= discussion.posts.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.indigo,
                      ),
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

/// Custom pill segmented control instead of a default TabBar — matches the
/// rounded-pill language used elsewhere in the app (achievement badges,
/// filter chips) rather than Material's stock tab indicator underline.
class _ChannelSwitcher extends StatelessWidget {
  const _ChannelSwitcher({required this.selected, required this.onSelect});

  final DiscussionChannel selected;
  final ValueChanged<DiscussionChannel> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        // Explicit center alignment matters here: Stack's default
        // alignment (top-start) is what caused the icon/label row to sit
        // pinned to the top of the switcher instead of vertically centered
        // - the sliding pill behind it happened to fill the full height
        // via Align's expand behavior, so only the Row looked "off."
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: selected == DiscussionChannel.public
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: p.indigo,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: p.indigo.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _segment(
                context,
                label: 'Public',
                icon: Icons.public_rounded,
                isSelected: selected == DiscussionChannel.public,
                onTap: () => onSelect(DiscussionChannel.public),
              ),
              _segment(
                context,
                label: 'Team',
                icon: Icons.groups_rounded,
                isSelected: selected == DiscussionChannel.team,
                onTap: () => onSelect(DiscussionChannel.team),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final p = AppPalette.of(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : p.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: isSelected ? Colors.white : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({super.key, required this.channel});
  final DiscussionChannel channel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isPublic = channel == DiscussionChannel.public;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: p.indigoLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPublic ? Icons.forum_rounded : Icons.groups_rounded,
              size: 32,
              color: p.indigo,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          isPublic ? 'No posts yet' : 'No team posts yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isPublic
              ? 'Start a discussion — ask a question, share progress, or post an update for anyone to see.'
              : 'This space is just for the team. Post an update or ask something only your teammates will see.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.4),
        ),
      ],
    );
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
    final (accent, _) = _tagColors(p, post.tag);

    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Signature element for this rework: a tag-colored accent
                // rail down the left edge of every post, so the topic
                // reads at a glance while scanning the feed instead of
                // requiring you to read the tag chip text each time.
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '/users/${post.authorId}/portfolio',
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      avatarUrl: post.authorAvatarUrl,
                                      initials: _initials(post.authorName),
                                      radius: 11,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        post.authorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: p.textSecondary,
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
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                            height: 1.3,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _TagChip(tag: post.tag),
                            const Spacer(),
                            _Pill(
                              onTap: onLike,
                              icon: post.likedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: post.likedByMe ? p.red : p.textMuted,
                              label: '${post.likeCount}',
                            ),
                            const SizedBox(width: 6),
                            _Pill(
                              icon: Icons.mode_comment_outlined,
                              color: p.textMuted,
                              label: '${post.commentCount}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

class _Pill extends StatelessWidget {
  const _Pill({
    this.onTap,
    required this.icon,
    required this.color,
    required this.label,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: content,
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

/// Shared so the feed card's accent rail, its tag chip, and the post
/// detail screen's header/comment rails all agree on the same color per
/// tag — one visual language across the whole feature.
(Color, Color) _tagColors(AppPalette p, PostTag tag) {
  return switch (tag) {
    PostTag.question => (p.indigo, p.indigoLight),
    PostTag.update => (p.greenText, p.greenLight),
    PostTag.announcement => (p.amberText, p.amberLight),
    PostTag.general => (p.textMuted, p.surface1),
  };
}
