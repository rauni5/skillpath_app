import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/project_card.dart';
import '../data/membership_alert_service.dart';
import '../providers/project_management_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_filter_sheet.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final _searchCtrl = TextEditingController();
  final _alertService = MembershipAlertService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _checkAlerts();

      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<ProjectManagementProvider>().loadMyInvites(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    context.read<ProjectsProvider>().loadProjects();
  }

  Future<void> _checkAlerts() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final changes = await _alertService.checkForChanges(userId);

    if (!mounted) return;

    for (final c in changes) {
      final verb = c.status == MemberStatus.accepted ? 'accepted' : 'rejected';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your request to join "${c.projectName}" was $verb.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();

    final invitesCount = context
        .watch<ProjectManagementProvider>()
        .myInvites
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'My Invites',
            onPressed: () => context.push('/projects/invites'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.mail_outline),
                if (invitesCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: p.indigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 15),
                      child: Text(
                        '$invitesCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'My Projects',
            onPressed: () => context.push('/projects/mine'),
            icon: const Icon(Icons.folder_outlined),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: () => showProjectFilterSheet(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune),
                if (projects.hasActiveFilters)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.indigo,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // No Scaffold floatingActionButton here.
      //
      // The Add button is positioned manually so Scaffold does not run
      // its FloatingActionButton location transition when the route/sheet
      // underneath or above this screen changes.
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    context.read<ProjectsProvider>().setSearchQuery(v);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search projects…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<ProjectsProvider>().setSearchQuery(
                                '',
                              );
                              setState(() {});
                            },
                          ),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildBody(context, p, projects),
                ),
              ),
            ],
          ),

          // Manually positioned Add button.
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => context.push('/projects/new'),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    ProjectsProvider projects,
  ) {
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
          final hasQuery = projects.searchQuery.trim().isNotEmpty;
          final filtered = hasQuery || projects.hasActiveFilters;

          return RefreshIndicator(
            key: const ValueKey('empty'),
            onRefresh: () async => _load(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 40,
                  color: p.textMuted,
                ),
                const SizedBox(height: 14),
                Text(
                  filtered
                      ? 'No projects match this search.'
                      : 'No open projects yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                if (filtered) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        projects.clearSearchAndFilters();
                      },
                      child: const Text('Clear search & filters'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                projects.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: projects.projects.length + 1,
              itemBuilder: (context, index) {
                if (index == projects.projects.length) {
                  if (!projects.hasMore) {
                    return const SizedBox(height: 8);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: projects.isLoadingMore
                            ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: p.indigo,
                              )
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
                    onTap: () {
                      final userId = context
                          .read<AuthProvider>()
                          .currentUser
                          ?.id;

                      final isMine =
                          userId != null && userId == project.ownerId;

                      context.push(
                        isMine
                            ? '/projects/mine/${project.id}'
                            : '/projects/${project.id}',
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
    }
  }
}
