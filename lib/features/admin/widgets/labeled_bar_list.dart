import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

class BarListItem {
  const BarListItem({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;
}

/// A horizontal proportional bar list — label, bar, count — used for any
/// "top N" or categorical breakdown (top skills, experience levels, most
/// earned achievements, top career choices). One consistent visual
/// language for every ranked list in the admin panel.
class LabeledBarList extends StatelessWidget {
  const LabeledBarList({
    super.key,
    required this.items,
    this.labelWidth = 120,
    this.barColor,
  });

  final List<BarListItem> items;
  final double labelWidth;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No data yet.',
            style: TextStyle(color: p.textMuted, fontSize: 12.5),
          ),
        ),
      );
    }

    final maxValue = items
        .map((i) => i.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _BarRow(
            item: items[i],
            fraction: items[i].value / safeMax,
            labelWidth: labelWidth,
            color: items[i].color ?? barColor ?? p.indigo,
            p: p,
          ),
          if (i != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.item,
    required this.fraction,
    required this.labelWidth,
    required this.color,
    required this.p,
  });

  final BarListItem item;
  final double fraction;
  final double labelWidth;
  final Color color;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            item.label,
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.03, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: p.surface2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '${item.value}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
