import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingAboutStep extends StatefulWidget {
  const OnboardingAboutStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingAboutStep> createState() => _OnboardingAboutStepState();
}

class _OnboardingAboutStepState extends State<OnboardingAboutStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late ExperienceLevel _level;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _level = user?.experienceLevel ?? ExperienceLevel.beginner;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      experienceLevel: _level,
    );
    if (ok) {
      widget.onContinue();
    } else if (mounted && auth.errorMessage != null) {
      showErrorDialog(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = AppPalette.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about you',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "A few details to personalise your roadmap and match you with the right teammates.",
              style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Short bio (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'EXPERIENCE LEVEL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ExperienceLevel.values.map((level) {
                final selected = _level == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _levelLabel(level),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _level = level);
                      },
                      selectedColor: p.indigoLight,
                      labelPadding: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: TextStyle(
                        color: selected ? p.indigo : p.textSecondary,
                        // Keeping font weight constant prevents text sizing shifts
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(color: selected ? p.indigo : p.border),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }
}
