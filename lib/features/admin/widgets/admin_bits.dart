import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Small uppercase micro-heading used above charts/sections.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: p.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// A small colored pill for status/count display (non-interactive).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = color ?? p.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? c.withValues(alpha: 0.14) : p.surface2,
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable pill that flips a boolean state — replaces bare [Switch]
/// widgets in tight table rows, which tend to get visually clipped.
class ToggleBadge extends StatelessWidget {
  const ToggleBadge({
    super.key,
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeColor,
    this.onTap,
  });

  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? activeColor.withValues(alpha: 0.14) : p.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? activeColor.withValues(alpha: 0.4) : p.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.remove_circle_outline,
                  size: 15,
                  color: active ? activeColor : p.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  active ? activeLabel : inactiveLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? activeColor : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small inline spinner sized to sit inline with pills/badges.
class MiniSpinner extends StatelessWidget {
  const MiniSpinner({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Empty-state placeholder — icon, message, optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: p.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 13),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

/// Inline error state with a retry button — used inside the content area
/// rather than a full-screen error page, since the header stays visible.
class InlineErrorState extends StatelessWidget {
  const InlineErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: p.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free-form category input: a text field with an autocomplete dropdown of
/// categories already in use. Unlike a [DropdownButtonFormField], typing a
/// brand new value is always allowed — categories are never a fixed set.
class CategoryInputField extends StatelessWidget {
  const CategoryInputField({
    super.key,
    required this.knownCategories,
    required this.initialValue,
    required this.onChanged,
    this.labelText = 'Category',
  });

  final List<String> knownCategories;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return knownCategories;
        return knownCategories.where((c) => c.toLowerCase().contains(query));
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        // Keep the caller's onChanged in sync with free typing too, not
        // just picks from the suggestion list.
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            helperText: 'Pick an existing category or type a new one',
            helperMaxLines: 1,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final p = AppPalette.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      title: Text(option, style: const TextStyle(fontSize: 13)),
                      onTap: () => onSelected(option),
                    ),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No matches — press enter to use this as a new category.',
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A generic sortable table for admin list screens. Renders as a real
/// scrollable [DataTable] on wide layouts; the [rows] already carry
/// per-column [DataCell]s so callers keep full control of cell content
/// (chips, icons, tap targets, etc.) while this widget owns the shared
/// header styling, sorting affordance, and empty/loading chrome.
class AdminDataTable extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.minWidth = 720,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final double minWidth;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // LayoutBuilder gives the real available width so the table can
      // stretch to fill it on a wide desktop screen (rather than sitting
      // at a fixed 720px with empty space beside it) while still
      // guaranteeing at least [minWidth] so columns stay readable and
      // scroll horizontally on a narrow/mobile-web viewport instead of
      // squashing or clipping content.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveMinWidth = widget.minWidth > constraints.maxWidth
              ? widget.minWidth
              : constraints.maxWidth;
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: effectiveMinWidth),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: p.border,
                    dataTableTheme: DataTableThemeData(
                      headingRowColor: WidgetStatePropertyAll(p.surface2),
                      headingTextStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                        letterSpacing: 0.3,
                      ),
                      dataTextStyle: TextStyle(
                        fontSize: 14.5,
                        color: p.textPrimary,
                      ),
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 66,
                    ),
                  ),
                  child: DataTable(
                    sortColumnIndex: widget.sortColumnIndex,
                    sortAscending: widget.sortAscending,
                    showCheckboxColumn: false,
                    columnSpacing: 32,
                    columns: widget.columns,
                    rows: widget.rows,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An icon-badge + title row used at the top of a form section inside an
/// [AdminCard] — gives "Skill details", "Unlock rule", etc. a visual anchor
/// instead of a form card just starting cold with the first text field.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final accent = color ?? p.indigo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: p.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows a consistently-styled confirmation dialog for destructive (or any)
/// actions — replaces the plain default [AlertDialog] used ad hoc for
/// "delete this?" prompts across the admin screens. Returns `true` only if
/// the person tapped the confirm button.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  IconData icon = Icons.warning_amber_rounded,
  bool destructive = true,
}) async {
  final p = AppPalette.of(context);
  final accent = destructive ? p.red : p.indigo;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(icon: icon, title: title, color: accent),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// the caller's form fields, an inline error slot, and a full-width
/// Cancel/primary-action button pair. Replaces ad-hoc [AlertDialog] usage
/// so every "New skill" / "New role" / "Add branch" dialog looks the same.
class AdminFormDialog extends StatelessWidget {
  const AdminFormDialog({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    required this.onCancel,
    required this.onSubmit,
    this.submitLabel = 'Create',
    this.isSubmitting = false,
    this.errorText,
    this.width = 460,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final bool isSubmitting;
  final String? errorText;
  final double width;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final accent = accentColor ?? p.indigo;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                icon: icon,
                title: title,
                subtitle: subtitle,
                color: accent,
              ),
              const SizedBox(height: 20),
              child,
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
