import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../dashboard/widgets/project_card.dart';
import '../providers/projects_provider.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<ProjectsProvider>().loadProjects();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create project',
            onPressed: () => context.push('/projects/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/projects/new'),
        child: const Icon(Icons.add),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, projects),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppPalette p, ProjectsProvider projects) {
    switch (projects.listState) {
      case ProjectsLoadState.initial:
      case ProjectsLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case ProjectsLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: projects.listError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case ProjectsLoadState.loaded:
        if (projects.projects.isEmpty) {
          return RefreshIndicator(
            key: const ValueKey('empty'),
            onRefresh: () async => _load(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.rocket_launch_outlined, size: 40, color: p.textMuted),
                const SizedBox(height: 14),
                Text(
                  'No open projects yet.\nBe the first to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
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
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                projects.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: projects.projects.length + 1,
              itemBuilder: (context, index) {
                if (index == projects.projects.length) {
                  if (!projects.hasMore) return const SizedBox(height: 8);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: projects.isLoadingMore
                            ? CircularProgressIndicator(strokeWidth: 2, color: p.indigo)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }
                final project = projects.projects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProjectCard(
                    project: project,
                    onTap: () => context.push('/projects/${project.id}'),
                  ),
                );
              },
            ),
          ),
        );
    }
  }
}
