import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/models/branch_recommendation.dart';
import '../../../core/models/career_role.dart';
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
import '../widgets/specialization_card.dart';
import '../widgets/specialization_info_sheet.dart';

enum _ScreenMode { viewing, pickingRole, pickingBranch }

class CareerGoalScreen extends StatefulWidget {
  const CareerGoalScreen({super.key});

  @override
  State<CareerGoalScreen> createState() => _CareerGoalScreenState();
}

class _CareerGoalScreenState extends State<CareerGoalScreen> {
  _ScreenMode _mode = _ScreenMode.viewing;
  int? _pendingRoleId;
  String? _pendingRoleName;
  bool _isSwitchingBranchOnly = false;
  bool _isProcessingRoleTap = false;

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

  void _resetToViewing() {
    setState(() {
      _mode = _ScreenMode.viewing;
      _pendingRoleId = null;
      _pendingRoleName = null;
      _isSwitchingBranchOnly = false;
      _isProcessingRoleTap = false;
    });
  }

  /// A role was tapped from the role list. If it has specializations, show
  /// the picker; if not, set the goal immediately (unchanged behavior).
  Future<void> _onRoleTapped(CareerRole role) async {
    if (_isProcessingRoleTap) return;
    HapticFeedback.selectionClick();
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _isProcessingRoleTap = true;
      _pendingRoleId = role.id;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final career = context.read<CareerProvider>();
    await career.loadBranchesForRole(userId, role.id);
    if (!mounted) return;
    if (career.branches.isEmpty) {
      await _confirmGoal(role.id, null);
      if (mounted) setState(() => _isProcessingRoleTap = false);
    } else {
      setState(() {
        _pendingRoleName = role.name;
        _isSwitchingBranchOnly = false;
        _mode = _ScreenMode.pickingBranch;
        _isProcessingRoleTap = false;
      });
    }
  }

  /// "Change specialization" from the viewing state — same role, different specialization.
  Future<void> _startSwitchingBranch() async {
    HapticFeedback.selectionClick();
    final userId = _userId;
    final career = context.read<CareerProvider>();
    if (userId == null) return;
    final matches = career.roles.where(
      (r) => r.name == career.gap.careerRoleName,
    );
    final currentRole = matches.isEmpty ? null : matches.first;
    if (currentRole == null) return;
    await career.loadBranchesForRole(userId, currentRole.id);
    if (!mounted) return;
    setState(() {
      _pendingRoleId = currentRole.id;
      _pendingRoleName = currentRole.name;
      _isSwitchingBranchOnly = true;
      _mode = _ScreenMode.pickingBranch;
    });
  }

  Future<void> _onBranchTapped(int branchId) async {
    HapticFeedback.selectionClick();
    if (_isSwitchingBranchOnly) {
      await _confirmBranchSwitch(branchId);
    } else if (_pendingRoleId != null) {
      await _confirmGoal(_pendingRoleId!, branchId);
    }
  }

  Future<void> _confirmGoal(int roleId, int? branchId) async {
    final userId = _userId;
    if (userId == null) return;
    final career = context.read<CareerProvider>();
    final ok = await career.setGoal(userId, roleId, branchId: branchId);
    if (ok) {
      _resetToViewing();
      _refreshDependents(userId);
    } else if (mounted && career.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(career.errorMessage!)));
    }
  }

  Future<void> _confirmBranchSwitch(int branchId) async {
    final userId = _userId;
    if (userId == null) return;
    final career = context.read<CareerProvider>();
    final ok = await career.switchBranch(userId, branchId);
    if (ok) {
      _resetToViewing();
      _refreshDependents(userId);
    } else if (mounted && career.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(career.errorMessage!)));
    }
  }

  void _refreshDependents(int userId) {
    // Career goal/specialization changed -> the backend already rebuilt the
    // roadmap. Refresh Dashboard/Roadmap now so they show fresh data as soon
    // as the user navigates there, instead of stale cached state.
    if (!mounted) return;
    context.read<DashboardProvider>().load(userId);
    context.read<RoadmapProvider>().load(userId);
  }

  BranchRecommendation? _recommendationFor(
    CareerProvider career,
    int branchId,
  ) {
    final matches = career.branchRecommendations.where(
      (r) => r.branchId == branchId,
    );
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final career = context.watch<CareerProvider>();
    final loading =
        career.gapState == CareerLoadState.loading &&
        career.rolesState == CareerLoadState.loading;
    final hasError =
        career.gapState == CareerLoadState.error &&
        career.rolesState == CareerLoadState.error;

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(_mode))),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: loading && career.roles.isEmpty
              ? const LoadingView(key: ValueKey('loading'))
              : hasError
              ? ErrorView(
                  key: const ValueKey('error'),
                  message: career.errorMessage ?? 'Something went wrong.',
                  onRetry: _load,
                )
              : _buildContent(context, p, career),
        ),
      ),
    );
  }

  String _titleFor(_ScreenMode mode) {
    switch (mode) {
      case _ScreenMode.viewing:
        return 'Career goal';
      case _ScreenMode.pickingRole:
        return 'Choose a role';
      case _ScreenMode.pickingBranch:
        return _isSwitchingBranchOnly
            ? 'Change specialization'
            : 'Choose a specialization';
    }
  }

  Widget _buildContent(
    BuildContext context,
    AppPalette p,
    CareerProvider career,
  ) {
    switch (_mode) {
      case _ScreenMode.viewing:
        return RefreshIndicator(
          key: const ValueKey('viewing'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              GapSummaryCard(
                gap: career.gap,
                onTapSpecializationInfo: () =>
                    showSpecializationInfoSheet(context),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    setState(() => _mode = _ScreenMode.pickingRole),
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
              if (career.gap.hasGoalSet && career.gap.branchId != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.alt_route, size: 16, color: p.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'SPECIALIZATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: p.textMuted,
                      ),
                      onPressed: () => showSpecializationInfoSheet(context),
                    ),
                  ],
                ),
                Text(
                  "You're on the ${career.gap.branchName} track within ${career.gap.careerRoleName}. "
                  'Switching keeps your role, just changes which skills your roadmap targets.',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _startSwitchingBranch,
                  icon: const Icon(Icons.sync_alt, size: 18),
                  label: const Text('Change specialization'),
                ),
              ],
            ],
          ),
        );

      case _ScreenMode.pickingRole:
        return ListView(
          key: const ValueKey('pickingRole'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const SectionHeader(
              label: 'CHOOSE A ROLE',
              icon: Icons.explore_outlined,
            ),
            const SizedBox(height: 10),
            for (final role in career.roles)
              RoleCard(
                role: role,
                isSelected:
                    career.gap.careerRoleName == role.name ||
                    _pendingRoleId == role.id,
                onTap:
                    _isProcessingRoleTap ||
                        career.isSubmitting ||
                        career.branchesState == CareerLoadState.loading
                    ? () {}
                    : () => _onRoleTapped(role),
              ),
            if (career.isSubmitting ||
                career.branchesState == CareerLoadState.loading)
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
            TextButton(onPressed: _resetToViewing, child: const Text('Cancel')),
          ],
        );

      case _ScreenMode.pickingBranch:
        final topScore = career.branchRecommendations.isEmpty
            ? null
            : career.branchRecommendations
                  .map((r) => r.matchScore)
                  .reduce((a, b) => a > b ? a : b);
        return ListView(
          key: const ValueKey('pickingBranch'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: p.indigoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: p.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_pendingRoleName has multiple specializations — different technology tracks that '
                      'lead to the same role. Each one below shows what you already know and what '
                      "you'd still need to learn.",
                      style: TextStyle(
                        fontSize: 12,
                        color: p.indigo,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final branch in career.branches)
              SpecializationCard(
                branch: branch,
                recommendation: _recommendationFor(career, branch.id),
                isTopMatch:
                    topScore != null &&
                    career.scoreForBranch(branch.id) == topScore,
                onTap: career.isSubmitting
                    ? () {}
                    : () => _onBranchTapped(branch.id),
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
              onPressed: () => setState(
                () => _mode = _isSwitchingBranchOnly
                    ? _ScreenMode.viewing
                    : _ScreenMode.pickingRole,
              ),
              child: const Text('Back'),
            ),
          ],
        );
    }
  }
}
