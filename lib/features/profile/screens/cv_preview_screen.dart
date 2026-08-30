import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/models/portfolio.dart';
import '../data/cv_generator.dart';

class CvPreviewScreen extends StatelessWidget {
  const CvPreviewScreen({super.key, required this.data});
  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CV Preview')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return PdfPreview(
            build: (format) => buildCvPdf(data),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            maxPageWidth: constraints.maxWidth,
          );
        },
      ),
    );
  }
}
