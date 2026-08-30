import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../career/providers/career_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/skill_picker_field.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String? _difficulty;
  int _teamSize = 3;
  final Set<int> _selectedSkillIds = {};
  final Set<int> _selectedRoleIds = {};

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final career = context.read<CareerProvider>();
      if (career.roles.isEmpty) career.loadRoles();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final projects = context.read<ProjectsProvider>();
    final created = await projects.createProject(
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      difficulty: _difficulty,
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      teamSize: _teamSize,
      requiredSkillIds: _selectedSkillIds.toList(),
      requiredRoleIds: _selectedRoleIds.toList(),
    );
    if (!mounted) return;
    if (created != null) {
      context.pop();
    } else if (projects.createError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(projects.createError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final career = context.watch<CareerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create project'),
        actions: [
          if (projects.isCreating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold, color: p.indigo),
              ),
            ),
        ],
      ),
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
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Add a description so people know what this project is'
                    : null,
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
              SkillPickerField(
                selectedSkillIds: _selectedSkillIds,
                onChanged: (ids) => setState(() {
                  _selectedSkillIds
                    ..clear()
                    ..addAll(ids);
                }),
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
            ],
          ),
        ),
      ),
    );
  }
}
