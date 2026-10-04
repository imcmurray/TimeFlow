import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Picks a CSV file on native platforms (desktop/mobile).
/// Returns the file contents as a string, or null if cancelled.
Future<String?> pickCsvFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'tsv', 'txt'],
  );

  if (result == null || result.files.isEmpty) return null;

  final path = result.files.single.path;
  if (path == null) return null;

  return File(path).readAsString();
}
