import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_preferences.dart';
import '../../notifications/data/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: p.indigoLight,
              child: Text(
                user?.initials ?? '?',
                style: TextStyle(
                  color: p.indigo,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.name ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ),
          const SizedBox(height: 24),

          const _SectionLabel('PROFILE'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _row(p, 'Name', user?.name ?? '—'),
                const Divider(height: 1),
                _row(
                  p,
                  'Contact number',
                  (user?.phoneNumber == null || user!.phoneNumber!.isEmpty)
                      ? 'Not set'
                      : user.phoneNumber!,
                ),
                const Divider(height: 1),
                _navRow(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit profile',
                  onTap: () => context.push('/profile/settings/edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _SectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _row(p, 'Email', user?.email ?? '—'),
                if (auth.isPasswordAccount) ...[
                  const Divider(height: 1),
                  _navRow(
                    context,
                    icon: Icons.lock_reset_outlined,
                    label: 'Send password reset email',
                    onTap: () => _sendPasswordReset(context, user?.email),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _SectionLabel('NOTIFICATIONS'),
          const SizedBox(height: 8),
          const _PushNotificationsToggle(),
          const SizedBox(height: 24),

          const _SectionLabel('SKILLPATH'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _navRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'View portfolio',
                  onTap: () => context.pop(),
                ),
                const Divider(height: 1),
                _navRow(
                  context,
                  icon: Icons.psychology_outlined,
                  label: 'Your skills',
                  onTap: () => context.push('/profile/skills'),
                ),
                const Divider(height: 1),
                _navRow(
                  context,
                  icon: Icons.flag_outlined,
                  label: 'Career goal & gap analysis',
                  onTap: () => context.push('/profile/career-goal'),
                ),
                const Divider(height: 1),
                _navRow(
                  context,
                  icon: Icons.groups_outlined,
                  label: 'Projects',
                  onTap: () => context.go('/projects'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _SectionLabel('APPEARANCE'),
          const SizedBox(height: 8),
          const _ThemeModeSection(),
          const SizedBox(height: 24),

          OutlinedButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String? email) async {
    if (email == null) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordResetEmail(email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password reset email sent to $email.'
              : (auth.errorMessage ?? 'Could not send reset email.'),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: p.textMuted,
      ),
    );
  }
}

Widget _navRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final p = AppPalette.of(context);
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: p.textMuted),
        ],
      ),
    ),
  );
}

Widget _row(AppPalette p, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
      ],
    ),
  );
}

//Push notifications toggle

class _PushNotificationsToggle extends StatefulWidget {
  const _PushNotificationsToggle();

  @override
  State<_PushNotificationsToggle> createState() =>
      _PushNotificationsToggleState();
}

class _PushNotificationsToggleState extends State<_PushNotificationsToggle> {
  bool? _enabled;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    NotificationPreferences.isEnabled().then((value) {
      if (mounted) setState(() => _enabled = value);
    });
  }

  Future<void> _toggle(bool value) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    setState(() => _updating = true);
    await NotificationPreferences.setEnabled(value);
    await NotificationService.instance.setPushEnabled(value, userId);
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _updating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Card(
      child: SwitchListTile(
        title: const Text('Push notifications'),
        subtitle: Text(
          'Invite requests, responses, and project updates',
          style: TextStyle(fontSize: 11.5, color: p.textMuted),
        ),
        value: _enabled ?? true,
        onChanged: (_enabled == null || _updating) ? null : _toggle,
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dark_mode_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                ),
              ],
              selected: {themeProvider.mode},
              onSelectionChanged: (selection) =>
                  themeProvider.setMode(selection.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 6),
            Text(
              'Follows your device setting by default.',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
