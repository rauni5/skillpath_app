import 'package:flutter/material.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/models/cv_checklist.dart';

class CvMenuButton extends StatelessWidget {
  const CvMenuButton({
    super.key,
    required this.data,
    required this.generating,
    required this.onIncompleteTap,
    required this.onPreview,
    required this.onDownload,
  });

  final PortfolioData data;
  final bool generating;
  final VoidCallback onIncompleteTap;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!isCvReady(data)) {
      return IconButton(
        icon: const Icon(Icons.download_outlined),
        tooltip: 'Complete your profile to export a CV',
        onPressed: onIncompleteTap,
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.download_outlined),
      tooltip: 'Export CV',
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'preview',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_outlined),
            title: Text('Preview CV'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'download',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.download_outlined),
            title: Text('Download CV'),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'preview') onPreview();
        if (value == 'download') onDownload();
      },
    );
  }
}
