import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Saves a backup file where the user chooses (a save dialog on desktop and
/// mobile, a download on the web). Returns false if they cancelled.
Future<bool> saveBackupFile(String json, String fileName) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: utf8.encode(json),
    mimeType: 'application/json',
    type: FileType.custom,
    allowedExtensions: const ['json'],
    dialogTitle: 'Save TimeFlow backup',
  );
  return uri != null;
}

/// Lets the user pick a backup file and returns its text, or null if they
/// cancelled.
Future<String?> pickBackupFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    dialogTitle: 'Restore TimeFlow backup',
  );
  return file?.xFile.readAsString();
}
