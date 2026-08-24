import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/portfolio.dart';
import '../../../core/models/project.dart';
import '../../../core/models/skill.dart';

Future<Uint8List> buildCvPdf(PortfolioData data) async {
  final doc = pw.Document();

  final skillsByCategory = <SkillCategory, List<SkillWithProficiency>>{};
  for (final s in data.skills) {
    skillsByCategory.putIfAbsent(s.category, () => []).add(s);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      build: (context) => [
        _header(data),
        pw.SizedBox(height: 18),

        if (data.bio != null && data.bio!.trim().isNotEmpty) ...[
          _sectionBar('CAREER OBJECTIVE'),
          pw.SizedBox(height: 8),
          pw.Text(data.bio!, style: const pw.TextStyle(fontSize: 10.5)),
          pw.SizedBox(height: 16),
        ],

        if (data.education.isNotEmpty) ...[
          _sectionBar('EDUCATION'),
          pw.SizedBox(height: 10),
          ...data.education.map(_educationEntry),
          pw.SizedBox(height: 4),
        ],

        if (skillsByCategory.isNotEmpty) ...[
          _sectionBar('TECHNICAL SKILLS'),
          pw.SizedBox(height: 10),
          ...skillsByCategory.entries.map(_skillCategoryLine),
          pw.SizedBox(height: 16),
        ],

        if (data.softSkills.isNotEmpty) ...[
          _sectionBar('SOFT SKILLS'),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 4,
            children: [
              for (var i = 0; i < data.softSkills.length; i++)
                pw.Bullet(
                  text: data.softSkills[i],
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
            ],
          ),
          pw.SizedBox(height: 16),
        ],

        if (data.projects.isNotEmpty) ...[
          _sectionBar('PROJECTS'),
          pw.SizedBox(height: 10),
          ...data.projects.map((project) => _projectEntry(project, data)),
          pw.SizedBox(height: 4),
        ],

        if (data.portfolioItems.isNotEmpty) ...[
          _sectionBar('PORTFOLIO'),
          pw.SizedBox(height: 10),
          ...data.portfolioItems.map(_portfolioItemEntry),
          pw.SizedBox(height: 4),
        ],

        if (data.certifications.isNotEmpty) ...[
          _sectionBar('CERTIFICATIONS'),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1.4),
            },
            children: data.certifications
                .map(
                  (cert) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: _certificationLine(cert),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          cert.earnedOn == null
                              ? ''
                              : _formatDate(cert.earnedOn!),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

//Header

pw.Widget _header(PortfolioData data) {
  final muted = PdfColor.fromInt(0xFF525252);
  final link = PdfColor.fromInt(0xFF1D4ED8);

  final contactParts = <String>[
    if (data.location != null && data.location!.trim().isNotEmpty)
      data.location!.trim(),
    data.email,
    if (data.phoneNumber != null && data.phoneNumber!.trim().isNotEmpty)
      data.phoneNumber!.trim(),
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        data.name.toUpperCase(),
        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        contactParts.join('  |  '),
        style: pw.TextStyle(fontSize: 10, color: muted),
      ),
      if ((data.githubUrl != null && data.githubUrl!.trim().isNotEmpty) ||
          (data.linkedinUrl != null && data.linkedinUrl!.trim().isNotEmpty))
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Wrap(
            spacing: 16,
            children: [
              if (data.githubUrl != null && data.githubUrl!.trim().isNotEmpty)
                pw.UrlLink(
                  destination: data.githubUrl!,
                  child: pw.Text(
                    'GitHub: ${extractProfileUsername(data.githubUrl) ?? _displayUrl(data.githubUrl!)}',
                    style: pw.TextStyle(fontSize: 10, color: link),
                  ),
                ),
              if (data.linkedinUrl != null &&
                  data.linkedinUrl!.trim().isNotEmpty)
                pw.UrlLink(
                  destination: data.linkedinUrl!,
                  child: pw.Text(
                    'LinkedIn: ${extractProfileUsername(data.linkedinUrl) ?? _displayUrl(data.linkedinUrl!)}',
                    style: pw.TextStyle(fontSize: 10, color: link),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Strips "https://" and a trailing slash so a raw fallback link still
/// reads cleanly ("github.com/rauni5" rather than "https://github.com/rauni5/").
String _displayUrl(String url) {
  return url
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/$'), '');
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

//Section header bar

pw.Widget _sectionBar(String label) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFE5E5E5),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 11.5,
        fontWeight: pw.FontWeight.bold,
        fontStyle: pw.FontStyle.italic,
      ),
    ),
  );
}

//Technical skills: "Category: skill, skill, skill"

pw.Widget _skillCategoryLine(
  MapEntry<SkillCategory, List<SkillWithProficiency>> entry,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '${entry.key.label}: ',
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: entry.value.map((s) => s.name).join(', '),
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        ],
      ),
    ),
  );
}

//Projects

pw.Widget _projectEntry(Project project, PortfolioData data) {
  final isOwner = project.ownerId == data.userId;
  final link = PdfColor.fromInt(0xFF1D4ED8);
  final hasLink = project.link != null && project.link!.trim().isNotEmpty;

  final nameText = pw.Text(
    project.name,
    style: pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      decoration: pw.TextDecoration.underline,
      color: hasLink ? link : PdfColors.black,
    ),
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            hasLink
                ? pw.UrlLink(destination: project.link!, child: nameText)
                : nameText,
            pw.Text(
              isOwner ? 'Owner' : 'Contributor',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ],
        ),
        if (project.requiredSkills.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Technologies used: ',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.TextSpan(
                    text: project.requiredSkills.map((s) => s.name).join(', '),
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ],
              ),
            ),
          ),
        if (project.description != null &&
            project.description!.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3, left: 10),
            child: pw.Bullet(
              text: project.description!,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
      ],
    ),
  );
}

//Education

pw.Widget _educationEntry(Education edu) {
  final subtitleParts = <String>[
    if (edu.degree != null && edu.degree!.isNotEmpty) edu.degree!,
    if (edu.fieldOfStudy != null && edu.fieldOfStudy!.isNotEmpty)
      edu.fieldOfStudy!,
  ];
  final dateRange = edu.startDate == null
      ? ''
      : '${_formatDate(edu.startDate!)} - '
            '${edu.endDate == null ? 'Present' : _formatDate(edu.endDate!)}';

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              edu.institution,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (dateRange.isNotEmpty)
              pw.Text(dateRange, style: const pw.TextStyle(fontSize: 9.5)),
          ],
        ),
        if (subtitleParts.isNotEmpty)
          pw.Text(
            subtitleParts.join(', '),
            style: const pw.TextStyle(fontSize: 10),
          ),
        if (edu.description != null && edu.description!.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, left: 10),
            child: pw.Bullet(
              text: edu.description!,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
      ],
    ),
  );
}

//Portfolio items

pw.Widget _portfolioItemEntry(PortfolioItem item) {
  final link = PdfColor.fromInt(0xFF1D4ED8);
  final hasLink = item.githubUrl != null && item.githubUrl!.isNotEmpty;

  final titleText = pw.Text(
    item.projectName ?? item.userRole ?? 'Portfolio item',
    style: pw.TextStyle(
      fontSize: 10.5,
      fontWeight: pw.FontWeight.bold,
      decoration: pw.TextDecoration.underline,
      color: hasLink ? link : PdfColors.black,
    ),
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        hasLink
            ? pw.UrlLink(destination: item.githubUrl!, child: titleText)
            : titleText,
        if (item.description != null && item.description!.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, left: 10),
            child: pw.Bullet(
              text: item.description!,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
      ],
    ),
  );
}

//Certifications

pw.Widget _certificationLine(Certification cert) {
  final link = PdfColor.fromInt(0xFF1D4ED8);
  final hasLink = cert.credentialUrl != null && cert.credentialUrl!.isNotEmpty;
  final subtitle = cert.issuer == null || cert.issuer!.isEmpty
      ? ''
      : ' - ${cert.issuer}';

  final text = pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: cert.name,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: hasLink ? link : PdfColors.black,
            decoration: hasLink ? pw.TextDecoration.underline : null,
          ),
        ),
        pw.TextSpan(text: subtitle, style: const pw.TextStyle(fontSize: 10.5)),
      ],
    ),
  );

  return hasLink
      ? pw.UrlLink(destination: cert.credentialUrl!, child: text)
      : text;
}
