import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';

class NewEducation {
  NewEducation({
    required this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.description,
  });
  final String institution;
  final String? degree;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
}

class AddEducationSheet extends StatefulWidget {
  const AddEducationSheet({super.key});

  @override
  State<AddEducationSheet> createState() => _AddEducationSheetState();
}

class _AddEducationSheetState extends State<AddEducationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _ongoing = false;

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add education',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _institutionController,
                maxLength: 200,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Institution name is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  hintText: 'University of Example',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _degreeController,
                maxLength: 150,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Degree is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Degree',
                  hintText: 'B.Sc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fieldController,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Field of study (optional)',
                  hintText: 'Computer Science',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Select'
                              : _formatYmd(_startDate!),
                          style: TextStyle(
                            color: _startDate == null
                                ? p.textMuted
                                : p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _ongoing ? null : () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End date',
                          border: const OutlineInputBorder(),
                          enabled: !_ongoing,
                        ),
                        child: Text(
                          _ongoing
                              ? 'Present'
                              : (_endDate == null
                                    ? 'Select'
                                    : _formatYmd(_endDate!)),
                          style: TextStyle(
                            color: _endDate == null && !_ongoing
                                ? p.textMuted
                                : p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _ongoing,
                onChanged: (v) => setState(() {
                  _ongoing = v ?? false;
                  if (_ongoing) _endDate = null;
                }),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  "I'm currently studying here",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewEducation(
        institution: _institutionController.text.trim(),
        degree: _degreeController.text.trim(),
        fieldOfStudy: _fieldController.text.trim().isEmpty
            ? null
            : _fieldController.text.trim(),
        startDate: _startDate,
        endDate: _ongoing ? null : _endDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }
}
