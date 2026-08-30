import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../career/providers/career_provider.dart';
import '../../career/widgets/gap_summary_card.dart';

class OnboardingSummaryStep extends StatefulWidget {
  const OnboardingSummaryStep({super.key});

  @override
  State<OnboardingSummaryStep> createState() => _OnboardingSummaryStepState();
}

class _OnboardingSummaryStepState extends State<OnboardingSummaryStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) context.read<CareerProvider>().loadGap(userId);
      HapticFeedback.mediumImpact();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.greenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: p.green, size: 34),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're all set",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Here's where you stand. Your roadmap is already generated — check the Roadmap tab any time.",
            style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: career.gapState == CareerLoadState.loading
                ? const LoadingView()
                : SingleChildScrollView(child: GapSummaryCard(gap: career.gap)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                context.read<AuthProvider>().markOnboardingComplete(),
            child: const Text('Go to dashboard'),
          ),
        ],
      ),
    );
  }
}
