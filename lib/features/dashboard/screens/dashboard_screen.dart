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
import '../../notifications/providers/notifications_provider.dart';
import '../widgets/achievement_badge.dart';
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
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await Future.wait([
      context.read<DashboardProvider>().load(userId),
      context.read<NotificationsProvider>().refreshUnreadCount(userId),
    ]);
    unawaited(_loadAiSummary(userId));
    unawaited(_loadGamification(userId));
    final changes = await _alertService.checkForChanges(userId);
    if (!mounted) return;
    for (final c in changes) {
      final verb = c.status == MemberStatus.accepted ? 'accepted' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your request to join "${c.projectName}" was $verb.'),
        ),
      );
    }
  }

  Future<void> _loadAiSummary(int userId) async {
    final ai = context.read<DashboardAiProvider>();
    await ai.load(userId);
    // `load()` only fetches a previously-generated summary — it never
    // calls the AI itself. If nothing's ever been generated for this user,
    // that used to leave the card sitting on "tap refresh" until the user
    // did exactly that. Generate one automatically the first time instead,
    // so there's always something to show without manual action.
    if (ai.state == SummaryLoadState.empty && mounted) {
      await ai.generate(userId);
    }
  }

  Future<void> _loadGamification(int userId) async {
    final gami = context.read<GamificationProvider>();
    await gami.load(userId);
    // A cold backend (or a dropped first request right after sign-in, while
    // the Firebase token is still being attached) can make this very first
    // call fail even though the rest of the dashboard loaded fine. Retry
    // once automatically rather than leaving the streak/achievements
    // sections silently empty until the user manually pulls to refresh.
    if (gami.state == GamificationLoadState.error && mounted) {
      await gami.load(userId);
    }
    if (mounted) _showAchievementToasts();
  }

  void _showAchievementToasts() {
    final gami = context.read<GamificationProvider>();
    final newlyUnlocked = gami.newlyUnlocked;
    if (newlyUnlocked.isEmpty) return;
    for (final achievement in newlyUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Achievement unlocked: ${achievement.title}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => showAchievementDetail(context, achievement),
          ),
        ),
      );
    }
    gami.clearNewlyUnlocked();
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
          Consumer<NotificationsProvider>(
            builder: (context, notifications, _) => IconButton(
              icon: Badge(
                isLabelVisible: notifications.unreadCount > 0,
                label: Text(
                  notifications.unreadCount > 9
                      ? '9+'
                      : '${notifications.unreadCount}',
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // 1. Greeting Header
                    Text(
                      '${_greeting()}${user != null ? ', ${user.name.split(' ').first}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Daily Streak Widget
                    Consumer<GamificationProvider>(
                      builder: (context, gami, _) {
                        if (gami.state == GamificationLoadState.error) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _InlineRetryRow(
                              message: "Couldn't load your streak.",
                              onRetry: () {
                                final userId = context
                                    .read<AuthProvider>()
                                    .currentUser
                                    ?.id;
                                if (userId != null) gami.load(userId);
                              },
                            ),
                          );
                        }
                        if (gami.state != GamificationLoadState.loaded ||
                            gami.streak == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: StreakCard(
                            streak: gami.streak!,
                            onTap: () => context.go('/roadmap'),
                          ),
                        );
                      },
                    ),

                    // 3. Career Goal Banner
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/profile/career-goal'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.indigo,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.indigo.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    data.careerRoleName == null
                                        ? 'Tap to choose a career goal'
                                        : 'Skills mastered: ${data.knownSkillCount} of ${data.requiredSkillCount}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Learning Path Steps
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.indigoLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.alt_route_rounded,
                                  size: 20,
                                  color: colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Learning Plan',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Your personalized path to this role',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.indigoLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${data.roadmapCompletedSteps}/${data.roadmapTotalSteps} steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colors.indigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedProgressBar(
                            value: data.roadmapProgress,
                            backgroundColor: colors.border,
                            valueColor: colors.green,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => context.go('/roadmap'),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View full roadmap',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: colors.indigo,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. AI Recommendations
                    Consumer<DashboardAiProvider>(
                      builder: (context, ai, _) => AiSummaryCard(
                        provider: ai,
                        onRefresh: _generateSummary,
                        onViewAssistant: () => context.go('/assistant'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 6. Achievements Section
                    Consumer<GamificationProvider>(
                      builder: (context, gami, _) {
                        if (gami.state == GamificationLoadState.error) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _InlineRetryRow(
                              message: "Couldn't load your achievements.",
                              onRetry: () {
                                final userId = context
                                    .read<AuthProvider>()
                                    .currentUser
                                    ?.id;
                                if (userId != null) gami.load(userId);
                              },
                            ),
                          );
                        }
                        if (gami.state != GamificationLoadState.loaded ||
                            gami.achievements.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: AchievementsSection(
                            achievements: gami.achievements,
                          ),
                        );
                      },
                    ),

                    // 7. Active Projects Section
                    SectionHeader(
                      label: 'ACTIVE PROJECTS',
                      icon: Icons.groups_outlined,
                      trailing: TextButton(
                        onPressed: () => context.go('/projects/mine'),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.5),
                          ),
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
                          child: ProjectCard(
                            project: proj,
                            onTap: () {
                              final userId = context
                                  .read<AuthProvider>()
                                  .currentUser
                                  ?.id;
                              final isMine =
                                  userId != null && userId == proj.ownerId;

                              context.push(
                                isMine
                                    ? '/projects/mine/${proj.id}'
                                    : '/projects/${proj.id}',
                                extra: {'name': proj.name, 'isMember': true},
                              );
                            },
                          ),
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

/// Small inline "couldn't load — retry" affordance for a section that
/// failed independently of the rest of the dashboard, so a failure never
/// just silently disappears with no way to recover short of a full
/// pull-to-refresh.
class _InlineRetryRow extends StatelessWidget {
  const _InlineRetryRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: p.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
