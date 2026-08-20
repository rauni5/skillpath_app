import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// A compact metric tile — big number, short label, optional icon badge and
/// trend caption (e.g. "+12 this week"). Used across the admin dashboard
/// and users screen so all analytics read consistently.
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.accentColor,
    this.fullWidth = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final Color? accentColor;
  final bool fullWidth;
  final VoidCallback? onTap;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final accent = widget.accentColor ?? p.indigo;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.onTap != null)
              Icon(Icons.chevron_right, size: 15, color: p.textMuted),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        // Always reserve the same two-line slot for the caption — present
        // or not — so every card in a row ends up the same height instead
        // of the ones with captions growing taller.
        SizedBox(
          height: 30,
          child: Text(
            widget.caption ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: p.textMuted, height: 1.3),
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.onTap == null
            ? Padding(padding: const EdgeInsets.all(16), child: content)
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: (_) => _setPressed(true),
                  onTapCancel: () => _setPressed(false),
                  onTapUp: (_) => _setPressed(false),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}
