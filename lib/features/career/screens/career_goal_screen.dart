import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../roadmap/providers/roadmap_provider.dart';
import '../providers/career_provider.dart';
import '../widgets/gap_summary_card.dart';
import '../widgets/role_card.dart';

class CareerGoalScreen extends StatefulWidget {
  const CareerGoalScreen({super.key});

  @override
  State<CareerGoalScreen> createState() => _CareerGoalScreenState();
}

class _CareerGoalScreenState extends State<CareerGoalScreen> {
  bool _changingGoal = false;

  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = _userId;
    if (userId != null) context.read<CareerProvider>().loadAll(userId);
  }

  Future<void> _selectRole(int roleId) async {
    HapticFeedback.selectionClick();
    final userId = _userId;
    if (userId == null) return;
    final career = context.read<CareerProvider>();
    final ok = await career.setGoal(userId, roleId);
    if (ok) {
      setState(() => _changingGoal = false);
      // Career goal changed -> the backend already rebuilt the roadmap for the
      // new role. Refresh both providers now so Dashboard/Roadmap screens show
      // the new data as soon as the user navigates there, instead of stale
      // cached state from the previous role.
      if (mounted) {
        context.read<DashboardProvider>().load(userId);
        context.read<RoadmapProvider>().load(userId);
      }
    } else if (mounted && career.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(career.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final career = context.watch<CareerProvider>();
    final loading =
        career.gapState == CareerLoadState.loading ||
        career.rolesState == CareerLoadState.loading;
    final hasError =
        career.gapState == CareerLoadState.error &&
        career.rolesState == CareerLoadState.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Career goal')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: loading && career.roles.isEmpty
            ? const LoadingView(key: ValueKey('loading'))
            : hasError
            ? ErrorView(
                key: const ValueKey('error'),
                message: career.errorMessage ?? 'Something went wrong.',
                onRetry: _load,
              )
            : RefreshIndicator(
                key: ValueKey(_changingGoal),
                onRefresh: () async => _load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    if (!_changingGoal) ...[
                      GapSummaryCard(gap: career.gap),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => setState(() => _changingGoal = true),
                        icon: Icon(
                          career.gap.hasGoalSet
                              ? Icons.swap_horiz
                              : Icons.flag_outlined,
                          size: 18,
                        ),
                        label: Text(
                          career.gap.hasGoalSet
                              ? 'Change career goal'
                              : 'Choose a career goal',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      const SectionHeader(
                        label: 'CHOOSE A ROLE',
                        icon: Icons.explore_outlined,
                      ),
                      const SizedBox(height: 10),
                      for (final role in career.roles)
                        RoleCard(
                          role: role,
                          isSelected: career.gap.careerRoleName == role.name,
                          onTap: career.isSubmitting
                              ? () {}
                              : () => _selectRole(role.id),
                        ),
                      if (career.isSubmitting)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.indigo,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _changingGoal = false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
