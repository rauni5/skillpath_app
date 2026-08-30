// edit_profile_screen.dart (Redesigned)
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar Section
              Center(
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _changeAvatar,
                  child: Stack(
                    children: [
                      _localAvatarPreview != null
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: MemoryImage(
                                _localAvatarPreview!,
                              ),
                            )
                          : UserAvatar(
                              avatarUrl: user?.avatarUrl,
                              initials: user?.initials ?? '?',
                              radius: 48,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: p.indigo,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Identity Group
              _FormCard(
                title: 'PERSONAL INFORMATION',
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Name can't be empty"
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller:
                        _phoneController, // Add final _phoneCtrl = TextEditingController(); in State
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number (optional)',
                      hintText: '98XXXXXXXX',
                      prefixIcon: Icon(Icons.phone, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'City, Country',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Links Group
              _FormCard(
                title: 'SOCIAL LINKS',
                children: [
                  TextFormField(
                    controller: _githubController,
                    keyboardType: TextInputType.url,
                    validator: _validateUrl,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Profile',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkedinController,
                    keyboardType: TextInputType.url,
                    validator: _validateUrl,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn Profile',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Portfolio Details Group
              _FormCard(
                title: 'PORTFOLIO DETAILS',
                children: [
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Experience Level',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ExperienceLevel>(
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
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for projects'),
                    value: _availability,
                    onChanged: (v) => setState(() => _availability = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _softSkillsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Soft Skills',
                      hintText: 'Communication, Teamwork',
                      helperText: 'Separate with commas',
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Card(
      elevation: 0,
      color: p.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: p.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
