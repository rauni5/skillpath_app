import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/public_links.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_preferences.dart';
import '../../notifications/data/notification_service.dart';
import '../providers/public_profile_provider.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.indigoLight, width: 3),
                ),
                child: UserAvatar(
                  avatarUrl: user?.avatarUrl,
                  initials: user?.initials ?? '?',
                  radius: 30,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user?.name ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
            const SizedBox(height: 28),

            const _SectionLabel('PROFILE'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _InfoRow(label: 'Name', value: user?.name ?? '—'),
                const _RowDivider(),
                _InfoRow(
                  label: 'Contact number',
                  value:
                      (user?.phoneNumber == null || user!.phoneNumber!.isEmpty)
                      ? 'Not set'
                      : user.phoneNumber!,
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.edit_outlined,
                  iconColor: p.indigo,
                  iconBackground: p.indigoLight,
                  label: 'Edit profile',
                  onTap: () => context.push('/profile/settings/edit'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionLabel('ACCOUNT'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _InfoRow(label: 'Email', value: user?.email ?? '—'),
                if (auth.isPasswordAccount) ...[
                  const _RowDivider(),
                  _NavRow(
                    icon: Icons.lock_reset_outlined,
                    iconColor: p.indigo,
                    iconBackground: p.indigoLight,
                    label: 'Send password reset email',
                    onTap: () => _sendPasswordReset(context, user?.email),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            const _SectionLabel('NOTIFICATIONS'),
            const SizedBox(height: 8),
            const _PushNotificationsToggle(),
            const SizedBox(height: 24),

            const _SectionLabel('SHARING'),
            const SizedBox(height: 8),
            const _ShareProfileSection(),
            const SizedBox(height: 24),

            const _SectionLabel('SKILLPATH'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _NavRow(
                  icon: Icons.person_outline,
                  iconColor: p.indigo,
                  iconBackground: p.indigoLight,
                  label: 'View portfolio',
                  onTap: () => context.pop(),
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.psychology_outlined,
                  iconColor: p.indigo,
                  iconBackground: p.indigoLight,
                  label: 'Your skills',
                  onTap: () => context.push('/profile/skills'),
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.flag_outlined,
                  iconColor: p.amberText,
                  iconBackground: p.amberLight,
                  label: 'Career goal & gap analysis',
                  onTap: () => context.push('/profile/career-goal'),
                ),
                const _RowDivider(),
                _NavRow(
                  icon: Icons.groups_outlined,
                  iconColor: p.greenText,
                  iconBackground: p.greenLight,
                  label: 'Projects',
                  onTap: () => context.go('/projects'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionLabel('APPEARANCE'),
            const SizedBox(height: 8),
            const _ThemeModeSection(),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.red,
                  side: BorderSide(color: p.redLight, width: 1.5),
                  backgroundColor: p.redLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Sign out?',
                    message:
                        'You\'ll need to log back in to access your '
                        'account, roadmap, and projects.',
                    confirmText: 'Sign out',
                    icon: Icons.logout_rounded,
                  );
                  if (!confirmed || !context.mounted) return;
                  context.read<AuthProvider>().signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Sign out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String? email) async {
    if (email == null) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordResetEmail(email);
    if (!context.mounted) return;
    if (ok) {
      showSuccessDialog(context, 'Password reset email sent to $email.');
    } else {
      showErrorDialog(
        context,
        auth.errorMessage ?? 'Could not send reset email.',
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: p.textMuted,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: p.indigo.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Divider(height: 1, indent: 56, color: p.border);
  }
}

/// A tappable settings row with a small colored icon badge, a label, and
/// a trailing chevron.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
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
}

/// A static label/value row (e.g. "Email — you@example.com").
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: p.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Push notifications toggle ---

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
    return _SettingsCard(
      children: [
        SwitchListTile(
          title: const Text('Push notifications'),
          subtitle: Text(
            'Invite requests, responses, and project updates',
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
          ),
          activeTrackColor: p.indigo,
          value: _enabled ?? true,
          onChanged: (_enabled == null || _updating) ? null : _toggle,
        ),
      ],
    );
  }
}

// --- Share profile ---

class _ShareProfileSection extends StatefulWidget {
  const _ShareProfileSection();

  @override
  State<_ShareProfileSection> createState() => _ShareProfileSectionState();
}

class _ShareProfileSectionState extends State<_ShareProfileSection> {
  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PublicProfileProvider>().loadSettings(userId),
      );
    }
  }

  Future<void> _toggle(bool value) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final provider = context.read<PublicProfileProvider>();
    final ok = value
        ? await provider.enable(userId)
        : await provider.disable(userId);
    if (!ok && mounted && provider.settingsError != null) {
      showErrorDialog(context, provider.settingsError!);
    }
  }

  Future<void> _regenerate() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate link?'),
        content: const Text(
          'Anyone with your old link will no longer be able to view your '
          "profile. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<PublicProfileProvider>();
    final ok = await provider.regenerateLink(userId);
    if (!ok && mounted && provider.settingsError != null) {
      showErrorDialog(context, provider.settingsError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<PublicProfileProvider>();
    final settings = provider.settings;
    final loading = provider.settingsState == PublicProfileLoadState.loading;
    final enabled = settings?.enabled ?? false;
    final link = settings?.token == null
        ? null
        : buildPublicProfileLink(settings!.token!);

    return _SettingsCard(
      children: [
        SwitchListTile(
          title: const Text('Public profile'),
          subtitle: Text(
            'Anyone with the link can view a read-only version of your '
            'profile — no account needed.',
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
          ),
          activeTrackColor: p.indigo,
          value: enabled,
          onChanged: (loading || provider.isUpdatingSettings) ? null : _toggle,
        ),
        if (enabled && link != null) ...[
          Divider(height: 1, color: p.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 12.5, color: p.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text: 'Check out my SkillPath profile: $link',
                            ),
                          );
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: provider.isUpdatingSettings ? null : _regenerate,
                    child: Text(
                      'Regenerate link',
                      style: TextStyle(color: p.textMuted, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- Appearance ---

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dark_mode_outlined, size: 18, color: p.indigo),
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
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
