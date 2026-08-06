import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(p, 'Experience', user?.experienceLevel.name ?? '—'),
                  const Divider(height: 20),
                  _row(
                    p,
                    'Availability',
                    (user?.availability ?? false)
                        ? 'Available'
                        : 'Not available',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
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
    return Row(
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
                  'Appearance',
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
