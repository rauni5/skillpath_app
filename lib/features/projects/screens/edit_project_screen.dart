import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../career/providers/career_provider.dart';
import '../../skills/providers/skills_provider.dart';
import '../providers/project_management_provider.dart';

class EditProjectScreen extends StatefulWidget {
  const EditProjectScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _skillSearchCtrl = TextEditingController();
  String? _difficulty;
  int _teamSize = 3;
  final Set<int> _selectedSkillIds = {};
  final Set<int> _selectedRoleIds = {};
  bool _prefilled = false;

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final skills = context.read<SkillsProvider>();
      if (skills.catalog.isEmpty) skills.loadCatalog();
      final career = context.read<CareerProvider>();
      if (career.roles.isEmpty) career.loadRoles();

      final mgmt = context.read<ProjectManagementProvider>();
      // Re-fetch to be safe, in case this screen was opened via a direct
      // link rather than from the already-loaded Manage screen.
      await mgmt.loadManageData(widget.projectId);
      _prefill(mgmt);
    });
  }

  void _prefill(ProjectManagementProvider mgmt) {
    final project = mgmt.managedProject;
    if (project == null || _prefilled) return;
    _nameCtrl.text = project.name;
    _descriptionCtrl.text = project.description ?? '';
    _linkCtrl.text = project.link ?? '';
    _teamSize = project.teamSize;
    _difficulty = _difficulties.firstWhere(
      (d) => d.toUpperCase() == (project.difficulty ?? '').toUpperCase(),
      orElse: () => '',
    );
    if (_difficulty!.isEmpty) _difficulty = null;
    _selectedSkillIds
      ..clear()
      ..addAll(project.requiredSkills.map((s) => s.id));
    _selectedRoleIds
      ..clear()
      ..addAll(project.requiredRoles.map((r) => r.id));
    setState(() => _prefilled = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    _skillSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final mgmt = context.read<ProjectManagementProvider>();
    final ok = await mgmt.updateProject(
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      difficulty: _difficulty,
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      teamSize: _teamSize,
      requiredSkillIds: _selectedSkillIds.toList(),
      requiredRoleIds: _selectedRoleIds.toList(),
    );
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else if (mgmt.updateError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mgmt.updateError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();
    final skills = context.watch<SkillsProvider>();
    final career = context.watch<CareerProvider>();

    if (!_prefilled) {
      if (mgmt.managedProject != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _prefill(mgmt));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Edit project')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredCatalog = _skillSearchCtrl.text.trim().isEmpty
        ? skills.catalog
        : skills.catalog
              .where(
                (s) => s.name.toLowerCase().contains(
                  _skillSearchCtrl.text.trim().toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit project')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Project name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Give your project a name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  hintText: 'github.com/you/project',
                  prefixIcon: Icon(Icons.link, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final ok =
                      Uri.tryParse(
                        v.trim().contains('://')
                            ? v.trim()
                            : 'https://${v.trim()}',
                      )?.host.contains('.') ??
                      false;
                  return ok ? null : 'Enter a valid link';
                },
              ),
              const SizedBox(height: 18),
              Text(
                'DIFFICULTY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _difficulties.map((d) {
                  final selected = _difficulty == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _difficulty = selected ? null : d),
                    selectedColor: p.indigoLight,
                    labelStyle: TextStyle(
                      color: selected ? p.indigo : p.textSecondary,
                      fontSize: 12.5,
                    ),
                    side: BorderSide(color: selected ? p.indigo : p.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEAM SIZE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _teamSize > 1
                              ? () => setState(() => _teamSize--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 22,
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$_teamSize',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _teamSize < 20
                              ? () => setState(() => _teamSize++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'REQUIRED SKILLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _skillSearchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search skills…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              if (skills.catalogState == SkillsLoadState.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.indigo,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: filteredCatalog.map((s) {
                    final selected = _selectedSkillIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.name),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedSkillIds.add(s.id);
                        } else {
                          _selectedSkillIds.remove(s.id);
                        }
                      }),
                      selectedColor: p.indigoLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? p.indigo : p.textSecondary,
                      ),
                      side: BorderSide(color: selected ? p.indigo : p.border),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),
              Text(
                'REQUIRED ROLES (optional)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (career.rolesState == CareerLoadState.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.indigo,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: career.roles.map((r) {
                    final selected = _selectedRoleIds.contains(r.id);
                    return FilterChip(
                      label: Text(r.name),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedRoleIds.add(r.id);
                        } else {
                          _selectedRoleIds.remove(r.id);
                        }
                      }),
                      selectedColor: p.indigoLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? p.indigo : p.textSecondary,
                      ),
                      side: BorderSide(color: selected ? p.indigo : p.border),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: mgmt.isUpdating ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: p.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: mgmt.isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
