import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/dashboard_ai_provider.dart';

/// Shows the AI-generated "what's next" summary in place of a static
/// "upcoming steps" list. Generation only happens when the user taps
/// refresh — this widget never calls the AI on its own. Collapsed by
/// default; tap the header to expand.
class AiSummaryCard extends StatefulWidget {
  const AiSummaryCard({
    super.key,
    required this.provider,
    required this.onRefresh,
  });

  final DashboardAiProvider provider;
  final VoidCallback onRefresh;

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant AiSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand once a summary first arrives (e.g. right after the user
    // taps refresh) so they don't have to tap twice to see the result.
    final justGenerated =
        oldWidget.provider.summary == null && widget.provider.summary != null;
    if (justGenerated) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = widget.provider;
    final hasSummary = provider.summary != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.indigoLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.indigo.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 15, color: p.indigo),
                const SizedBox(width: 6),
                Text(
                  'AI SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.indigo,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!_expanded && hasSummary) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.summary!.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (_expanded)
                  _RefreshButton(
                    busy: provider.isGenerating,
                    onPressed: widget.onRefresh,
                    color: p.indigo,
                  ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: p.indigo,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _ExpandedContent(provider: provider, p: p),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({required this.provider, required this.p});
  final DashboardAiProvider provider;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final hasSummary = provider.summary != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isGenerating && !hasSummary)
          _SkeletonLines(color: p.indigo)
        else if (hasSummary)
          Text(
            provider.summary!.content,
            style: TextStyle(fontSize: 13, height: 1.45, color: p.textPrimary),
          )
        else if (provider.errorMessage != null)
          Text(
            provider.errorMessage!,
            style: TextStyle(fontSize: 12.5, color: p.red),
          )
        else
          Text(
            'Tap refresh to have the AI look at your progress and tell you what to focus on next.',
            style: TextStyle(fontSize: 12.5, color: p.textMuted),
          ),
        if (hasSummary) ...[
          const SizedBox(height: 8),
          Text(
            'Generated ${_relativeTime(provider.summary!.generatedAt)}',
            style: TextStyle(fontSize: 10.5, color: p.textMuted),
          ),
        ],
      ],
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.busy,
    required this.onPressed,
    required this.color,
  });

  final bool busy;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.refresh, size: 17, color: color),
      ),
    );
  }
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(1), bar(0.85), bar(0.5)],
    );
  }
}
