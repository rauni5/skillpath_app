import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../../career/providers/career_provider.dart';
import '../../career/widgets/role_card.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';

class OnboardingGoalStep extends StatefulWidget {
  const OnboardingGoalStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingGoalStep> createState() => _OnboardingGoalStepState();
}

class _OnboardingGoalStepState extends State<OnboardingGoalStep> {
  int? _selectedRoleId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CareerProvider>().loadRoles();
    });
  }

  Future<void> _select(int roleId) async {
    if (_isProcessing) return;
    HapticFeedback.selectionClick();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    // Show the glow immediately, and hold for a beat before the network
    // call — otherwise a fast response can move on to the next onboarding
    // step before the highlight ever gets painted.
    setState(() {
      _isProcessing = true;
      _selectedRoleId = roleId;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final career = context.read<CareerProvider>();
    final ok = await career.setGoal(userId, roleId);
    if (!mounted) return;
    if (ok) {
      widget.onContinue();
    } else {
      setState(() {
        _isProcessing = false;
        _selectedRoleId = null;
      });
      if (career.errorMessage != null) {
        showErrorDialog(context, career.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final career = context.watch<CareerProvider>();
    final p = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where are you headed?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick a target role — we'll build a dependency-ordered roadmap and show you exactly what's missing.",
            style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: career.rolesState == CareerLoadState.loading
                ? const LoadingView()
                : career.rolesState == CareerLoadState.error
                ? ErrorView(
                    message:
                        career.errorMessage ?? 'Could not load career roles.',
                    onRetry: () => context.read<CareerProvider>().loadRoles(),
                  )
                : ListView(
                    children: [
                      for (final role in career.roles)
                        RoleCard(
                          role: role,
                          isSelected: _selectedRoleId == role.id,
                          onTap: _isProcessing || career.isSubmitting
                              ? () {}
                              : () => _select(role.id),
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
