import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/skill_check_provider.dart';

class SkillCheckScreen extends StatefulWidget {
  const SkillCheckScreen({
    super.key,
    required this.skillId,
    required this.skillName,
  });

  final int skillId;
  final String skillName;

  @override
  State<SkillCheckScreen> createState() => _SkillCheckScreenState();
}

class _SkillCheckScreenState extends State<SkillCheckScreen> {
  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillCheckProvider>().reset();
    });
  }

  Future<void> _start() async {
    final userId = _userId;
    if (userId == null) return;
    await context.read<SkillCheckProvider>().start(userId, widget.skillId);
  }

  Future<void> _submit() async {
    final userId = _userId;
    if (userId == null) return;
    HapticFeedback.lightImpact();
    await context.read<SkillCheckProvider>().submit(userId, widget.skillId);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final check = context.watch<SkillCheckProvider>();

    return Scaffold(
      backgroundColor: p.surface0,
      appBar: AppBar(
        title: Text('Skill Check · ${widget.skillName}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildBody(context, p, check),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    SkillCheckProvider check,
  ) {
    switch (check.phase) {
      case SkillCheckPhase.notStarted:
        return _NotStartedView(
          key: const ValueKey('notStarted'),
          skillName: widget.skillName,
          onStart: _start,
        );
      case SkillCheckPhase.generating:
        return const _BusyView(
          key: ValueKey('generating'),
          message: 'Generating your quiz…',
          icon: Icons.auto_awesome_outlined,
        );
      case SkillCheckPhase.submitting:
        return const _BusyView(
          key: ValueKey('submitting'),
          message: 'Grading your answers…',
          icon: Icons.fact_check_outlined,
        );
      case SkillCheckPhase.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: check.errorMessage ?? 'Something went wrong.',
          onRetry: check.attemptId == null ? _start : _submit,
        );
      case SkillCheckPhase.inProgress:
        return _QuizView(
          key: ValueKey('question-${check.currentIndex}'),
          onSubmit: _submit,
        );
      case SkillCheckPhase.result:
        return _ResultView(
          key: const ValueKey('result'),
          skillId: widget.skillId,
          skillName: widget.skillName,
        );
    }
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({super.key, required this.message, required this.icon});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingIcon(icon: icon, color: p.indigo),
          const SizedBox(height: 20),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: p.indigo, strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: p.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.12);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: widget.color, size: 30),
      ),
    );
  }
}

class _NotStartedView extends StatelessWidget {
  const _NotStartedView({
    super.key,
    required this.skillName,
    required this.onStart,
  });

  final String skillName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.indigoLight, p.indigoLight.withValues(alpha: 0.4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.indigo.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: p.indigo,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: p.indigo.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Skill check: $skillName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(
                p,
                Icons.help_outline_rounded,
                '5 AI-generated multiple-choice questions',
              ),
              _infoRow(
                p,
                Icons.grade_outlined,
                'Scored out of 20, 4 points per question',
              ),
              _infoRow(
                p,
                Icons.trending_up_rounded,
                '10+ passes as Beginner, 15+ Intermediate, 20 Advanced',
              ),
              _infoRow(
                p,
                Icons.flag_outlined,
                'A pass marks this step done at the level you earned',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: p.indigo,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'Start Skill Check',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(AppPalette p, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: p.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({super.key, required this.onSubmit});

  final VoidCallback onSubmit;

  static const _optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final check = context.watch<SkillCheckProvider>();
    final question = check.questions[check.currentIndex];
    final total = check.questions.length;
    final selected = check.answers[check.currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${check.currentIndex + 1} of $total',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${check.answeredCount}/$total answered',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: p.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedProgressBar(
            value: (check.currentIndex + 1) / total,
            valueColor: p.indigo,
            backgroundColor: p.border,
            height: 6,
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final isSelected = selected == i;
                return _OptionTile(
                  label: _optionLabels[i % _optionLabels.length],
                  text: question.options[i],
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<SkillCheckProvider>().selectAnswer(i);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (check.currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: p.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        context.read<SkillCheckProvider>().goBack(),
                    child: const Text('Back'),
                  ),
                ),
              if (check.currentIndex > 0) const SizedBox(width: 10),
              Expanded(
                flex: check.currentIndex > 0 ? 1 : 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.indigo,
                    minimumSize: const Size.fromHeight(48),
                    disabledBackgroundColor: p.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: selected == null
                      ? null
                      : check.isLastQuestion
                      ? (check.answeredCount == total ? onSubmit : null)
                      : () => context.read<SkillCheckProvider>().goNext(),
                  child: Text(
                    check.isLastQuestion ? 'Submit' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? p.indigoLight : p.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? p.indigo : p.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: p.indigo.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? p.indigo
                      : p.border.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : p.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Font weight is now constant regardless of selection. It
              // used to jump w400 -> w600 on select, which changes glyph
              // widths and reflows the whole line - that was the
              // "text moves when selected" bug. Color alone now carries
              // the selected/unselected distinction here.
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isSelected ? p.textPrimary : p.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fixed-width slot that's always in the tree - only its
              // opacity animates. Previously the checkmark Icon only
              // existed in the widget tree when isSelected was true,
              // which shrank the Expanded text's available width the
              // instant you selected it, causing the same reflow shift.
              SizedBox(
                width: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isSelected ? 1 : 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: p.indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  const _ResultView({
    super.key,
    required this.skillId,
    required this.skillName,
  });

  final int skillId;
  final String skillName;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final check = context.watch<SkillCheckProvider>();
    final result = check.result;
    if (result == null) return const SizedBox.shrink();

    final passed = result.passed;
    final scoreColor = passed ? p.green : p.amber;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: passed ? p.greenLight : p.amberLight,
                    border: Border.all(color: scoreColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: result.score),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedScore, _) => Text(
                        '$animatedScore/${result.maxScore}',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Icon(
                passed
                    ? Icons.celebration_rounded
                    : Icons.sentiment_neutral_rounded,
                color: scoreColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                passed ? 'Nice work!' : 'Not quite there yet',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? 'You earned ${result.proficiency?.label ?? 'a passing'} level in ${widget.skillName}.'
                    : 'You need at least a Beginner-level score to pass. Give it another go whenever you\'re ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textSecondary,
                  height: 1.4,
                ),
              ),
              if (passed && result.proficiency != null) ...[
                const SizedBox(height: 14),
                _ProficiencyBadge(proficiency: result.proficiency!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'QUESTION BREAKDOWN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: p.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < result.correctness.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: result.correctness[i] ? p.greenLight : p.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: result.correctness[i]
                    ? p.green.withValues(alpha: 0.3)
                    : p.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.correctness[i]
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 18,
                  color: result.correctness[i] ? p.green : p.red,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    check.questions.length > i
                        ? check.questions[i].question
                        : 'Question ${i + 1}',
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: p.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.read<SkillCheckProvider>().reset(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.indigo,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.pop(passed),
                child: Text("Return"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProficiencyBadge extends StatelessWidget {
  const _ProficiencyBadge({required this.proficiency});

  final SkillProficiency proficiency;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: p.greenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 14, color: p.greenText),
          const SizedBox(width: 6),
          Text(
            proficiency.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: p.greenText,
            ),
          ),
        ],
      ),
    );
  }
}
