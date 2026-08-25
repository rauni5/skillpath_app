import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/skill_chip.dart';
import '../providers/project_management_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/difficulty_badge.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() =>
      context.read<ProjectsProvider>().loadProjectDetail(widget.projectId);

  Future<void> _join() async {
    HapticFeedback.mediumImpact();
    final projects = context.read<ProjectsProvider>();
    final ok = await projects.joinProject(widget.projectId);
    if (!ok && mounted && projects.detailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(projects.detailError!)));
    } else if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're in! Request sent to the project owner."),
        ),
      );
    }
  }

  Future<void> _respondToInvite({required bool accept}) async {
    HapticFeedback.mediumImpact();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final mgmt = context.read<ProjectManagementProvider>();
    final ok = accept
        ? await mgmt.acceptInvite(userId, widget.projectId)
        : await mgmt.declineInvite(userId, widget.projectId);
    if (!mounted) return;
    if (ok) {
      await context.read<ProjectsProvider>().loadProjectDetail(
        widget.projectId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? "You're on the team!" : 'Invite declined.'),
        ),
      );
    } else if (mgmt.myInvitesError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mgmt.myInvitesError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final project = projects.selectedProject;
    final myId = context.watch<AuthProvider>().currentUser?.id;
    final isMember =
        project != null &&
        (project.ownerId == myId ||
            project.viewerMembershipStatus == MemberStatus.accepted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
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
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, projects),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    ProjectsProvider projects,
  ) {
    switch (projects.detailState) {
      case ProjectDetailLoadState.initial:
      case ProjectDetailLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case ProjectDetailLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: projects.detailError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case ProjectDetailLoadState.loaded:
        final project = projects.selectedProject!;
        final isPending = projects.pendingJoinIds.contains(project.id);
        final viewerStatus = project.viewerMembershipStatus;
        final canJoin =
            project.status == ProjectStatus.open && viewerStatus == null;

        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                _statusBadge(p, project.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DifficultyBadge(difficulty: project.difficulty),
                const SizedBox(width: 8),
                Icon(Icons.groups_outlined, size: 14, color: p.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Team of ${project.teamSize}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
            if (project.ownerName != null && project.ownerName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    context.push('/users/${project.ownerId}/portfolio'),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: project.ownerAvatarUrl,
                      initials: project.ownerInitials,
                      radius: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project.ownerName!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· Owner',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
            if (project.description != null &&
                project.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                project.description!,
                style: TextStyle(
                  fontSize: 13.5,
                  color: p.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (project.link != null && project.link!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _LinkRow(link: project.link!),
            ],
            const SizedBox(height: 20),
            SectionHeader(
              label: 'REQUIRED SKILLS',
              icon: Icons.checklist_outlined,
            ),
            const SizedBox(height: 8),
            if (project.requiredSkills.isEmpty)
              Text(
                'No specific skills listed.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
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
              const SizedBox(height: 20),
              SectionHeader(label: 'TARGET ROLES', icon: Icons.badge_outlined),
              const SizedBox(height: 8),
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
            SizedBox(
              width: double.infinity,
              child: _joinButton(p, project, viewerStatus, canJoin, isPending),
            ),
            if (viewerStatus == MemberStatus.accepted) ...[
              const SizedBox(height: 28),
              SectionHeader(label: 'TEAM', icon: Icons.groups_2_outlined),
              const SizedBox(height: 10),
              if (projects.teamLoading)
                Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.indigo,
                  ),
                )
              else
                ...projects.team.map((m) => _TeamMemberTile(member: m)),
            ],
          ],
        );
    }
  }

  Widget _joinButton(
    AppPalette p,
    Project project,
    MemberStatus? status,
    bool canJoin,
    bool isPending,
  ) {
    switch (status) {
      case MemberStatus.accepted:
        return OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.check_circle, color: p.green, size: 18),
          label: const Text('Accepted'),
        );
      case MemberStatus.rejected:
        return OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.cancel_outlined, color: p.red, size: 18),
          label: const Text('Request rejected'),
        );
      case MemberStatus.pending:
        if (project.viewerInvitedByOwner) {
          final mgmt = context.watch<ProjectManagementProvider>();
          final isResponding = mgmt.respondingProjectIds.contains(project.id);
          if (isResponding) {
            return const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToInvite(accept: false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _respondToInvite(accept: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept invite'),
                ),
              ),
            ],
          );
        }
        return OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.hourglass_empty, color: p.textMuted, size: 18),
          label: const Text('Request sent'),
        );
      case MemberStatus.unknown:
      case null:
        return FilledButton(
          onPressed: canJoin && !isPending ? _join : null,
          style: FilledButton.styleFrom(
            backgroundColor: p.indigo,
            foregroundColor: Colors.white,
          ),
          child: isPending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  project.status == ProjectStatus.open
                      ? 'Join this project'
                      : 'Not accepting members',
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Icon(Icons.link, size: 14, color: p.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            link,
            style: TextStyle(fontSize: 12.5, color: p.indigo),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Copy link',
          icon: Icon(Icons.copy, size: 16, color: p.textMuted),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: link));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Link copied.')));
          },
        ),
      ],
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.member});
  final ProjectMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final initials = member.name.trim().isEmpty
        ? '?'
        : member.name
              .trim()
              .split(RegExp(r'\s+'))
              .map((s) => s[0])
              .take(2)
              .join()
              .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.indigo.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/users/${member.userId}/portfolio'),
            child: UserAvatar(
              avatarUrl: member.avatarUrl,
              initials: initials,
              radius: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      context.push('/users/${member.userId}/portfolio'),
                  child: Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 13,
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
          if (member.role == 'Owner')
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
