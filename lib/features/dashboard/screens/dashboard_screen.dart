import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../projects/data/membership_alert_service.dart';
import '../providers/dashboard_ai_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/gamification_provider.dart';
import '../widgets/achievements_section.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/project_card.dart';
import '../widgets/streak_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _alertService = MembershipAlertService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();
    final dashboardAi = context.read<DashboardAiProvider>();
    final gamification = context.read<GamificationProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    await dashboard.load(userId);
    unawaited(dashboardAi.load(userId));
    unawaited(gamification.load(userId));

    final changes = await _alertService.checkForChanges(userId);
    if (!mounted) return;
    // Capture ScaffoldMessenger before any potential loop context usage
    final messenger = ScaffoldMessenger.of(context);
    for (final c in changes) {
      final verb = c.status == MemberStatus.accepted ? 'accepted' : 'rejected';
      messenger.showSnackBar(
        SnackBar(
          content: Text('Your request to join "${c.projectName}" was $verb.'),
        ),
      );
    }
  }

  Future<void> _generateSummary() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<DashboardAiProvider>().generate(userId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: colors.indigoLight,
              child: Icon(Icons.person, size: 16, color: colors.indigo),
            ),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: Builder(
          builder: (context) {
            switch (dashboard.state) {
              case DashboardLoadState.initial:
              case DashboardLoadState.loading:
                return const LoadingView();
              case DashboardLoadState.error:
                return ErrorView(
                  message: dashboard.errorMessage ?? 'Something went wrong.',
                  onRetry: _load,
                );
              case DashboardLoadState.loaded:
                final data = dashboard.data!;
                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Text(
                      '${_greeting()}${user != null ? ', ${user.name.split(' ').first}' : ''}',
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    const SizedBox(height: 12),

                    // Career progress card (mockup: .ind-card)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/profile/career-goal'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.indigo,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ProgressRing(percent: data.careerProgressPercent),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.branchName != null
                                        ? '${data.careerRoleName} · ${data.branchName}'
                                        : (data.careerRoleName ??
                                              'No career goal set'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    data.careerRoleName == null
                                        ? 'Tap to choose a career goal'
                                        : 'Career progress toward this role',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Roadmap completion
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Roadmap progress',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${data.roadmapCompletedSteps}/${data.roadmapTotalSteps} steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedProgressBar(
                              value: data.roadmapProgress,
                              backgroundColor: colors.border,
                              valueColor: colors.indigo,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => context.go('/roadmap'),
                                child: const Text('View full roadmap  →'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // AI-generated "what's next" summary (replaces the old
                    // static "next up" skill list).
                    Consumer<DashboardAiProvider>(
                      builder: (context, ai, _) => AiSummaryCard(
                        provider: ai,
                        onRefresh: _generateSummary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Gamification: streak + achievements
                    Consumer<GamificationProvider>(
                      builder: (context, gami, _) {
                        if (gami.state != GamificationLoadState.loaded) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (gami.streak != null) ...[
                              StreakCard(streak: gami.streak!),
                              const SizedBox(height: 18),
                            ],
                            AchievementsSection(
                              achievements: gami.achievements,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Active projects
                    SectionHeader(
                      label: 'ACTIVE PROJECTS',
                      icon: Icons.groups_outlined,
                      trailing: TextButton(
                        onPressed: () => context.go('/projects'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'See all',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.activeProjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.surface1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              size: 18,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No active projects yet — browse open projects to join one.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...data.activeProjects.map(
                        (proj) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ProjectCard(project: proj),
                        ),
                      ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
