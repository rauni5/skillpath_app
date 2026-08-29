import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/avatar_upload_service.dart';
import '../providers/portfolio_provider.dart';

/// Combines everything that lives on the User record: name, contact
/// number, bio, experience level, availability. Reached from Settings.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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

  final AvatarUploadService _avatarPicker = AvatarUploadService();
  Uint8List? _localAvatarPreview;
  bool _uploadingAvatar = false;

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

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _avatarPicker.pickImage(source);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final portfolio = context.read<PortfolioProvider>();

    setState(() {
      _localAvatarPreview = bytes;
      _uploadingAvatar = true;
    });

    final ok = await auth.uploadAvatar(picked);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    if (ok) {
      unawaited(portfolio.refresh());
    } else {
      showErrorDialog(
        context,
        auth.errorMessage ?? 'Could not update your photo.',
      );
    }
  }

  Future<void> _save() async {
    // Unfocus active keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    // Capture Providers and Messenger before async gaps
    final auth = context.read<AuthProvider>();
    final portfolio = context.read<PortfolioProvider>();
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

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
      unawaited(portfolio.refresh());
      await showSuccessDialog(context, 'Your profile has been updated.');
      if (mounted) navigator.pop();
    } else {
      showErrorDialog(
        context,
        auth.errorMessage ?? 'Could not save.',
        title: 'Could not save',
      );
    }
  }

  String? _validateUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'Should start with http:// or https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final user = context.watch<AuthProvider>().currentUser;

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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _changeAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _localAvatarPreview != null
                          ? CircleAvatar(
                              radius: 44,
                              backgroundImage: MemoryImage(
                                _localAvatarPreview!,
                              ),
                            )
                          : UserAvatar(
                              avatarUrl: user?.avatarUrl,
                              initials: user?.initials ?? '?',
                              radius: 44,
                            ),
                      if (_uploadingAvatar)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.indigo,
                            border: Border.all(color: p.surface0, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
              TextFormField(
                controller: _nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Name can't be empty"
                    : null,
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
                  hintText: '+977-9841431258',
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
              TextFormField(
                controller: _githubController,
                keyboardType: TextInputType.url,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateUrl,
                decoration: const InputDecoration(
                  labelText: 'GitHub profile',
                  hintText: 'https://github.com/yourname',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkedinController,
                keyboardType: TextInputType.url,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateUrl,
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
                'Your photo,GitHub, LinkedIn, location, bio, experience level, availability, and soft skills all show on your Portfolio and CV.',
                style: TextStyle(fontSize: 11.5, color: p.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
