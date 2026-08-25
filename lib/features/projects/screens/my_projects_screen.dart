import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/project_card.dart';
import '../providers/project_management_provider.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<ProjectManagementProvider>().loadOwnedProjects(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mgmt = context.watch<ProjectManagementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Projects')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, mgmt),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    ProjectManagementProvider mgmt,
  ) {
    switch (mgmt.ownedState) {
      case OwnedProjectsLoadState.initial:
      case OwnedProjectsLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case OwnedProjectsLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: mgmt.ownedError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case OwnedProjectsLoadState.loaded:
        if (mgmt.ownedProjects.isEmpty) {
          return RefreshIndicator(
            key: const ValueKey('empty'),
            onRefresh: () async => _load(),
            child: ListView(
              children: [
                const SizedBox(height: 90),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: p.indigoLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_off_outlined,
                      size: 32,
                      color: p.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "You don't own any projects yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start one and build your team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => context.push('/projects/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create a project'),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mgmt.ownedProjects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final project = mgmt.ownedProjects[i];
              return ProjectCard(
                project: project,
                onTap: () => context.push('/projects/mine/${project.id}'),
              );
            },
          ),
        );
    }
  }
}
