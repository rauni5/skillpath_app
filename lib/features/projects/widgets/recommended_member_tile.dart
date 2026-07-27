import 'package:flutter/material.dart';

import '../../../core/models/recommended_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';

class RecommendedMemberTile extends StatelessWidget {
  const RecommendedMemberTile({super.key, required this.member});

  final RecommendedMember member;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final percent = (member.matchScore.clamp(0, 1) * 100).round();
    final initials = member.name.trim().isEmpty
        ? '?'
        : member.name.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: p.indigoLight,
            child: Text(initials, style: TextStyle(color: p.indigo, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary)),
                const SizedBox(height: 4),
                AnimatedProgressBar(value: member.matchScore.clamp(0, 1), height: 5, backgroundColor: p.border, valueColor: p.indigo),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$percent%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.indigo)),
        ],
      ),
    );
  }
}
