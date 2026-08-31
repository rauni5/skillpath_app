import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';

class _AdminNavItem {
  const _AdminNavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}

const _navItems = [
  _AdminNavItem('/admin', Icons.dashboard_outlined, 'Overview'),
  _AdminNavItem('/admin/users', Icons.people_outline, 'Users'),
  _AdminNavItem('/admin/skills', Icons.psychology_outlined, 'Skills'),
  _AdminNavItem('/admin/roles', Icons.badge_outlined, 'Career Roles'),
  _AdminNavItem(
    '/admin/achievements',
    Icons.emoji_events_outlined,
    'Achievements',
  ),
];

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIndex = _navItems.indexWhere(
      (d) =>
          location == d.path ||
          (d.path != '/admin' && location.startsWith('${d.path}/')),
    );
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      backgroundColor: p.surface2,
      body: Row(
        children: [
          _NavRail(selectedIndex: selectedIndex, p: p),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.selectedIndex, required this.p});

  final int selectedIndex;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      color: p.surface1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(p: p),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < _navItems.length; i++)
                    _NavTile(
                      item: _navItems[i],
                      selected: i == selectedIndex,
                      p: p,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _SignOutTile(p: p),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.p});
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.indigo,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Admin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.p});

  final _AdminNavItem item;
  final bool selected;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final color = selected ? p.indigo : p.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? p.indigoLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: color),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.p});
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.read<AuthProvider>().signOut(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: p.textMuted),
                const SizedBox(width: 12),
                Text(
                  'Sign out',
                  style: TextStyle(fontSize: 13, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
