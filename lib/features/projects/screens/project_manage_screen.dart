import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/project_management_provider.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/recommended_member_tile.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Project')),
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
                    '${mgmt.acceptedMembers.length}/${project.teamSize} members',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                ],
              ),
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
                label: 'TEAM (${mgmt.acceptedMembers.length})',
                icon: Icons.groups_2_outlined,
              ),
              const SizedBox(height: 10),
              if (mgmt.acceptedMembers.isEmpty)
                Text(
                  'No members yet.',
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                )
              else
                ...mgmt.acceptedMembers.map(
                  (m) => _AcceptedMemberTile(
                    projectId: widget.projectId,
                    member: m,
                  ),
                ),
              if (mgmt.recommendedMembers.isNotEmpty) ...[
                const SizedBox(height: 24),
                SectionHeader(
                  label: 'RECOMMENDED TEAMMATES',
                  icon: Icons.stars_outlined,
                ),
                const SizedBox(height: 10),
                ...mgmt.recommendedMembers.map(
                  (m) => RecommendedMemberTile(member: m),
                ),
              ],
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
