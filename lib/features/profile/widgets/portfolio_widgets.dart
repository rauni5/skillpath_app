import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
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

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class LinkChip extends StatelessWidget {
  const LinkChip({
    super.key,
    required this.icon,
    required this.label,
    required this.url,
  });
  final IconData icon;
  final String label;
  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        showErrorDialog(context, 'Could not open $label link.');
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

class InlineLink extends StatelessWidget {
  const InlineLink({super.key, required this.url});
  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        showErrorDialog(context, 'Could not open that link.');
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

class PortfolioProjectTile extends StatelessWidget {
  const PortfolioProjectTile({
    super.key,
    required this.project,
    required this.onTap,
  });
  final Project project;
  final VoidCallback onTap;

  Future<void> _openLink(BuildContext context) async {
    final link = project.link;
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        showErrorDialog(context, 'Could not open that link.');
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

    return SectionCard(
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
