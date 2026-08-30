import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/models/user_search_result.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/skill_chip.dart';
import '../providers/project_management_provider.dart';
import '../providers/user_search_provider.dart';
import '../widgets/difficulty_badge.dart';

class ProjectManageScreen extends StatefulWidget {
  const ProjectManageScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectManageScreen> createState() => _ProjectManageScreenState();
}

class _ProjectManageScreenState extends State<ProjectManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<ProjectManagementProvider>().loadManageData(
    widget.projectId,
  );

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ProjectManagementProvider>();
    final project = mgmt.managedProject;
    final myId = context.watch<AuthProvider>().currentUser?.id;
    final isMember =
        project != null &&
        (project.ownerId == myId ||
            project.viewerMembershipStatus == MemberStatus.accepted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Project'),
        centerTitle: true,
        actions: [
          if (project != null)
            IconButton(
              tooltip: 'Discussion',
              icon: const Icon(Icons.forum_outlined),
              onPressed: () => context.push(
                '/projects/${project.id}/discussion',
                extra: {'name': project.name, 'isMember': isMember},
              ),
            ),
          IconButton(
            tooltip: 'Edit project',
            icon: const Icon(Icons.edit_outlined),
            onPressed: project == null
                ? null
                : () => context.push('/projects/mine/${widget.projectId}/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildBody(context, mgmt),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectManagementProvider mgmt) {
    final p = AppPalette.of(context);

    switch (mgmt.manageState) {
      case ManageLoadState.initial:
      case ManageLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case ManageLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: mgmt.manageError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case ManageLoadState.loaded:
        final project = mgmt.managedProject!;
        final isInactive =
            project.status == ProjectStatus.cancelled ||
            project.status == ProjectStatus.completed;

        return DefaultTabController(
          key: ValueKey('loaded_$isInactive'),
          length: isInactive ? 1 : 3,
          child: Column(
            children: [
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProjectSummaryHeader(
                                project: project,
                                mgmt: mgmt,
                              ),
                              const SizedBox(height: 16),
                              _ProjectLifecycleSection(
                                project: project,
                                mgmt: mgmt,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          TabBar(
                            labelColor: p.indigo,
                            unselectedLabelColor: p.textMuted,
                            indicatorColor: p.indigo,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: [
                              const Tab(text: 'Team'),
                              if (!isInactive) ...[
                                Tab(
                                  text: mgmt.pendingRequests.isEmpty
                                      ? 'Requests'
                                      : 'Requests (${mgmt.pendingRequests.length})',
                                ),
                                const Tab(text: 'Invite'),
                              ],
                            ],
                          ),
                          p.surface1,
                          p.border,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _TeamTab(projectId: widget.projectId, mgmt: mgmt),
                      if (!isInactive) ...[
                        _RequestsTab(projectId: widget.projectId, mgmt: mgmt),
                        _InviteTab(projectId: widget.projectId, mgmt: mgmt),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this._backgroundColor, this._borderColor);

  final TabBar _tabBar;
  final Color _backgroundColor;
  final Color _borderColor;

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: _backgroundColor,
      child: Column(
        children: [
          _tabBar,
          Divider(height: 1, color: _borderColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _ProjectSummaryHeader extends StatelessWidget {
  const _ProjectSummaryHeader({required this.project, required this.mgmt});
  final Project project;
  final ProjectManagementProvider mgmt;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(p, project.status),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DifficultyBadge(difficulty: project.difficulty),
            const SizedBox(width: 12),
            Icon(Icons.groups_outlined, size: 16, color: p.textMuted),
            const SizedBox(width: 4),
            Text(
              '${mgmt.acceptedMembers.length + 1}/${project.teamSize} members',
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
        if (project.description != null && project.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            project.description!,
            style: TextStyle(
              fontSize: 13.5,
              color: p.textSecondary,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const SectionHeader(
          label: 'REQUIRED SKILLS',
          icon: Icons.checklist_outlined,
        ),
        const SizedBox(height: 8),
        if (project.requiredSkills.isEmpty)
          Text(
            'No specific skills listed.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.requiredSkills
                .map((s) => SkillChipWidget(skill: s))
                .toList(),
          ),
        if (project.requiredRoles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.requiredRoles.map<Widget>((r) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.name,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: p.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

Widget _statusBadge(AppPalette p, ProjectStatus status) {
  final (bg, fg, label) = switch (status) {
    ProjectStatus.open => (p.greenLight, p.greenText, 'Open'),
    ProjectStatus.full => (p.amberLight, p.amberText, 'Full'),
    ProjectStatus.completed => (p.surface1, p.textSecondary, 'Completed'),
    ProjectStatus.cancelled => (p.redLight, p.red, 'Cancelled'),
    ProjectStatus.unknown => (p.surface1, p.textSecondary, '—'),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.projectId, required this.mgmt});
  final int projectId;
  final ProjectManagementProvider mgmt;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<ProjectManagementProvider>().loadManageData(projectId),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          SectionHeader(
            label: 'TEAM (${mgmt.acceptedMembers.length + 1})',
            icon: Icons.groups_2_outlined,
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final me = context.watch<AuthProvider>().currentUser;
              if (me == null) return const SizedBox.shrink();
              return _OwnerTile(
                userId: me.id,
                name: me.name,
                email: me.email,
                avatarUrl: me.avatarUrl,
              );
            },
          ),
          ...mgmt.acceptedMembers.map(
            (m) => _AcceptedMemberTile(projectId: projectId, member: m),
          ),
          if (mgmt.pendingInvites.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeader(
              label:
                  'INVITED — AWAITING RESPONSE (${mgmt.pendingInvites.length})',
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 10),
            ...mgmt.pendingInvites.map((m) => _InvitedTile(member: m)),
          ],
          if (mgmt.recommendedMembers.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(
              label: 'RECOMMENDED TEAMMATES',
              icon: Icons.stars_outlined,
            ),
            const SizedBox(height: 10),
            ...mgmt.recommendedMembers.map(
              (m) => _RecommendedInviteTile(projectId: projectId, member: m),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.projectId, required this.mgmt});
  final int projectId;
  final ProjectManagementProvider mgmt;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          context.read<ProjectManagementProvider>().loadManageData(projectId),
      child: mgmt.pendingRequests.isEmpty
          ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: p.indigoLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_empty,
                      size: 28,
                      color: p.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You'll see join requests here as people apply.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: mgmt.pendingRequests
                  .map(
                    (m) => _PendingRequestTile(projectId: projectId, member: m),
                  )
                  .toList(),
            ),
    );
  }
}

class _InviteTab extends StatelessWidget {
  const _InviteTab({required this.projectId, required this.mgmt});
  final int projectId;
  final ProjectManagementProvider mgmt;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<ProjectManagementProvider>().loadManageData(projectId),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const SectionHeader(
            label: 'INVITE BY NAME OR EMAIL',
            icon: Icons.person_search_outlined,
          ),
          const SizedBox(height: 10),
          _SearchInviteSection(projectId: projectId),
        ],
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  const _PendingRequestTile({required this.projectId, required this.member});

  final int projectId;
  final ProjectMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final isPending = mgmt.pendingActionUserIds.contains(member.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, member.name, member.avatarUrl, member.userId),
          const SizedBox(width: 12),
          Expanded(
            child: _tappableToProfile(
              context,
              member.userId,
              Text(
                member.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
          if (isPending)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              tooltip: 'Reject',
              icon: Icon(Icons.close, color: p.red, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<ProjectManagementProvider>().rejectRequest(
                  projectId,
                  member.userId,
                );
              },
            ),
            IconButton(
              tooltip: 'Accept',
              icon: Icon(Icons.check, color: p.green, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<ProjectManagementProvider>().acceptRequest(
                  projectId,
                  member.userId,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AcceptedMemberTile extends StatelessWidget {
  const _AcceptedMemberTile({required this.projectId, required this.member});

  final int projectId;
  final ProjectMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final isPending = mgmt.pendingActionUserIds.contains(member.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, member.name, member.avatarUrl, member.userId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tappableToProfile(
                  context,
                  member.userId,
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                if (member.email != null && member.email!.isNotEmpty)
                  _CopyableEmail(email: member.email!),
              ],
            ),
          ),
          if (isPending)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: 'Remove from team',
              icon: Icon(
                Icons.person_remove_outlined,
                color: p.textMuted,
                size: 20,
              ),
              onPressed: () => _confirmRemove(context, projectId, member),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    int projectId,
    ProjectMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.name} will be removed from this project.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      context.read<ProjectManagementProvider>().removeMember(
        projectId,
        member.userId,
      );
    }
  }
}

class _CopyableEmail extends StatelessWidget {
  const _CopyableEmail({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            email,
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            Clipboard.setData(ClipboardData(text: email));
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Email copied.')));
          },
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.copy, size: 12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
  final int userId;
  final String name;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, name, avatarUrl, userId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tappableToProfile(
                  context,
                  userId,
                  Text(
                    '$name (You)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                _CopyableEmail(email: email),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.amberLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Owner',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: p.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _tappableToProfile(BuildContext context, int userId, Widget child) {
  return GestureDetector(
    onTap: () => context.push('/users/$userId/portfolio'),
    child: child,
  );
}

Widget _avatar(
  BuildContext context,
  AppPalette p,
  String name,
  String? avatarUrl,
  int userId,
) {
  final initials = name.trim().isEmpty
      ? '?'
      : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase();
  return GestureDetector(
    onTap: () => context.push('/users/$userId/portfolio'),
    child: UserAvatar(avatarUrl: avatarUrl, initials: initials, radius: 16),
  );
}

class _InvitedTile extends StatelessWidget {
  const _InvitedTile({required this.member});
  final ProjectMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, member.name, member.avatarUrl, member.userId),
          const SizedBox(width: 12),
          Expanded(
            child: _tappableToProfile(
              context,
              member.userId,
              Text(
                member.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.amberLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                color: p.amberText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedInviteTile extends StatelessWidget {
  const _RecommendedInviteTile({required this.projectId, required this.member});

  final int projectId;
  final RecommendedMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final alreadyInvited =
        mgmt.invitedUserIds.contains(member.userId) ||
        mgmt.members.any((m) => m.userId == member.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, member.name, member.avatarUrl, member.userId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tappableToProfile(
                  context,
                  member.userId,
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${member.matchScore.clamp(0, 100).round()}% match',
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (alreadyInvited)
            SizedBox(
              width: 72,
              child: Text(
                'Pending', // or 'Invited'
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: p.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            SizedBox(
              width: 72,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, // Keep inner padding consistent
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<ProjectManagementProvider>().invite(
                    projectId,
                    member.userId,
                  );
                },
                child: const Text('Invite'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchInviteSection extends StatefulWidget {
  const _SearchInviteSection({required this.projectId});
  final int projectId;

  @override
  State<_SearchInviteSection> createState() => _SearchInviteSectionState();
}

class _SearchInviteSectionState extends State<_SearchInviteSection> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final search = context.watch<UserSearchProvider>();
    final mgmt = context.watch<ProjectManagementProvider>();
    final myId = context.watch<AuthProvider>().currentUser?.id;

    final filteredResults = search.results.where((u) => u.id != myId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) =>
              context.read<UserSearchProvider>().onQueryChanged(v),
          decoration: InputDecoration(
            hintText: 'Search by name or email…',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<UserSearchProvider>().clear();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        switch (search.state) {
          UserSearchLoadState.idle => Text(
            'Type at least 2 characters to search.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          UserSearchLoadState.loading => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          UserSearchLoadState.error => Text(
            search.error ?? 'Search failed.',
            style: TextStyle(fontSize: 12, color: p.red),
          ),
          UserSearchLoadState.loaded when filteredResults.isEmpty => Text(
            'No one found matching that search.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          UserSearchLoadState.loaded => Column(
            children: filteredResults
                .map(
                  (u) => _SearchResultTile(
                    projectId: widget.projectId,
                    user: u,
                    alreadyInvited:
                        mgmt.invitedUserIds.contains(u.id) ||
                        mgmt.members.any((m) => m.userId == u.id),
                  ),
                )
                .toList(),
          ),
        },
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.projectId,
    required this.user,
    required this.alreadyInvited,
  });

  final int projectId;
  final UserSearchResult user;
  final bool alreadyInvited;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(context, p, user.name, user.avatarUrl, user.id),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tappableToProfile(
                  context,
                  user.id,
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Text(
                    user.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
              ],
            ),
          ),
          // In _RecommendedInviteTile and _SearchResultTile
          if (alreadyInvited)
            SizedBox(
              width: 72,
              child: Text(
                'Pending', // or 'Invited'
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: p.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            SizedBox(
              width: 72,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, // Keep inner padding consistent
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<ProjectManagementProvider>().invite(
                    projectId,
                    user.id,
                  );
                },
                child: const Text('Invite'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectLifecycleSection extends StatelessWidget {
  const _ProjectLifecycleSection({required this.project, required this.mgmt});

  final Project project;
  final ProjectManagementProvider mgmt;

  bool get _isActive =>
      project.status == ProjectStatus.open ||
      project.status == ProjectStatus.full;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (!_isActive) {
      final (icon, label) = project.status == ProjectStatus.completed
          ? (Icons.check_circle_outline, 'This project has been completed.')
          : (Icons.cancel_outlined, 'This project has been cancelled.');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: p.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: mgmt.isCompletingOrCancelling
                ? null
                : () => _confirmComplete(context),
            icon: Icon(Icons.check_circle_outline, size: 17, color: p.green),
            label: const Text('Mark Complete'),
            style: OutlinedButton.styleFrom(foregroundColor: p.green),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: mgmt.isCompletingOrCancelling
                ? null
                : () => _confirmCancel(context),
            icon: Icon(Icons.cancel_outlined, size: 17, color: p.red),
            label: const Text('Cancel Project'),
            style: OutlinedButton.styleFrom(foregroundColor: p.red),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark this project complete?'),
        content: const Text(
          "This creates a portfolio entry for you and every accepted "
          "member, and the project stops accepting new members. This "
          "can't be undone from here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProjectManagementProvider>().completeProject(
      project.id,
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project marked complete.')));
    } else {
      final err = context.read<ProjectManagementProvider>().manageError;
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this project?'),
        content: const Text(
          'Every accepted member will be notified that the project was '
          "cancelled. This can't be undone from here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep project'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel project'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProjectManagementProvider>().cancelProject(
      project.id,
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project cancelled.')));
    } else {
      final err = context.read<ProjectManagementProvider>().manageError;
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }
}
