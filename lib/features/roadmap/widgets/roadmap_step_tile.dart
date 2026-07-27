import 'package:flutter/material.dart';
import 'package:skillpath_app/core/models/skill.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/theme/app_colors.dart';

/// A single roadmap step. Tap the row to expand it and see its category;
/// the very next incomplete step is visually called out as "Up next" so
/// it's always obvious what to tackle. Completing a step animates the dot
/// filling in rather than snapping instantly.
class RoadmapStepTile extends StatefulWidget {
  const RoadmapStepTile({
    super.key,
    required this.step,
    required this.isLast,
    required this.isPending,
    required this.isUpNext,
    required this.onMarkDone,
  });

  final RoadmapStep step;
  final bool isLast;
  final bool isPending;
  final bool isUpNext;
  final VoidCallback onMarkDone;

  @override
  State<RoadmapStepTile> createState() => _RoadmapStepTileState();
}

class _RoadmapStepTileState extends State<RoadmapStepTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final isDone = step.status == RoadmapStepStatus.done;

    final dotColor = isDone
        ? AppColors.green
        : widget.isUpNext
        ? AppColors.indigo
        : AppColors.border;

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
                width: widget.isUpNext && !isDone ? 20 : 16,
                height: widget.isUpNext && !isDone ? 20 : 16,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isDone
                      ? null
                      : Border.all(color: AppColors.border, width: 1.5),
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
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isUpNext && !isDone
                        ? AppColors.indigoLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: widget.isUpNext && !isDone
                        ? Border.all(color: AppColors.indigo.withOpacity(0.25))
                        : null,
                  ),
                  child: Row(
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
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.isUpNext && !isDone) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo,
                                      borderRadius: BorderRadius.circular(6),
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
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.skillName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDone
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  step.skillCategory.icon,
                                  size: 12,
                                  color: AppColors.indigo,
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigoLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    step.skillCategory.label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.indigo,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _expanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        isDone && step.completedAt != null
                                            ? 'Completed ${_formatDate(step.completedAt!)}'
                                            : 'Part of the ${step.skillCategory.label} track — complete the steps above it first if this feels out of order.',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isDone)
                        SizedBox(
                          height: 30,
                          child: widget.isPending
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.indigo,
                                    ),
                                  ),
                                )
                              : FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: widget.isUpNext
                                        ? AppColors.indigo
                                        : AppColors.surface2,
                                    foregroundColor: widget.isUpNext
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: widget.isUpNext
                                        ? null
                                        : const BorderSide(
                                            color: AppColors.border,
                                          ),
                                    elevation: 0,
                                  ),
                                  onPressed: widget.onMarkDone,
                                  child: const Text('Mark done'),
                                ),
                        ),
                    ],
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
