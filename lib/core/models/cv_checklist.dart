import '../../../core/models/portfolio.dart';

class CvCheck {
  const CvCheck(this.label, this.done);
  final String label;
  final bool done;
}

bool isCvReady(PortfolioData data) => cvChecklist(data).every((c) => c.done);

List<CvCheck> cvChecklist(PortfolioData data) {
  final hasBio = data.bio != null && data.bio!.trim().isNotEmpty;
  final hasPhone =
      data.phoneNumber != null && data.phoneNumber!.trim().isNotEmpty;
  final hasLocation = data.location != null && data.location!.trim().isNotEmpty;
  final hasLink =
      (data.githubUrl != null && data.githubUrl!.trim().isNotEmpty) ||
      (data.linkedinUrl != null && data.linkedinUrl!.trim().isNotEmpty);
  final hasWork = data.projects.isNotEmpty || data.education.isNotEmpty;

  return [
    CvCheck('Add a bio', hasBio),
    CvCheck('Add a contact number', hasPhone),
    CvCheck('Add a location', hasLocation),
    CvCheck('Add a GitHub or LinkedIn link', hasLink),
    CvCheck('Add at least one project or Education listed', hasWork),
  ];
}

String cvFileName(PortfolioData data) {
  final safeName = data.name.trim().isEmpty
      ? 'cv'
      : data.name.trim().replaceAll(RegExp(r'\s+'), '_');
  return '${safeName}_CV.pdf';
}
