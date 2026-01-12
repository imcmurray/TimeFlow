import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

/// Exports JSON content by triggering a browser download.
Future<ExportResult> exportJsonFile(String content, String fileName) async {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);

    return const ExportResult(success: true);
  } catch (e) {
    return ExportResult(success: false, error: e.toString());
  }
}

/// Picks a JSON file using browser file input.
Future<ImportResult> pickAndReadJsonFile() async {
  try {
    final completer = Completer<ImportResult>();

    final input = html.FileUploadInputElement()..accept = '.json';

    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(
          const ImportResult(success: false, error: 'No file selected'),
        );
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        final content = reader.result as String?;
        if (content != null) {
          completer.complete(ImportResult(success: true, content: content));
        } else {
          completer.complete(
            const ImportResult(success: false, error: 'Failed to read file'),
          );
        }
      });

      reader.onError.listen((event) {
        completer.complete(
          ImportResult(success: false, error: 'Error reading file: ${reader.error}'),
        );
      });

      reader.readAsText(file);
    });

    input.click();

    return completer.future;
  } catch (e) {
    return ImportResult(success: false, error: e.toString());
  }
}
