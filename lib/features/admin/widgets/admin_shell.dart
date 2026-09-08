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

  /// Below this width (mobile/narrow web), the persistent 236px side rail
  /// would eat most of the viewport and cause every page to feel cramped
  /// and clipped. Switch to an app bar + drawer instead so content gets
  /// the full width.
  static const _railBreakpoint = 760.0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < _railBreakpoint;

        if (!isNarrow) {
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

        final currentTitle = selectedIndex >= 0
            ? _navItems[selectedIndex].label
            : 'Admin';
        return Scaffold(
          backgroundColor: p.surface2,
          appBar: AppBar(
            backgroundColor: p.surface1,
            foregroundColor: p.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              currentTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          drawer: Drawer(
            width: 260,
            backgroundColor: p.surface1,
            child: _NavRail(
              selectedIndex: selectedIndex,
              p: p,
              fillWidth: true,
            ),
          ),
          body: child,
        );
      },
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.selectedIndex,
    required this.p,
    this.fillWidth = false,
  });

  final int selectedIndex;
  final AppPalette p;

  /// True when rendered inside a [Drawer] (narrow/mobile web) — the
  /// Drawer already sets its own width, so this shouldn't also force a
  /// fixed 236px and leave an odd gap.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fillWidth ? null : 258,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.indigo,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Admin',
            style: TextStyle(
              fontSize: 18,
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
          onTap: () {
            // Close the drawer first if this rail is being shown as one
            // (narrow/mobile web) — otherwise it stays open over the new
            // page until manually dismissed.
            if (Scaffold.maybeOf(context)?.hasDrawer == true) {
              Navigator.of(context).pop();
            }
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(item.icon, size: 21, color: color),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: p.textMuted),
                const SizedBox(width: 12),
                Text(
                  'Sign out',
                  style: TextStyle(fontSize: 14.5, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
