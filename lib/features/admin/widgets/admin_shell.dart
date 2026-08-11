import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';

class _AdminNavItem {
  // ignore: unused_element_parameter
  const _AdminNavItem(this.path, this.icon, this.label, {this.enabled = true});
  final String path;
  final IconData icon;
  final String label;
  final bool enabled;
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                children: [
                  Icon(Icons.shield_outlined, color: p.indigo, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.indigo,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    tooltip: 'Sign out',
                    icon: Icon(Icons.logout, color: p.textMuted),
                    onPressed: () => context.read<AuthProvider>().signOut(),
                  ),
                ),
              ),
            ),
            onDestinationSelected: (i) {
              final item = _navItems[i];
              if (!item.enabled) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon.')));
                return;
              }
              context.go(item.path);
            },
            destinations: _navItems
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(
                      d.icon,
                      color: d.enabled
                          ? null
                          : p.textMuted.withValues(alpha: 0.4),
                    ),
                    label: Text(
                      d.label,
                      style: d.enabled
                          ? null
                          : TextStyle(
                              color: p.textMuted.withValues(alpha: 0.4),
                            ),
                    ),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(width: 1, color: p.border),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
