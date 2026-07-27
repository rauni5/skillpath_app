import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/models/project.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../dashboard/widgets/skill_chip.dart';
import '../providers/projects_provider.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/recommended_member_tile.dart';

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

  void _load() => context.read<ProjectsProvider>().loadProjectDetail(widget.projectId);

  Future<void> _join() async {
    HapticFeedback.mediumImpact();
    final projects = context.read<ProjectsProvider>();
    final ok = await projects.joinProject(widget.projectId);
    if (!ok && mounted && projects.detailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(projects.detailError!)));
    } else if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You're in! Request sent to the project owner.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Project')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, projects),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppPalette p, ProjectsProvider projects) {
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
        final hasJoined = projects.joinedIds.contains(project.id);
        final canJoin = project.status == ProjectStatus.open && !hasJoined;

        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(project.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.textPrimary)),
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
                Text('Team of ${project.teamSize}', style: TextStyle(fontSize: 12, color: p.textMuted)),
              ],
            ),
            if (project.description != null && project.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(project.description!, style: TextStyle(fontSize: 13.5, color: p.textSecondary, height: 1.5)),
            ],
            const SizedBox(height: 20),
            SectionHeader(label: 'REQUIRED SKILLS', icon: Icons.checklist_outlined),
            const SizedBox(height: 8),
            if (project.requiredSkills.isEmpty)
              Text('No specific skills listed.', style: TextStyle(fontSize: 12.5, color: p.textMuted))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.requiredSkills.map((s) => SkillChipWidget(skill: s)).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: hasJoined
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.check_circle, color: p.green, size: 18),
                      label: const Text('Request sent'),
                    )
                  : FilledButton(
                      onPressed: canJoin && !isPending ? _join : null,
                      style: FilledButton.styleFrom(backgroundColor: p.indigo, foregroundColor: Colors.white),
                      child: isPending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(project.status == ProjectStatus.open ? 'Join this project' : 'Not accepting members'),
                    ),
            ),
            if (projects.recommendedMembers.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionHeader(label: 'RECOMMENDED TEAMMATES', icon: Icons.stars_outlined),
              const SizedBox(height: 10),
              ...projects.recommendedMembers.map((m) => RecommendedMemberTile(member: m)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
