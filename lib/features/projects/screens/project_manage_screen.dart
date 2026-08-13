import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project_member.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/models/user_search_result.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
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
    final p = AppPalette.of(context);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, mgmt),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    ProjectManagementProvider mgmt,
  ) {
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
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Text(
                project.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DifficultyBadge(difficulty: project.difficulty),
                  const SizedBox(width: 8),
                  Icon(Icons.groups_outlined, size: 14, color: p.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${mgmt.acceptedMembers.length + 1}/${project.teamSize} members',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                ],
              ),
              if (project.requiredRoles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.requiredRoles.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: p.indigoLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: p.indigo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              SectionHeader(
                label: 'PENDING REQUESTS (${mgmt.pendingRequests.length})',
                icon: Icons.hourglass_empty,
              ),
              const SizedBox(height: 10),
              if (mgmt.pendingRequests.isEmpty)
                Text(
                  'No pending requests.',
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                )
              else
                ...mgmt.pendingRequests.map(
                  (m) => _PendingRequestTile(
                    projectId: widget.projectId,
                    member: m,
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(
                label: 'TEAM (${mgmt.acceptedMembers.length + 1})',
                icon: Icons.groups_2_outlined,
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final me = context.watch<AuthProvider>().currentUser;
                  if (me == null) return const SizedBox.shrink();
                  return _OwnerTile(name: me.name, email: me.email);
                },
              ),
              ...mgmt.acceptedMembers.map(
                (m) =>
                    _AcceptedMemberTile(projectId: widget.projectId, member: m),
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
                SectionHeader(
                  label: 'RECOMMENDED TEAMMATES',
                  icon: Icons.stars_outlined,
                ),
                const SizedBox(height: 10),
                ...mgmt.recommendedMembers.map(
                  (m) => _RecommendedInviteTile(
                    projectId: widget.projectId,
                    member: m,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SectionHeader(
                label: 'INVITE BY NAME OR EMAIL',
                icon: Icons.person_search_outlined,
              ),
              const SizedBox(height: 10),
              _SearchInviteSection(projectId: widget.projectId),
            ],
          ),
        );
    }
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, member.name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, member.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
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
            child: Icon(Icons.copy, size: 13, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name (You)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                _CopyableEmail(email: email),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: p.amberLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Owner',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: p.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _avatar(AppPalette p, String name) {
  final initials = name.trim().isEmpty
      ? '?'
      : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase();
  return CircleAvatar(
    radius: 16,
    backgroundColor: p.indigoLight,
    child: Text(
      initials,
      style: TextStyle(
        color: p.indigo,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InvitedTile extends StatelessWidget {
  const _InvitedTile({required this.member});
  final ProjectMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, member.name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
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
                fontWeight: FontWeight.w600,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, member.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '${member.matchScore.clamp(0, 100).round()}% match',
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (alreadyInvited)
            Text(
              'Invited',
              style: TextStyle(
                fontSize: 11.5,
                color: p.textMuted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<ProjectManagementProvider>().invite(
                  projectId,
                  member.userId,
                );
              },
              child: const Text('Invite'),
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
    context.read<UserSearchProvider>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final search = context.watch<UserSearchProvider>();
    final mgmt = context.watch<ProjectManagementProvider>();

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
        const SizedBox(height: 10),
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
          UserSearchLoadState.loaded when search.results.isEmpty => Text(
            'No one found matching that search.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          UserSearchLoadState.loaded => Column(
            children: search.results
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _avatar(p, user.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Text(
                    user.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
              ],
            ),
          ),
          if (alreadyInvited)
            Text(
              'Invited',
              style: TextStyle(
                fontSize: 11.5,
                color: p.textMuted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<ProjectManagementProvider>().invite(
                  projectId,
                  user.id,
                );
              },
              child: const Text('Invite'),
            ),
        ],
      ),
    );
  }
}
