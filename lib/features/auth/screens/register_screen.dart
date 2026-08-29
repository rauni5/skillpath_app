import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  ExperienceLevel _level = ExperienceLevel.beginner;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      experienceLevel: _level,
    );
    if (!ok && mounted && auth.errorMessage != null) {
      showErrorDialog(
        context,
        auth.errorMessage!,
        title: 'Could not create account',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticated) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: p.indigo)),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.indigoLight.withValues(alpha: 0.6), p.surface0],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(child: BrandMark(color: p.indigo, size: 60)),
                  const SizedBox(height: 16),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "We'll tailor your roadmap as you go — it only takes a minute.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: p.textMuted),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          label: 'Email',
                          icon: Icons.mail_outline,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocus),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'At least 6 characters'
                              : null,
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
                        Column(
                          children: ExperienceLevel.values.map((level) {
                            final selected = _level == level;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _level = level);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? p.indigoLight
                                        : p.surface1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? p.indigo : p.border,
                                      width: selected ? 1.25 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _levelIcon(level),
                                        size: 18,
                                        color: selected
                                            ? p.indigo
                                            : p.textMuted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _levelLabel(level),
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? p.indigo
                                                    : p.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              _levelDescription(level),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: selected
                                                    ? p.indigo.withValues(
                                                        alpha: 0.75,
                                                      )
                                                    : p.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: selected ? p.indigo : p.border,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
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
                              : const Text('Create account'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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

  String _levelDescription(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return "Just starting out or new to the field";
      case ExperienceLevel.intermediate:
        return 'Comfortable with the basics, building real projects';
      case ExperienceLevel.advanced:
        return 'Experienced and looking to specialise further';
    }
  }

  IconData _levelIcon(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return Icons.eco_outlined;
      case ExperienceLevel.intermediate:
        return Icons.trending_up;
      case ExperienceLevel.advanced:
        return Icons.military_tech_outlined;
    }
  }
}
