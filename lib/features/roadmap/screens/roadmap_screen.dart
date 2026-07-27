import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/theme/app_colors.dart';
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

  Future<void> _markDone(RoadmapProvider roadmap, int stepId) async {
    HapticFeedback.lightImpact();
    final userId = _userId;
    if (userId != null) await roadmap.markDone(userId, stepId);
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = context.watch<RoadmapProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your roadmap')),
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
            children: const [
              SizedBox(height: 100),
              Icon(Icons.map_outlined, size: 40, color: AppColors.textMuted),
              SizedBox(height: 14),
              Text(
                'Set a career goal on your profile\nto generate a roadmap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          );
        }

        final completed = roadmap.steps.where((s) => s.status == RoadmapStepStatus.done).length;
        final upNext = roadmap.steps.firstWhere(
          (s) => s.status != RoadmapStepStatus.done,
          orElse: () => roadmap.steps.first,
        );

        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed of ${roadmap.steps.length} steps complete',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${((completed / roadmap.steps.length) * 100).round()}%',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.indigo, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedProgressBar(
              value: roadmap.steps.isEmpty ? 0 : completed / roadmap.steps.length,
              valueColor: AppColors.indigo,
              backgroundColor: AppColors.border,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < roadmap.steps.length; i++)
              RoadmapStepTile(
                step: roadmap.steps[i],
                isLast: i == roadmap.steps.length - 1,
                isPending: roadmap.pendingStepIds.contains(roadmap.steps[i].id),
                isUpNext: roadmap.steps[i].id == upNext.id && upNext.status != RoadmapStepStatus.done,
                onMarkDone: () => _markDone(roadmap, roadmap.steps[i].id),
              ),
          ],
        );
    }
  }
}
