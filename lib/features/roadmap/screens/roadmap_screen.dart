import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/roadmap_step_tile.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = _userId;
    if (userId != null) context.read<RoadmapProvider>().load(userId);
  }

  void _openChat(RoadmapStep step) {
    context.push('/roadmap/skill/${step.skillId}/chat', extra: step.skillName);
  }

  Future<void> _openSkillCheck(RoadmapStep step) async {
    // The skill-check screen pops with `true` when the attempt was passed
    // (and the step therefore just flipped to done), so the roadmap only
    // needs to reload in that case.
    final passed = await context.push<bool>(
      '/roadmap/skill/${step.skillId}/skill-check',
      extra: step.skillName,
    );
    if (passed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = context.watch<RoadmapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your roadmap'),
        actions: [
          IconButton(
            tooltip: 'Ask AI about your roadmap',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => context.push('/roadmap/chat'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildBody(context, roadmap),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoadmapProvider roadmap) {
    final p = AppPalette.of(context);
    switch (roadmap.state) {
      case RoadmapLoadState.initial:
      case RoadmapLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case RoadmapLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: roadmap.errorMessage ?? 'Something went wrong.',
          onRetry: _load,
        );
      case RoadmapLoadState.loaded:
        if (roadmap.steps.isEmpty) {
          return ListView(
            key: const ValueKey('empty'),
            children: [
              const SizedBox(height: 100),
              Icon(Icons.map_outlined, size: 40, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Set a career goal on your profile\nto generate a roadmap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ],
          );
        }

        final completed = roadmap.steps
            .where((s) => s.status == RoadmapStepStatus.done)
            .length;
        final total = roadmap.steps.length;
        final remaining = total - completed;
        final categories = roadmap.steps
            .map((s) => s.skillCategory)
            .toSet()
            .length;
        final upNext = roadmap.steps.firstWhere(
          (s) => s.status != RoadmapStepStatus.done,
          orElse: () => roadmap.steps.first,
        );

        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.indigo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: total == 0 ? 0 : (completed / total) * 100,
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '${value.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          'through your path',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedProgressBar(
                    value: total == 0 ? 0 : completed / total,
                    valueColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    height: 7,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statPill(
                        icon: Icons.check_circle_outline,
                        label: '$completed done',
                      ),
                      _statPill(
                        icon: Icons.hourglass_empty,
                        label: '$remaining left',
                      ),
                      _statPill(
                        icon: Icons.category_outlined,
                        label: '$categories tracks',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < roadmap.steps.length; i++)
              RoadmapStepTile(
                step: roadmap.steps[i],
                isLast: i == roadmap.steps.length - 1,
                isUpNext:
                    roadmap.steps[i].id == upNext.id &&
                    upNext.status != RoadmapStepStatus.done,
                onChat: () => _openChat(roadmap.steps[i]),
                onSkillCheck: () => _openSkillCheck(roadmap.steps[i]),
              ),
          ],
        );
    }
  }

  Widget _statPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
