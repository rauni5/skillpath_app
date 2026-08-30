import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';

class NewCertification {
  NewCertification({
    required this.name,
    this.issuer,
    this.credentialUrl,
    this.earnedOn,
  });
  final String name;
  final String? issuer;
  final String? credentialUrl;
  final DateTime? earnedOn;
}

class AddCertificationSheet extends StatefulWidget {
  const AddCertificationSheet({super.key});

  @override
  State<AddCertificationSheet> createState() => _AddCertificationSheetState();
}

class _AddCertificationSheetState extends State<AddCertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _urlController = TextEditingController();
  DateTime? _earnedOn;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _earnedOn ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) setState(() => _earnedOn = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewCertification(
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim().isEmpty
            ? null
            : _issuerController.text.trim(),
        credentialUrl: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        earnedOn: _earnedOn,
      ),
    );
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
                'Add certification',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                maxLength: 200,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Certification name is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'AWS Certified Cloud Practitioner',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issuerController,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Issuer (optional)',
                  hintText: 'Amazon Web Services',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Credential link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date earned (optional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _earnedOn == null
                        ? 'Select a date'
                        : '${_earnedOn!.year}-${_earnedOn!.month.toString().padLeft(2, '0')}-${_earnedOn!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _earnedOn == null ? p.textMuted : p.textPrimary,
                    ),
                  ),
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
}
