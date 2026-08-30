import 'package:flutter/material.dart';

import '../../../core/models/daily_count.dart';
import '../../../core/theme/app_palette.dart';

/// Small, dependency-free bar chart (custom-painted, no charting package)
/// for showing a daily count trend — e.g. new signups over the last 30
/// days. Bars animate in on first build.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data,
    this.height = 120,
    this.barColor,
    this.expectedDays = 30,
  });

  final List<DailyCount> data;
  final double height;
  final Color? barColor;

  /// If the data has gaps (e.g. days with zero signups omitted by the
  /// backend), zero-fill so the chart still spans this many trailing
  /// days ending today. Defaults to 30. Pass 0 to disable and render
  /// exactly what was given.
  final int expectedDays;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final filled = expectedDays > 0 ? _zeroFilled(data, expectedDays) : data;

    if (filled.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet.',
            style: TextStyle(color: p.textMuted, fontSize: 12.5),
          ),
        ),
      );
    }

    final maxCount = filled
        .map((d) => d.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in filled)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Tooltip(
                  message: '${_formatDate(d.date)}: ${d.count}',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: d.count / safeMax),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedFraction, _) {
                      return FractionallySizedBox(
                        heightFactor: animatedFraction.clamp(0.02, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: (barColor ?? p.indigo).withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a contiguous list of the last [days] days ending today,
  /// filling in a count of 0 for any day missing from [source].
  List<DailyCount> _zeroFilled(List<DailyCount> source, int days) {
    final byDay = <DateTime, int>{
      for (final d in source)
        DateTime(d.date.year, d.date.month, d.date.day): d.count,
    };
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    return [
      for (var i = 0; i < days; i++)
        DailyCount(
          date: start.add(Duration(days: i)),
          count: byDay[start.add(Duration(days: i))] ?? 0,
        ),
    ];
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
