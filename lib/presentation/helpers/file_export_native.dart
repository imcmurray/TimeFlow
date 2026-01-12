import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result of an export operation.
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });
}

/// Result of an import operation.
class ImportResult {
  final bool success;
  final String? content;
  final String? error;

  const ImportResult({
    required this.success,
    this.content,
    this.error,
  });
}

/// Exports JSON content to a file.
/// On Linux: Saves to ~/Documents
/// On other platforms: Opens share dialog
Future<ExportResult> exportJsonFile(String content, String fileName) async {
  try {
    if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME'] ?? '/tmp';
      final documentsDir = Directory('$homeDir/Documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsString(content);
      return ExportResult(success: true, filePath: file.path);
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: 'TimeFlow Backup');
      return const ExportResult(success: true);
    }
  } catch (e) {
    return ExportResult(success: false, error: e.toString());
  }
}

/// Picks a JSON file and returns its content.
Future<ImportResult> pickAndReadJsonFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return const ImportResult(success: false, error: 'No file selected');
    }

    final path = result.files.single.path;
    if (path == null) {
      return const ImportResult(success: false, error: 'Invalid file path');
    }

    final file = File(path);
    final content = await file.readAsString();
    return ImportResult(success: true, content: content);
  } catch (e) {
    return ImportResult(success: false, error: e.toString());
  }
}
