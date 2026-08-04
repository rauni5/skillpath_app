import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_users_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() => context.read<AdminUsersProvider>().loadUsers();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final admin = context.watch<AdminUsersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, admin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminUsersProvider admin,
  ) {
    switch (admin.state) {
      case AdminUsersLoadState.initial:
      case AdminUsersLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case AdminUsersLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: admin.error ?? 'Something went wrong.',
          onRetry: _load,
        );
      case AdminUsersLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? admin.users
            : admin.users
                  .where(
                    (u) =>
                        u.name.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            key: const ValueKey('empty'),
            child: Text(
              query.isEmpty ? 'No users yet.' : 'No users match "$query".',
              style: TextStyle(color: p.textMuted, fontSize: 13),
            ),
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _UserRow(user: filtered[i]),
          ),
        );
    }
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final admin = context.watch<AdminUsersProvider>();
    final isSelf = context.watch<AuthProvider>().currentUser?.id == user.id;
    final isPending = admin.pendingUserIds.contains(user.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: p.indigoLight,
            child: Text(
              user.initials,
              style: TextStyle(
                color: p.indigo,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(you)',
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (isPending)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isAdmin)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.indigoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Switch(
                  value: user.isAdmin,
                  onChanged: isSelf
                      ? null
                      : (v) => _confirmToggle(context, user, v),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    AppUser user,
    bool makeAdmin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(makeAdmin ? 'Grant admin access?' : 'Revoke admin access?'),
        content: Text(
          makeAdmin
              ? '${user.name} will be able to sign in to the admin panel and manage skills, roles, and users.'
              : '${user.name} will lose access to the admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(makeAdmin ? 'Grant access' : 'Revoke access'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminUsersProvider>().setAdmin(
        user.id,
        makeAdmin,
      );
      if (!ok && context.mounted) {
        final error = context.read<AdminUsersProvider>().error;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }
}
