import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dialogs.dart';

Future<void> savePdfBytes(
  BuildContext context,
  List<int> bytes,
  String fileName,
) async {
  try {
    final sanitizedFileName = fileName.endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';

    final Uri? resultPath = await FilePicker.saveFile(
      dialogTitle: 'Save CV',
      fileName: sanitizedFileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: Uint8List.fromList(bytes),
    );

    if (resultPath == null) return;

    if (context.mounted) {
      showSuccessDialog(context, 'CV saved');
    }
  } catch (e) {
    if (context.mounted) {
      showErrorDialog(context, 'Could not save your CV: $e');
    }
  }
}
