import 'package:flutter/material.dart';
import 'package:skillpath_app/core/models/skill.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/theme/app_palette.dart';

class RoadmapStepTile extends StatefulWidget {
  const RoadmapStepTile({
    super.key,
    required this.step,
    required this.isLast,
    required this.isUpNext,
    required this.onChat,
    required this.onSkillCheck,
  });

  final RoadmapStep step;
  final bool isLast;
  final bool isUpNext;
  final VoidCallback onChat;
  final VoidCallback onSkillCheck;

  @override
  State<RoadmapStepTile> createState() => _RoadmapStepTileState();
}

class _RoadmapStepTileState extends State<RoadmapStepTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final step = widget.step;
    final isDone = step.status == RoadmapStepStatus.done;
    final isUpNext = widget.isUpNext && !isDone;

    final dotColor = isDone ? p.green : (isUpNext ? p.indigo : p.border);

    final cardColor = isUpNext
        ? p.indigoLight
        : isDone
        ? p.surface1
        : p.surface2;
    final cardBorder = isUpNext ? p.indigo.withValues(alpha: 0.35) : p.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connector line + dot
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                width: isUpNext ? 20 : 16,
                height: isUpNext ? 20 : 16,
                margin: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isDone
                      ? null
                      : Border.all(color: p.border, width: 1.5),
                  boxShadow: isUpNext
                      ? [
                          BoxShadow(
                            color: p.indigo.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          key: ValueKey('done'),
                          size: 11,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
              if (!widget.isLast)
                Expanded(child: Container(width: 2, color: p.border)),
            ],
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cardBorder,
                      width: isUpNext ? 1.25 : 0.75,
                    ),
                  ),
                  child: ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Step ${step.stepOrder}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: p.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isUpNext) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.indigo,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'UP NEXT',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isDone) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: p.green,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      step.skillName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDone
                                            ? p.textMuted
                                            : p.textPrimary,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          step.skillCategory.icon,
                                          size: 12,
                                          color: p.indigo,
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.indigoLight,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            step.skillCategory.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: p.indigo,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                                color: p.textMuted,
                              ),
                            ],
                          ),
                          if (_expanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                isDone && step.completedAt != null
                                    ? 'Completed ${_formatDate(step.completedAt!)}'
                                    : 'Part of the ${step.skillCategory.label} track — complete the steps above it first if this feels out of order.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          if (!isDone) ...[
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: widget.onChat,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
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
                                        backgroundColor: isUpNext
                                            ? p.indigo
                                            : p.surface2,
                                        foregroundColor: isUpNext
                                            ? Colors.white
                                            : p.textPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: isUpNext
                                            ? null
                                            : BorderSide(color: p.border),
                                        elevation: 0,
                                      ),
                                      onPressed: widget.onSkillCheck,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.quiz_outlined,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
