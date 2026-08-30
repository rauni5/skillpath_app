import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project_member.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../career/providers/career_provider.dart';
import '../../dashboard/widgets/project_card.dart';
import '../../skills/providers/skills_provider.dart';
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
  final _showClearButton = ValueNotifier<bool>(false);
  final _alertService = MembershipAlertService();

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      _showClearButton.value = _searchCtrl.text.isNotEmpty;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _checkAlerts();

      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<ProjectManagementProvider>().loadMyInvites(userId);
      }
      final skills = context.read<SkillsProvider>();
      if (skills.catalog.isEmpty) skills.loadCatalog();
      final career = context.read<CareerProvider>();
      if (career.roles.isEmpty) career.loadRoles();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _showClearButton.dispose();
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
      showInfoDialog(
        context,
        title: 'Project Invitation',
        message: 'Your request to join "${c.projectName}" was $verb.',
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final invitesCount = context
        .watch<ProjectManagementProvider>()
        .myInvites
        .length;

    return Scaffold(
      backgroundColor: p.surface0,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: p.surface0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Explore Projects',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              actions: [
                _InviteIconButton(invitesCount: invitesCount, palette: p),
                IconButton(
                  tooltip: 'My Projects',
                  icon: const Icon(Icons.folder_outlined),
                  onPressed: () => context.push('/projects/mine'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: IconButton.filledTonal(
                    tooltip: 'New Project',
                    style: IconButton.styleFrom(
                      backgroundColor: p.indigoLight,
                      foregroundColor: p.indigo,
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => context.push('/projects/new'),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) {
                            context.read<ProjectsProvider>().setSearchQuery(v);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search projects, skills...',
                            hintStyle: TextStyle(
                              color: p.textMuted,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: p.textMuted,
                            ),
                            suffixIcon: ValueListenableBuilder<bool>(
                              valueListenable: _showClearButton,
                              builder: (context, show, _) {
                                if (!show) return const SizedBox.shrink();
                                return IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    context
                                        .read<ProjectsProvider>()
                                        .setSearchQuery('');
                                  },
                                );
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterActionButton(
                      hasActiveFilters: projects.hasActiveFilters,
                      onPressed: () => showProjectFilterSheet(context),
                      palette: p,
                    ),
                  ],
                ),
              ),
            ),

            if (projects.hasActiveFilters)
              SliverToBoxAdapter(
                child: _ActiveFiltersRow(capitalize: _capitalize),
              ),

            _buildSliverBody(context, p, projects),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody(
    BuildContext context,
    AppPalette p,
    ProjectsProvider projects,
  ) {
    switch (projects.listState) {
      case ProjectsLoadState.initial:
      case ProjectsLoadState.loading:
        return const SliverFillRemaining(
          child: LoadingView(key: ValueKey('loading')),
        );

      case ProjectsLoadState.error:
        return SliverFillRemaining(
          child: ErrorView(
            key: const ValueKey('error'),
            message: projects.listError ?? 'Something went wrong.',
            onRetry: _load,
          ),
        );

      case ProjectsLoadState.loaded:
        if (projects.projects.isEmpty) {
          final hasQuery = projects.searchQuery.trim().isNotEmpty;
          final filtered = hasQuery || projects.hasActiveFilters;

          return SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.indigoLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    filtered
                        ? Icons.search_off_rounded
                        : Icons.rocket_launch_outlined,
                    size: 32,
                    color: p.indigo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  filtered
                      ? 'No projects match your criteria'
                      : 'No open projects yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  filtered
                      ? 'Try adjusting your search terms or filters'
                      : 'Be the first creator to start a project.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (filtered)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: p.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      projects.clearSearchAndFilters();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'Clear filters',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: p.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push('/projects/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Create a project',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
              projects.loadMore();
            }
            return false;
          },
          child: SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == projects.projects.length) {
                  if (!projects.hasMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: p.border, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "No more projects",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: p.border, height: 1)),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: projects.isLoadingMore
                            ? CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: p.indigo,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }

                final project = projects.projects[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
              }, childCount: projects.projects.length + 1),
            ),
          ),
        );
    }
  }
}

class _InviteIconButton extends StatelessWidget {
  const _InviteIconButton({required this.invitesCount, required this.palette});

  final int invitesCount;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'My Invites',
      onPressed: () => context.push('/projects/invites'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.mail_outline),
          if (invitesCount > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.indigo,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  '$invitesCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.hasActiveFilters,
    required this.onPressed,
    required this.palette,
  });

  final bool hasActiveFilters;
  final VoidCallback onPressed;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hasActiveFilters ? palette.indigo : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        tooltip: 'Filter Projects',
        onPressed: onPressed,
        icon: Icon(
          Icons.tune,
          color: hasActiveFilters ? Colors.white : palette.textPrimary,
        ),
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.capitalize});

  final String Function(String) capitalize;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final skills = context.watch<SkillsProvider>();
    final career = context.watch<CareerProvider>();

    String skillName(int id) {
      final matches = skills.catalog.where((s) => s.id == id);
      return matches.isEmpty ? 'Skill' : matches.first.name;
    }

    String roleName(int id) {
      final matches = career.roles.where((r) => r.id == id);
      return matches.isEmpty ? 'Role' : matches.first.name;
    }

    final chips = <Widget>[];
    if (projects.filterDifficulty != null) {
      chips.add(
        _FilterChip(
          label: capitalize(projects.filterDifficulty!),
          onRemove: () => projects.setDifficultyFilter(null),
        ),
      );
    }
    for (final id in projects.filterSkillIds) {
      chips.add(
        _FilterChip(
          label: skillName(id),
          onRemove: () => projects.toggleSkillFilter(id),
        ),
      );
    }
    for (final id in projects.filterRoleIds) {
      chips.add(
        _FilterChip(
          label: roleName(id),
          onRemove: () => projects.toggleRoleFilter(id),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 32,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            ...chips.map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: c),
            ),
            ActionChip(
              label: const Text('Clear all', style: TextStyle(fontSize: 12)),
              onPressed: () => projects.clearFilters(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: p.border),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: p.indigo,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: p.indigoLight,
      deleteIcon: Icon(Icons.close, size: 14, color: p.indigo),
      onDeleted: onRemove,
      elevation: 0,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
