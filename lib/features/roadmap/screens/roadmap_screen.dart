import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
  bool _hideCompleted = false;

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
    final passed = await context.push<bool>(
      '/roadmap/skill/${step.skillId}/skill-check',
      extra: step.skillName,
    );
    if (passed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roadmap = context.watch<RoadmapProvider>();

    return Scaffold(
      backgroundColor: p.surface0,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: p.surface0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Your Roadmap',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            _buildSliverBody(context, p, roadmap),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody(
    BuildContext context,
    AppPalette p,
    RoadmapProvider roadmap,
  ) {
    switch (roadmap.state) {
      case RoadmapLoadState.initial:
      case RoadmapLoadState.loading:
        return const SliverFillRemaining(
          child: LoadingView(key: ValueKey('loading')),
        );

      case RoadmapLoadState.error:
        return SliverFillRemaining(
          child: ErrorView(
            key: const ValueKey('error'),
            message: roadmap.errorMessage ?? 'Something went wrong.',
            onRetry: _load,
          ),
        );

      case RoadmapLoadState.loaded:
        if (roadmap.steps.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.indigoLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_outlined, size: 32, color: p.indigo),
                ),
                const SizedBox(height: 16),
                Text(
                  'No roadmap active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set a career goal to generate your personalized path.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: p.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => context.push('/profile/career-goal'),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text(
                    'Set career goal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
        final upNext = remaining == 0
            ? null
            : roadmap.steps.firstWhere(
                (s) => s.status != RoadmapStepStatus.done,
              );

        final visibleSteps = _hideCompleted
            ? roadmap.steps
                  .where((s) => s.status != RoadmapStepStatus.done)
                  .toList()
            : roadmap.steps;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.indigo,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: p.indigo.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                          padding: const EdgeInsets.only(bottom: 4),
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
                    const SizedBox(height: 12),
                    AnimatedProgressBar(
                      value: total == 0 ? 0 : completed / total,
                      valueColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      height: 6,
                    ),
                    const SizedBox(height: 14),
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

              if (upNext != null) ...[
                const SizedBox(height: 16),
                _UpNextCard(
                  step: upNext,
                  onChat: () => _openChat(upNext),
                  onSkillCheck: () => _openSkillCheck(upNext),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Text(
                    'ALL STEPS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (completed > 0)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _hideCompleted = !_hideCompleted);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hideCompleted
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 13,
                              color: p.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _hideCompleted
                                  ? 'Show completed'
                                  : 'Hide completed',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              for (int i = 0; i < visibleSteps.length; i++)
                RoadmapStepTile(
                  key: ValueKey(visibleSteps[i].id),
                  step: visibleSteps[i],
                  isLast: i == visibleSteps.length - 1,
                  isUpNext: upNext != null && visibleSteps[i].id == upNext.id,
                  onChat: () => _openChat(visibleSteps[i]),
                  onSkillCheck: () => _openSkillCheck(visibleSteps[i]),
                ),
            ]),
          ),
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

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.step,
    required this.onChat,
    required this.onSkillCheck,
  });

  final RoadmapStep step;
  final VoidCallback onChat;
  final VoidCallback onSkillCheck;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.indigoLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.indigo.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.indigoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_rounded, color: p.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: p.indigo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.skillName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.textPrimary,
                            side: BorderSide(color: p.border),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: p.surface0,
                          ),
                          onPressed: onChat,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 14),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Chat with Tutor',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: p.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 0,
                          ),
                          onPressed: onSkillCheck,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_outlined, size: 14),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Skill Check',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
