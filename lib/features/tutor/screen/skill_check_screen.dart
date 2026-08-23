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
    this.returnLabel = 'Back to Roadmap',
  });

  final int skillId;
  final String skillName;

  final String returnLabel;
  @override
  State<SkillCheckScreen> createState() => _SkillCheckScreenState();
}

class _SkillCheckScreenState extends State<SkillCheckScreen> {
  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    // Every visit to this screen starts from the landing state. Retakes
    // have no cooldown and the backend tracks no "in-progress" step status,
    // so there's nothing worth preserving between visits — starting fresh
    // each time is the simplest, least surprising behavior.
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
      appBar: AppBar(title: Text('Skill Check · ${widget.skillName}')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
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
        );
      case SkillCheckPhase.submitting:
        return const _BusyView(
          key: ValueKey('submitting'),
          message: 'Grading your answers…',
        );
      case SkillCheckPhase.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: check.errorMessage ?? 'Something went wrong.',
          onRetry: check.attemptId == null ? _start : _submit,
        );
      case SkillCheckPhase.inProgress:
        return _QuizView(key: const ValueKey('inProgress'), onSubmit: _submit);
      case SkillCheckPhase.result:
        return _ResultView(
          key: const ValueKey('result'),
          skillId: widget.skillId,
          skillName: widget.skillName,
          returnLabel: widget.returnLabel,
        );
    }
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: p.indigo, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: p.textMuted, fontSize: 13)),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.indigoLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.indigo.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.quiz_outlined, color: p.indigo, size: 28),
              const SizedBox(height: 12),
              Text(
                'Skill check: $skillName',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _bullet(p, '5 AI-generated multiple-choice questions'),
              _bullet(p, 'Scored out of 20, 4 points per question'),
              _bullet(
                p,
                '10+ passes as Beginner, 15+ Intermediate, 20 Advanced',
              ),
              _bullet(p, 'A pass marks this step done at the level you earned'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: p.indigo,
            minimumSize: const Size.fromHeight(46),
          ),
          onPressed: onStart,
          child: const Text('Start Skill Check'),
        ),
      ],
    );
  }

  Widget _bullet(AppPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: p.indigo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
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
          Text(
            'Question ${check.currentIndex + 1} of $total',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            value: (check.currentIndex + 1) / total,
            valueColor: p.indigo,
            backgroundColor: p.border,
            height: 5,
          ),
          const SizedBox(height: 20),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final isSelected = selected == i;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      context.read<SkillCheckProvider>().selectAnswer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? p.indigoLight : p.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? p.indigo : p.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? p.indigo : p.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            question.options[i],
                            style: TextStyle(
                              fontSize: 13.5,
                              color: p.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(color: p.border),
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
                    minimumSize: const Size.fromHeight(46),
                    disabledBackgroundColor: p.border,
                  ),
                  onPressed: selected == null
                      ? null
                      : check.isLastQuestion
                      ? (check.answeredCount == total ? onSubmit : null)
                      : () => context.read<SkillCheckProvider>().goNext(),
                  child: Text(check.isLastQuestion ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.skillId,
    required this.skillName,
    required this.returnLabel,
  });

  final int skillId;
  final String skillName;
  final String returnLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final check = context.watch<SkillCheckProvider>();
    final result = check.result;
    if (result == null) return const SizedBox.shrink();

    final passed = result.passed;
    final scoreColor = passed ? p.green : p.amber;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed ? p.greenLight : p.amberLight,
                  border: Border.all(color: scoreColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${result.score}/${result.maxScore}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'Nice work!' : 'Not quite there yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? 'You earned ${result.proficiency?.label ?? 'a passing'} level in $skillName.'
                    : 'You need at least a Beginner-level score to pass. Give it another go whenever you\'re ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textSecondary,
                  height: 1.4,
                ),
              ),
              if (passed && result.proficiency != null) ...[
                const SizedBox(height: 12),
                _ProficiencyBadge(proficiency: result.proficiency!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'QUESTION BREAKDOWN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: p.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < result.correctness.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  result.correctness[i] ? Icons.check_circle : Icons.cancel,
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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: p.border),
                ),
                onPressed: () => context.read<SkillCheckProvider>().reset(),
                child: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.indigo,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: () => context.pop(passed),
                child: Text(returnLabel),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: p.greenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.green.withValues(alpha: 0.4)),
      ),
      child: Text(
        proficiency.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: p.greenText,
        ),
      ),
    );
  }
}
