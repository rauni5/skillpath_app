import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/achievement.dart';
import '../../../core/models/admin_achievement.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_achievements_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';

/// Create (achievementId == null) or edit (achievementId != null) an
/// achievement. The unlock rule is always a (criteriaType, criteriaValue)
/// pair — no free-form logic — so any admin-created achievement is
/// evaluated by the exact same generic code as the seeded ones.
class AdminAchievementFormScreen extends StatefulWidget {
  const AdminAchievementFormScreen({super.key, this.achievementId});

  final int? achievementId;

  bool get isEditing => achievementId != null;

  @override
  State<AdminAchievementFormScreen> createState() =>
      _AdminAchievementFormScreenState();
}

class _AdminAchievementFormScreenState
    extends State<AdminAchievementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _valueCtrl = TextEditingController(text: '1');

  String _icon = achievementIconOptions.first;
  AchievementCriteriaType _criteriaType =
      AchievementCriteriaType.roadmapStepsCompleted;
  bool _enabled = true;
  int? _hydratedId;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminAchievementsProvider>().loadDetail(
          widget.achievementId!,
        );
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _hydrate(AdminAchievement a) {
    if (_hydratedId == a.id) return;
    _hydratedId = a.id;
    _codeCtrl.text = a.code;
    _titleCtrl.text = a.title;
    _descCtrl.text = a.description;
    _categoryCtrl.text = a.category;
    _valueCtrl.text = a.criteriaValue.toString();
    setState(() {
      _icon = a.icon;
      _criteriaType = a.criteriaType;
      _enabled = a.enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<AdminAchievementsProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: widget.isEditing
                ? Icons.edit_outlined
                : Icons.add_circle_outline,
            title: widget.isEditing ? 'Edit Achievement' : 'New Achievement',
            subtitle: widget.isEditing
                ? 'Update this achievement\'s details and unlock criteria.'
                : 'Define a new unlockable achievement for users.',
          ),
          Expanded(
            child: widget.isEditing
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildEditBody(context, p, provider),
                  )
                : _buildForm(context, p, provider, achievement: null),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBody(
    BuildContext context,
    AppPalette p,
    AdminAchievementsProvider provider,
  ) {
    switch (provider.detailState) {
      case AdminAchievementDetailLoadState.initial:
      case AdminAchievementDetailLoadState.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );
      case AdminAchievementDetailLoadState.error:
        return InlineErrorState(
          key: const ValueKey('error'),
          message: provider.detailError ?? 'Something went wrong.',
          onRetry: () => context.read<AdminAchievementsProvider>().loadDetail(
            widget.achievementId!,
          ),
        );
      case AdminAchievementDetailLoadState.loaded:
        final a = provider.selected!;
        _hydrate(a);
        return _buildForm(context, p, provider, achievement: a);
    }
  }

  Widget _buildForm(
    BuildContext context,
    AppPalette p,
    AdminAchievementsProvider provider, {
    required AdminAchievement? achievement,
  }) {
    final value = int.tryParse(_valueCtrl.text) ?? 1;
    final error = widget.isEditing
        ? provider.detailError
        : provider.createError;

    return Center(
      key: const ValueKey('form'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            AdminCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _codeCtrl,
                      enabled: !widget.isEditing,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Code',
                        helperText: widget.isEditing
                            ? "Can't be changed after creation."
                            : 'Uppercase letters, numbers, underscores only — e.g. NIGHT_OWL',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(v.trim())) {
                          return 'Uppercase letters, numbers, underscores only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        helperText: 'Shown to students — describe what to do.',
                      ),
                      maxLines: 2,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        helperText:
                            'Free text grouping — e.g. roadmap, streak, project',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Icon'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: achievementIconOptions.map((name) {
                        final selected = name == _icon;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _icon = name),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected ? p.indigoLight : p.surface2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? p.indigo : p.border,
                              ),
                            ),
                            child: Icon(
                              Achievement.iconForName(name),
                              size: 20,
                              color: selected ? p.indigo : p.textMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<AchievementCriteriaType>(
                      initialValue: _criteriaType,
                      decoration: const InputDecoration(
                        labelText: 'Unlock rule',
                      ),
                      items: AchievementCriteriaType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _criteriaType = v ?? _criteriaType),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            _criteriaType ==
                                AchievementCriteriaType.roadmapPercentComplete
                            ? 'Threshold (%)'
                            : 'Threshold',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1)
                          return 'Enter a whole number ≥ 1';
                        if (_criteriaType ==
                                AchievementCriteriaType
                                    .roadmapPercentComplete &&
                            n > 100) {
                          return 'Percent can\'t exceed 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _criteriaType.unlockHint(value),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: p.textMuted,
                      ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        subtitle: Text(
                          _enabled
                              ? 'Obtainable by anyone who meets the criteria.'
                              : 'Hidden from anyone who hasn\'t already unlocked it.',
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                      if (achievement != null &&
                          achievement.unlockedByCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Earned by ${achievement.unlockedByCount} '
                          '${achievement.unlockedByCount == 1 ? 'student' : 'students'} so far.',
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                      ],
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                (widget.isEditing
                                    ? provider.isSaving
                                    : provider.isCreating)
                                ? null
                                : () => widget.isEditing
                                      ? _save(context, achievement!.id)
                                      : _create(context),
                            child:
                                (widget.isEditing
                                    ? provider.isSaving
                                    : provider.isCreating)
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.isEditing
                                        ? 'Save changes'
                                        : 'Create',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                          ),
                        ),
                        if (widget.isEditing) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: p.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(color: p.red),
                              ),
                              onPressed: provider.isDeleting
                                  ? null
                                  : () => _confirmDelete(context, achievement!),
                              child: provider.isDeleting
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: p.red,
                                      ),
                                    )
                                  : const Text(
                                      'Delete achievement',
                                      style: TextStyle(fontSize: 14),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminAchievementsProvider>();
    final created = await provider.createAchievement(
      code: _codeCtrl.text.trim().toUpperCase(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      icon: _icon,
      category: _categoryCtrl.text.trim(),
      criteriaType: _criteriaType,
      criteriaValue: int.parse(_valueCtrl.text),
    );
    if (created != null && context.mounted) {
      context.pushReplacement('/admin/achievements/${created.id}');
    }
  }

  Future<void> _save(BuildContext context, int id) async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminAchievementsProvider>().updateAchievement(
      id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      icon: _icon,
      category: _categoryCtrl.text.trim(),
      criteriaType: _criteriaType,
      criteriaValue: int.parse(_valueCtrl.text),
      enabled: _enabled,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminAchievement achievement,
  ) async {
    final hasEarners = achievement.unlockedByCount > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          hasEarners ? 'Disable this achievement?' : 'Delete this achievement?',
        ),
        content: Text(
          hasEarners
              ? '${achievement.unlockedByCount} student(s) have already earned '
                    '"${achievement.title}", so it can\'t be deleted outright — '
                    'it\'ll be disabled instead, keeping their badge intact but '
                    'hiding it from anyone who hasn\'t earned it yet.'
              : 'Nobody has earned "${achievement.title}" yet, so this removes it completely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(hasEarners ? 'Disable' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await context
        .read<AdminAchievementsProvider>()
        .deleteAchievement(achievement.id);
    if (!context.mounted) return;
    if (result == null) {
      final err = context.read<AdminAchievementsProvider>().detailError;
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.deleted) {
      context.pop();
    }
  }
}
