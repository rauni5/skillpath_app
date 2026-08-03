import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';
import 'package:skillpath_app/core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/project_management_provider.dart';
import '../widgets/difficulty_badge.dart';

class MyInvitesScreen extends StatefulWidget {
  const MyInvitesScreen({super.key});

  @override
  State<MyInvitesScreen> createState() => _MyInvitesScreenState();
}

class _MyInvitesScreenState extends State<MyInvitesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null)
      context.read<ProjectManagementProvider>().loadMyInvites(userId);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Invites')),
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
    switch (mgmt.myInvitesState) {
      case MyInvitesLoadState.initial:
      case MyInvitesLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case MyInvitesLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: mgmt.myInvitesError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case MyInvitesLoadState.loaded:
        if (mgmt.myInvites.isEmpty) {
          return RefreshIndicator(
            key: const ValueKey('empty'),
            onRefresh: () async => _load(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.mail_outline, size: 40, color: p.textMuted),
                const SizedBox(height: 14),
                Text(
                  "You don't have any invites right now.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mgmt.myInvites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _InviteCard(invite: mgmt.myInvites[i]),
          ),
        );
    }
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invite.projectName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              DifficultyBadge(difficulty: invite.difficulty),
              if (invite.teamSize != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.groups_outlined, size: 14, color: p.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Team of ${invite.teamSize}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
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
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final mgmt = context.read<ProjectManagementProvider>();
    final ok = accept
        ? await mgmt.acceptInvite(userId, invite.projectId)
        : await mgmt.declineInvite(userId, invite.projectId);
    if (!ok && context.mounted && mgmt.myInvitesError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mgmt.myInvitesError!)));
    }
  }
}
