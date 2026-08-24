import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/models/project.dart';
import '../../../core/models/skill.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/cv_generator.dart';
import '../providers/portfolio_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with WidgetsBindingObserver {
  bool _generatingCv = false;
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep polling while the app is backgrounded.
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
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<PortfolioProvider>().load(userId);
  }

  Future<void> _downloadCv(PortfolioData data) async {
    setState(() => _generatingCv = true);
    try {
      final bytes = await buildCvPdf(data);
      final fileName =
          '${data.name.trim().isEmpty ? 'cv' : data.name.trim().replaceAll(' ', '_')}_CV.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate your CV. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _generatingCv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
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
            generatingCv: _generatingCv,
            onDownloadCv: () => _downloadCv(portfolio.data!),
            onAddEducation: _addEducation,
            onDeleteEducation: _deleteEducation,
            onAddCertification: _addCertification,
            onDeleteCertification: _deleteCertification,
          ),
        },
      ),
    );
  }

  Future<void> _addEducation() async {
    final result = await showModalBottomSheet<_NewEducation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddEducationSheet(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Could not add education.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Could not remove education.')),
      );
    }
  }

  Future<void> _addCertification() async {
    final result = await showModalBottomSheet<_NewCertification>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCertificationSheet(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Could not add certification.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Could not remove certification.')),
      );
    }
  }
}

class _PortfolioBody extends StatelessWidget {
  const _PortfolioBody({
    required this.data,
    required this.generatingCv,
    required this.onDownloadCv,
    required this.onAddEducation,
    required this.onDeleteEducation,
    required this.onAddCertification,
    required this.onDeleteCertification,
  });

  final PortfolioData data;
  final bool generatingCv;
  final VoidCallback onDownloadCv;
  final VoidCallback onAddEducation;
  final void Function(int eduId) onDeleteEducation;
  final VoidCallback onAddCertification;
  final void Function(int certId) onDeleteCertification;

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioProvider>();
    final p = AppPalette.of(context);
    final skillsByCategory = <String, List<SkillWithProficiency>>{};
    for (final s in data.skills) {
      skillsByCategory.putIfAbsent(s.category.label, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Header ---
        SizedBox(
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.indigo, p.indigoTint],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface0,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: p.indigoLight,
                      child: Text(
                        data.initials,
                        style: TextStyle(
                          color: p.indigo,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            data.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: p.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                data.email,
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
              if (data.phoneNumber != null &&
                  data.phoneNumber!.trim().isNotEmpty) ...[
                Text('·', style: TextStyle(fontSize: 12.5, color: p.textMuted)),
                Text(
                  data.phoneNumber!,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (data.location != null && data.location!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 13, color: p.textMuted),
                const SizedBox(width: 3),
                Text(
                  data.location!,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
        if ((data.githubUrl != null && data.githubUrl!.trim().isNotEmpty) ||
            (data.linkedinUrl != null && data.linkedinUrl!.trim().isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Wrap(
                spacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  if (data.githubUrl != null &&
                      data.githubUrl!.trim().isNotEmpty)
                    _LinkChip(
                      icon: Icons.code,
                      label: extractProfileUsername(data.githubUrl) ?? 'GitHub',
                      url: data.githubUrl!,
                    ),
                  if (data.linkedinUrl != null &&
                      data.linkedinUrl!.trim().isNotEmpty)
                    _LinkChip(
                      icon: Icons.business_center_outlined,
                      label:
                          extractProfileUsername(data.linkedinUrl) ??
                          'LinkedIn',
                      url: data.linkedinUrl!,
                    ),
                ],
              ),
            ),
          ),
        if (data.bio != null && data.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            data.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            children: [
              _StatusPill(
                icon: Icons.bar_chart_rounded,
                label: _experienceLabel(data.experienceLevel),
                background: p.indigoLight,
                foreground: p.indigo,
              ),
              _StatusPill(
                icon: data.availability
                    ? Icons.check_circle
                    : Icons.remove_circle_outline,
                label: data.availability ? 'Available' : 'Not available',
                background: data.availability ? p.greenLight : p.surface1,
                foreground: data.availability ? p.greenText : p.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            onPressed: generatingCv ? null : onDownloadCv,
            icon: generatingCv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_outlined, size: 18),
            label: Text(generatingCv ? 'Preparing CV…' : 'Download CV'),
          ),
        ),
        const SizedBox(height: 28),

        // --- Career goal progress ---
        if (data.careerGoalRoleName != null) ...[
          SectionHeader(label: 'CAREER GOAL', icon: Icons.flag_outlined),
          const SizedBox(height: 8),
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.careerGoalRoleName!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedProgressBar(
                    value: data.careerProgressPercent / 100,
                    backgroundColor: p.surface1,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.careerProgressPercent}% ready',
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // --- Skills ---
        SectionHeader(label: 'SKILLS', icon: Icons.psychology_outlined),
        const SizedBox(height: 8),
        if (skillsByCategory.isEmpty)
          _emptyCard(p, 'No skills added yet.')
        else
          _SectionCard(
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
        const SizedBox(height: 24),

        // --- Soft skills ---
        if (data.softSkills.isNotEmpty) ...[
          SectionHeader(label: 'SOFT SKILLS', icon: Icons.diversity_3_outlined),
          const SizedBox(height: 8),
          _SectionCard(
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
          const SizedBox(height: 24),
        ],

        // --- Projects ---
        SectionHeader(label: 'PROJECTS', icon: Icons.groups_outlined),
        const SizedBox(height: 8),
        if (data.projects.isEmpty)
          _emptyCard(
            p,
            'No projects yet — join or start one to build your portfolio.',
          )
        else
          ...data.projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PortfolioProjectTile(
                project: project,
                onTap: () => context.push('/projects/${project.id}'),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // --- Education ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(label: 'EDUCATION', icon: Icons.school_outlined),
            IconButton(
              icon: portfolio.mutating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              tooltip: 'Add education',
              onPressed: portfolio.mutating ? null : onAddEducation,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (data.education.isEmpty)
          _emptyCard(
            p,
            'No education added yet — add a school or program to round out your CV.',
          )
        else
          _SectionCard(
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
                                      : '${_formatDate(edu.startDate!)} – '
                                            '${edu.endDate == null ? 'Present' : _formatDate(edu.endDate!)}',
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
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: p.textMuted,
                          ),
                          tooltip: 'Remove',
                          onPressed: () => onDeleteEducation(edu.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),

        // --- Certifications ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              label: 'CERTIFICATIONS',
              icon: Icons.verified_outlined,
            ),
            IconButton(
              icon: portfolio.mutating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              tooltip: 'Add certification',
              onPressed: portfolio.mutating ? null : onAddCertification,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (data.certifications.isEmpty)
          _emptyCard(p, 'No certifications added yet.')
        else
          _SectionCard(
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
                                _InlineLink(url: cert.credentialUrl!),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: p.textMuted,
                          ),
                          tooltip: 'Remove',
                          onPressed: () => onDeleteCertification(cert.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
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
    return _SectionCard(
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

// --- Add education ---

class _NewEducation {
  _NewEducation({
    required this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.description,
  });
  final String institution;
  final String? degree;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
}

class _AddEducationSheet extends StatefulWidget {
  const _AddEducationSheet();

  @override
  State<_AddEducationSheet> createState() => _AddEducationSheetState();
}

class _AddEducationSheetState extends State<_AddEducationSheet> {
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _ongoing = false;

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add education',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _institutionController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Institution',
              hintText: 'University of Example',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _degreeController,
            maxLength: 150,
            decoration: const InputDecoration(
              labelText: 'Degree',
              hintText: 'B.Sc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fieldController,
            maxLength: 150,
            decoration: const InputDecoration(
              labelText: 'Field of study',
              hintText: 'Computer Science',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isStart: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate == null ? 'Select' : _formatYmd(_startDate!),
                      style: TextStyle(
                        color: _startDate == null ? p.textMuted : p.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _ongoing ? null : () => _pickDate(isStart: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End date',
                      border: const OutlineInputBorder(),
                      enabled: !_ongoing,
                    ),
                    child: Text(
                      _ongoing
                          ? 'Present'
                          : (_endDate == null
                                ? 'Select'
                                : _formatYmd(_endDate!)),
                      style: TextStyle(
                        color: _endDate == null && !_ongoing
                            ? p.textMuted
                            : p.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          CheckboxListTile(
            value: _ongoing,
            onChanged: (v) => setState(() {
              _ongoing = v ?? false;
              if (_ongoing) _endDate = null;
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              "I'm currently studying here",
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Add')),
          ),
        ],
      ),
    );
  }

  String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _submit() {
    final institution = _institutionController.text.trim();
    final degree = _degreeController.text.trim();
    final field = _fieldController.text.trim();
    if (institution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Institution name is required.')),
      );
      return;
    }
    if (degree.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Degree name is required.')));
      return;
    }
    if (field.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Field name is required.')));
      return;
    }
    Navigator.of(context).pop(
      _NewEducation(
        institution: institution,
        degree: degree,
        fieldOfStudy: field,
        startDate: _startDate,
        endDate: _ongoing ? null : _endDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }
}

/// Small tappable pill for an external profile link
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: p.indigo.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Small icon + label pill used for the experience-level and
/// availability indicators under the profile header.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $label link.')));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: p.indigo),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: p.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A project card for the Portfolio screen
class _PortfolioProjectTile extends StatelessWidget {
  const _PortfolioProjectTile({required this.project, required this.onTap});
  final Project project;
  final VoidCallback onTap;

  Future<void> _openLink(BuildContext context) async {
    final link = project.link;
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _statusBadge(AppPalette p) {
    final (bg, fg, label) = switch (project.status) {
      ProjectStatus.open => (p.greenLight, p.greenText, 'Open'),
      ProjectStatus.full => (p.amberLight, p.amberText, 'Full'),
      ProjectStatus.completed => (p.surface1, p.textSecondary, 'Completed'),
      ProjectStatus.cancelled => (p.redLight, p.red, 'Cancelled'),
      ProjectStatus.unknown => (p.surface1, p.textSecondary, '—'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hasLink = project.link != null && project.link!.trim().isNotEmpty;

    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: hasLink
                        ? InkWell(
                            onTap: () => _openLink(context),
                            child: Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: p.indigo,
                                decoration: TextDecoration.underline,
                                decorationColor: p.indigo,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            project.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(p),
                ],
              ),
              if (project.description != null &&
                  project.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project.description!,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
              if (project.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Technologies used: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: project.requiredSkills
                            .map((s) => s.name)
                            .join(', '),
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline tappable URL text, used for the certification credential link.
class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.url});
  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: () => _open(context),
      child: Text(
        extractProfileUsername(url) ?? url,
        style: TextStyle(fontSize: 12, color: p.indigo),
      ),
    );
  }
}

//add certification

class _NewCertification {
  _NewCertification({
    required this.name,
    this.issuer,
    this.credentialUrl,
    this.earnedOn,
  });
  final String name;
  final String? issuer;
  final String? credentialUrl;
  final DateTime? earnedOn;
}

class _AddCertificationSheet extends StatefulWidget {
  const _AddCertificationSheet();

  @override
  State<_AddCertificationSheet> createState() => _AddCertificationSheetState();
}

class _AddCertificationSheetState extends State<_AddCertificationSheet> {
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _urlController = TextEditingController();
  DateTime? _earnedOn;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _earnedOn ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) setState(() => _earnedOn = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certification name is required.')),
      );
      return;
    }
    Navigator.of(context).pop(
      _NewCertification(
        name: name,
        issuer: _issuerController.text.trim().isEmpty
            ? null
            : _issuerController.text.trim(),
        credentialUrl: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        earnedOn: _earnedOn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add certification',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'AWS Certified Cloud Practitioner',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _issuerController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Issuer (optional)',
              hintText: 'Amazon Web Services',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Credential link (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date earned (optional)',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _earnedOn == null
                    ? 'Select a date'
                    : '${_earnedOn!.year}-${_earnedOn!.month.toString().padLeft(2, '0')}-${_earnedOn!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _earnedOn == null ? p.textMuted : p.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Add')),
          ),
        ],
      ),
    );
  }
}
