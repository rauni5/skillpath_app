import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';

/// Combines everything that lives on the User record: name, contact
/// number, bio, experience level, availability. Reached from Settings.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _githubController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _locationController;
  late final TextEditingController _softSkillsController;
  late final TextEditingController _bioController;
  late ExperienceLevel _experienceLevel;
  late bool _availability;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _githubController = TextEditingController(text: user?.githubUrl ?? '');
    _linkedinController = TextEditingController(text: user?.linkedinUrl ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _softSkillsController = TextEditingController(text: user?.softSkills ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _experienceLevel = user?.experienceLevel ?? ExperienceLevel.beginner;
    _availability = user?.availability ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _locationController.dispose();
    _softSkillsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name can\'t be empty.')));
      return;
    }
    for (final (label, url) in [
      ('GitHub', _githubController.text.trim()),
      ('LinkedIn', _linkedinController.text.trim()),
    ]) {
      if (url.isNotEmpty &&
          !url.startsWith('http://') &&
          !url.startsWith('https://')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label link should start with http:// or https://'),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: name,
      phoneNumber: _phoneController.text.trim(),
      githubUrl: _githubController.text.trim(),
      linkedinUrl: _linkedinController.text.trim(),
      location: _locationController.text.trim(),
      softSkills: _softSkillsController.text.trim(),
      bio: _bioController.text.trim(),
      experienceLevel: _experienceLevel,
      availability: _availability,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      // Everything here also appears on the Portfolio screen - keep it in
      // sync rather than waiting for a manual pull.
      unawaited(context.read<PortfolioProvider>().refresh());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not save.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'IDENTITY',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Contact number',
              hintText: '+1 555 123 4567',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'City, Country',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'LINKS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _githubController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'GitHub profile',
              hintText: 'https://github.com/yourname',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkedinController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'LinkedIn profile',
              hintText: 'https://linkedin.com/in/yourname',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'PORTFOLIO DETAILS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Experience level',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          const SizedBox(height: 6),
          SegmentedButton<ExperienceLevel>(
            segments: const [
              ButtonSegment(
                value: ExperienceLevel.beginner,
                label: Text('Beginner'),
              ),
              ButtonSegment(
                value: ExperienceLevel.intermediate,
                label: Text('Intermediate'),
              ),
              ButtonSegment(
                value: ExperienceLevel.advanced,
                label: Text('Advanced'),
              ),
            ],
            selected: {_experienceLevel},
            onSelectionChanged: (s) =>
                setState(() => _experienceLevel = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available for projects'),
            value: _availability,
            onChanged: (v) => setState(() => _availability = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _softSkillsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Soft skills',
              hintText: 'Communication, Time management, Teamwork',
              helperText: 'Separate with commas or new lines',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GitHub, LinkedIn, location, bio, experience level, availability, and soft skills all show on your Portfolio and CV.',
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
