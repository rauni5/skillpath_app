import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/models/skill.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/cv_generator.dart';
import '../data/save_pdf.dart';
import '../../../core/models/cv_checklist.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/add_certification_sheet.dart';
import '../widgets/add_education_sheet.dart';
import '../widgets/cv_menu_button.dart';
import '../widgets/portfolio_widgets.dart';
import '../widgets/profile_incomplete_dialog.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, this.userId});
  final int? userId;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with WidgetsBindingObserver {
  bool _generatingCv = false;
  Timer? _refreshTimer;
  bool _isSelf = true;
  static const _refreshInterval = Duration(seconds: 20);

  int? get _targetUserId =>
      widget.userId ?? context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    _isSelf = widget.userId == null || widget.userId == currentUserId;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    if (_isSelf) _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isSelf) return;
    if (state == AppLifecycleState.resumed) {
      _load();
      _startRefreshTimer();
    } else {
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _targetUserId;
    if (userId == null) return;
    await context.read<PortfolioProvider>().load(userId);
  }

  Future<void> _downloadCv(PortfolioData data) async {
    setState(() => _generatingCv = true);
    try {
      final bytes = await buildCvPdf(data);
      if (!mounted) return;
      await savePdfBytes(context, bytes, cvFileName(data));
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, 'Could not generate your CV. Try again.');
    } finally {
      if (mounted) setState(() => _generatingCv = false);
    }
  }

  void _previewCv(PortfolioData data) {
    context.push('/profile/cv-preview', extra: data);
  }

  Future<void> _handleCvTap(PortfolioData data) async {
    if (isCvReady(data)) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ProfileIncompleteDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelf ? 'Portfolio' : (portfolio.data?.name ?? 'Portfolio'),
        ),
        actions: [
          if (_isSelf && portfolio.data != null)
            CvMenuButton(
              data: portfolio.data!,
              generating: _generatingCv,
              onIncompleteTap: () => _handleCvTap(portfolio.data!),
              onPreview: () => _previewCv(portfolio.data!),
              onDownload: () => _downloadCv(portfolio.data!),
            ),
          if (_isSelf)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/profile/settings'),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: switch (portfolio.state) {
            PortfolioLoadState.initial ||
            PortfolioLoadState.loading => const LoadingView(),
            PortfolioLoadState.error => ErrorView(
              message: portfolio.errorMessage ?? 'Something went wrong.',
              onRetry: _load,
            ),
            PortfolioLoadState.loaded => _PortfolioBody(
              data: portfolio.data!,
              isSelf: _isSelf,
              onAddEducation: _addEducation,
              onDeleteEducation: _deleteEducation,
              onAddCertification: _addCertification,
              onDeleteCertification: _deleteCertification,
            ),
          },
        ),
      ),
    );
  }

  Future<void> _addEducation() async {
    final result = await showModalBottomSheet<NewEducation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddEducationSheet(),
    );
    if (result == null || !mounted) return;

    final ok = await context.read<PortfolioProvider>().addEducation(
      institution: result.institution,
      degree: result.degree,
      fieldOfStudy: result.fieldOfStudy,
      startDate: result.startDate,
      endDate: result.endDate,
      description: result.description,
    );
    if (!mounted) return;
    if (!ok) {
      final message = context.read<PortfolioProvider>().mutationError;
      showErrorDialog(context, message ?? 'Could not add education.');
    }
  }

  Future<void> _deleteEducation(int eduId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove education entry?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<PortfolioProvider>().deleteEducation(eduId);
    if (!mounted) return;
    if (!ok) {
      final message = context.read<PortfolioProvider>().mutationError;
      showErrorDialog(context, message ?? 'Could not remove education.');
    }
  }

  Future<void> _addCertification() async {
    final result = await showModalBottomSheet<NewCertification>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCertificationSheet(),
    );
    if (result == null || !mounted) return;

    final ok = await context.read<PortfolioProvider>().addCertification(
      name: result.name,
      issuer: result.issuer,
      credentialUrl: result.credentialUrl,
      earnedOn: result.earnedOn,
    );
    if (!mounted) return;
    if (!ok) {
      final message = context.read<PortfolioProvider>().mutationError;
      showErrorDialog(context, message ?? 'Could not add certification.');
    }
  }

  Future<void> _deleteCertification(int certId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove certification?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<PortfolioProvider>().deleteCertification(
      certId,
    );
    if (!mounted) return;
    if (!ok) {
      final message = context.read<PortfolioProvider>().mutationError;
      showErrorDialog(context, message ?? 'Could not remove certification.');
    }
  }
}

class _PortfolioBody extends StatefulWidget {
  const _PortfolioBody({
    required this.data,
    required this.isSelf,
    required this.onAddEducation,
    required this.onDeleteEducation,
    required this.onAddCertification,
    required this.onDeleteCertification,
  });

  final PortfolioData data;
  final bool isSelf;
  final VoidCallback onAddEducation;
  final void Function(int eduId) onDeleteEducation;
  final VoidCallback onAddCertification;
  final void Function(int certId) onDeleteCertification;

  @override
  State<_PortfolioBody> createState() => _PortfolioBodyState();
}

class _PortfolioBodyState extends State<_PortfolioBody> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioProvider>();
    final p = AppPalette.of(context);
    final data = widget.data;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: data.avatarUrl,
                initials: data.initials,
                radius: 40,
                ringColor: p.surface0,
                ringWidth: 3,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('${data.projects.length}', 'Projects', p),
                    _buildStatColumn(
                      '${data.education.length}',
                      'Education',
                      p,
                    ),
                    _buildStatColumn(
                      '${data.certifications.length}',
                      'Certs',
                      p,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: p.textPrimary,
                ),
              ),
              if (data.bio != null && data.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  data.bio!,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    data.email,
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                  if (data.phoneNumber != null &&
                      data.phoneNumber!.trim().isNotEmpty)
                    Text(
                      '• ${data.phoneNumber!}',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  if (data.location != null && data.location!.trim().isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: p.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          data.location!,
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                      ],
                    ),
                ],
              ),
              if ((data.githubUrl != null &&
                      data.githubUrl!.trim().isNotEmpty) ||
                  (data.linkedinUrl != null &&
                      data.linkedinUrl!.trim().isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (data.githubUrl != null &&
                          data.githubUrl!.trim().isNotEmpty)
                        LinkChip(
                          icon: Icons.code,
                          label:
                              extractProfileUsername(data.githubUrl) ??
                              'GitHub',
                          url: data.githubUrl!,
                        ),
                      if (data.linkedinUrl != null &&
                          data.linkedinUrl!.trim().isNotEmpty)
                        LinkChip(
                          icon: Icons.business_center_outlined,
                          label:
                              extractProfileUsername(data.linkedinUrl) ??
                              'LinkedIn',
                          url: data.linkedinUrl!,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatusPill(
                  icon: Icons.bar_chart_rounded,
                  label: _experienceLabel(data.experienceLevel),
                  background: p.indigoLight,
                  foreground: p.indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatusPill(
                  icon: data.availability
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  label: data.availability ? 'Available' : 'Unavailable',
                  background: data.availability ? p.greenLight : p.surface1,
                  foreground: data.availability ? p.greenText : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (data.careerGoalRoleName != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: p.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal: ${data.careerGoalRoleName!}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedProgressBar(
                            value: data.careerProgressPercent / 100,
                            backgroundColor: p.surface1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${data.careerProgressPercent}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: p.border, width: 1),
              bottom: BorderSide(color: p.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildTabItem(0, Icons.grid_on_outlined, 'Projects', p),
              _buildTabItem(1, Icons.school_outlined, 'Education', p),
              _buildTabItem(2, Icons.verified_outlined, 'Certs', p),
              _buildTabItem(3, Icons.psychology_outlined, 'Skills', p),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_selectedTab) {
            0 => _buildProjectsTab(data, p),
            1 => _buildEducationTab(data, portfolio, p),
            2 => _buildCertificationsTab(data, portfolio, p),
            3 => _buildSkillsTab(data, p),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(String count, String label, AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
      ],
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, AppPalette p) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? p.indigo : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? p.indigo : p.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab(PortfolioData data, AppPalette p) {
    if (data.projects.isEmpty) {
      return _emptyCard(
        p,
        'No projects yet — join or start one to build your portfolio.',
      );
    }
    return Column(
      children: data.projects
          .map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PortfolioProjectTile(
                project: project,
                onTap: () => context.push('/projects/${project.id}'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEducationTab(
    PortfolioData data,
    PortfolioProvider portfolio,
    AppPalette p,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(label: 'EDUCATION', icon: Icons.school_outlined),
            if (widget.isSelf)
              IconButton(
                icon: portfolio.mutating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                tooltip: 'Add education',
                onPressed: portfolio.mutating ? null : widget.onAddEducation,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.education.isEmpty)
          _emptyCard(
            p,
            'No education added yet — add a school or program to round out your CV.',
          )
        else
          SectionCard(
            child: Column(
              children: [
                for (final edu in data.education) ...[
                  if (edu != data.education.first) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                edu.institution,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                              if ((edu.degree != null &&
                                      edu.degree!.isNotEmpty) ||
                                  (edu.fieldOfStudy != null &&
                                      edu.fieldOfStudy!.isNotEmpty)) ...[
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (edu.degree != null &&
                                        edu.degree!.isNotEmpty)
                                      edu.degree!,
                                    if (edu.fieldOfStudy != null &&
                                        edu.fieldOfStudy!.isNotEmpty)
                                      edu.fieldOfStudy!,
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                              if (edu.startDate != null || edu.isOngoing) ...[
                                const SizedBox(height: 2),
                                Text(
                                  edu.startDate == null
                                      ? 'Ongoing'
                                      : '${_formatDate(edu.startDate!)} – ${edu.endDate == null ? 'Present' : _formatDate(edu.endDate!)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                              if (edu.description != null &&
                                  edu.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  edu.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.isSelf)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: p.textMuted,
                            ),
                            tooltip: 'Remove',
                            onPressed: () => widget.onDeleteEducation(edu.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCertificationsTab(
    PortfolioData data,
    PortfolioProvider portfolio,
    AppPalette p,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              label: 'CERTIFICATIONS',
              icon: Icons.verified_outlined,
            ),
            if (widget.isSelf)
              IconButton(
                icon: portfolio.mutating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                tooltip: 'Add certification',
                onPressed: portfolio.mutating
                    ? null
                    : widget.onAddCertification,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.certifications.isEmpty)
          _emptyCard(
            p,
            widget.isSelf
                ? 'No certifications added yet.'
                : 'No certifications listed.',
          )
        else
          SectionCard(
            child: Column(
              children: [
                for (final cert in data.certifications) ...[
                  if (cert != data.certifications.first)
                    const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                              if ((cert.issuer != null &&
                                      cert.issuer!.isNotEmpty) ||
                                  cert.earnedOn != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (cert.issuer != null &&
                                        cert.issuer!.isNotEmpty)
                                      cert.issuer!,
                                    if (cert.earnedOn != null)
                                      _formatDate(cert.earnedOn!),
                                  ].join('  ·  '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                              if (cert.credentialUrl != null &&
                                  cert.credentialUrl!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InlineLink(url: cert.credentialUrl!),
                              ],
                            ],
                          ),
                        ),
                        if (widget.isSelf)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: p.textMuted,
                            ),
                            tooltip: 'Remove',
                            onPressed: () =>
                                widget.onDeleteCertification(cert.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsTab(PortfolioData data, AppPalette p) {
    final skillsByCategory = <String, List<SkillWithProficiency>>{};
    for (final s in data.skills) {
      skillsByCategory.putIfAbsent(s.category.label, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label: 'TECHNICAL SKILLS',
          icon: Icons.psychology_outlined,
        ),
        const SizedBox(height: 8),
        if (skillsByCategory.isEmpty)
          _emptyCard(p, 'No skills added yet.')
        else
          SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in skillsByCategory.entries) ...[
                    if (entry.key != skillsByCategory.keys.first)
                      const SizedBox(height: 12),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.value
                          .map((s) => _proficiencyChip(p, s))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (data.softSkills.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionHeader(label: 'SOFT SKILLS', icon: Icons.diversity_3_outlined),
          const SizedBox(height: 8),
          SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: data.softSkills
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Widget _emptyCard(AppPalette p, String message) {
    return SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(fontSize: 12.5, color: p.textMuted),
        ),
      ),
    );
  }

  Widget _proficiencyChip(AppPalette p, SkillWithProficiency s) {
    final (bg, fg) = switch (s.proficiency) {
      SkillProficiency.beginner => (p.surface1, p.textSecondary),
      SkillProficiency.intermediate => (p.amberLight, p.amberText),
      SkillProficiency.advanced => (p.greenLight, p.greenText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${s.name} · ${s.proficiency.shortLabel}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  String _experienceLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }
}
