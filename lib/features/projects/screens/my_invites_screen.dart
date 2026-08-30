import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_app/core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/elevated_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/project_management_provider.dart';
import '../widgets/difficulty_badge.dart';

enum InvitesTab { invites, requests }

class MyInvitesScreen extends StatefulWidget {
  const MyInvitesScreen({super.key});

  @override
  State<MyInvitesScreen> createState() => _MyInvitesScreenState();
}

class _MyInvitesScreenState extends State<MyInvitesScreen> {
  InvitesTab _selectedTab = InvitesTab.invites;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final mgmt = context.read<ProjectManagementProvider>();
    mgmt.loadMyInvites(userId);
    mgmt.loadMyJoinRequests(userId);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();

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
        title: const Text('Invites & Requests'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<InvitesTab>(
                segments: [
                  ButtonSegment<InvitesTab>(
                    value: InvitesTab.invites,
                    label: Text('Invites (${mgmt.myInvites.length})'),
                    icon: const Icon(Icons.mail_outline, size: 18),
                  ),
                  ButtonSegment<InvitesTab>(
                    value: InvitesTab.requests,
                    label: Text('Requests (${mgmt.myJoinRequests.length})'),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (Set<InvitesTab> newSelection) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildTabContent(context, p, mgmt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    AppPalette p,
    ProjectManagementProvider mgmt,
  ) {
    final isInvites = _selectedTab == InvitesTab.invites;

    final isLoading = isInvites
        ? (mgmt.myInvitesState == MyInvitesLoadState.initial ||
              mgmt.myInvitesState == MyInvitesLoadState.loading)
        : (mgmt.myJoinRequestsState == MyInvitesLoadState.initial ||
              mgmt.myJoinRequestsState == MyInvitesLoadState.loading);

    if (isLoading) {
      return const LoadingView(key: ValueKey('loading'));
    }

    final hasFailed = isInvites
        ? mgmt.myInvitesState == MyInvitesLoadState.error
        : mgmt.myJoinRequestsState == MyInvitesLoadState.error;

    if (hasFailed) {
      return ErrorView(
        key: const ValueKey('error'),
        message:
            (isInvites ? mgmt.myInvitesError : mgmt.myJoinRequestsError) ??
            'Something went wrong.',
        onRetry: _load,
      );
    }

    final items = isInvites ? mgmt.myInvites : mgmt.myJoinRequests;

    if (items.isEmpty) {
      return RefreshIndicator(
        key: ValueKey('empty_${_selectedTab.name}'),
        onRefresh: () async => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInvites ? Icons.mail_outline : Icons.person_add_outlined,
                  size: 32,
                  color: p.indigo,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isInvites
                  ? "You don't have any project invites"
                  : "No pending join requests",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isInvites
                  ? 'Invitations from project owners will show up here.'
                  : 'Requests from users wanting to join your projects will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: ValueKey('loaded_${_selectedTab.name}'),
      onRefresh: () async => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: isInvites
                ? _InviteCard(invite: item as ProjectInvite)
                : _JoinRequestCard(request: item as ProjectJoinRequest),
          );
        },
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite});
  final ProjectInvite invite;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final isResponding = mgmt.respondingProjectIds.contains(invite.projectId);

    return ElevatedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  invite.projectName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              if (invite.invitedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _relativeTime(invite.invitedAt!),
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ],
          ),
          if (invite.ownerName != null && invite.ownerName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: invite.ownerId == null
                  ? null
                  : () => context.push('/users/${invite.ownerId}/portfolio'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    avatarUrl: invite.ownerAvatarUrl,
                    initials: invite.ownerInitials,
                    radius: 9,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Invited by ${invite.ownerName}',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              DifficultyBadge(difficulty: invite.difficulty),
              if (invite.teamSize != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.groups_outlined, size: 14, color: p.textMuted),
                const SizedBox(width: 4),
                Text(
                  invite.memberCount != null
                      ? '${invite.memberCount}/${invite.teamSize} members'
                      : 'Team of ${invite.teamSize}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ],
          ),
          if (invite.description != null &&
              invite.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              invite.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: p.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (invite.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: invite.requiredSkills.take(5).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface1,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    s.name,
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          if (isResponding)
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () => _respond(context, accept: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, accept: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    HapticFeedback.mediumImpact();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final mgmt = context.read<ProjectManagementProvider>();
    final ok = accept
        ? await mgmt.acceptInvite(userId, invite.projectId)
        : await mgmt.declineInvite(userId, invite.projectId);
    if (!ok && context.mounted && mgmt.myInvitesError != null) {
      showErrorDialog(
        context,
        mgmt.myInvitesError!,
        title: 'Failed to respond to invite',
      );
    }
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({required this.request});
  final ProjectJoinRequest request;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final isResponding = mgmt.respondingProjectIds.contains(request.projectId);

    return ElevatedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.projectName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                context.push('/users/${request.requesterId}/portfolio'),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: request.requesterAvatarUrl,
                  initials: request.requesterInitials,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'Wants to join your project',
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (request.requesterSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: request.requesterSkills.take(5).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface1,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    s.name,
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          if (isResponding)
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () => _respond(context, accept: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, accept: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    HapticFeedback.mediumImpact();
    final mgmt = context.read<ProjectManagementProvider>();
    final ok = accept
        ? await mgmt.acceptJoinRequest(request.projectId, request.requesterId)
        : await mgmt.declineJoinRequest(request.projectId, request.requesterId);
    if (!ok && context.mounted && mgmt.myJoinRequestsError != null) {
      showErrorDialog(
        context,
        mgmt.myJoinRequestsError!,
        title: 'Failed to respond to request',
      );
    }
  }
}
