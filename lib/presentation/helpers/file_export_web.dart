import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    web.URL.revokeObjectURL(url);

    return const ExportResult(success: true);
  } catch (e) {
    return ExportResult(success: false, error: e.toString());
  }
}

/// Picks a JSON file using browser file input.
Future<ImportResult> pickAndReadJsonFile() async {
  try {
    final completer = Completer<ImportResult>();

    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = '.json';

    input.onchange = (web.Event event) {
      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(
          const ImportResult(success: false, error: 'No file selected'),
        );
        return;
      }

      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.onloadend = (web.ProgressEvent event) {
        final content = (reader.result as JSString?)?.toDart;
        if (content != null) {
          completer.complete(ImportResult(success: true, content: content));
        } else {
          completer.complete(
            const ImportResult(success: false, error: 'Failed to read file'),
          );
        }
      }.toJS;

      reader.onerror = (web.Event event) {
        completer.complete(
          const ImportResult(success: false, error: 'Error reading file'),
        );
      }.toJS;

      reader.readAsText(file);
    }.toJS;

    input.click();

    return completer.future;
  } catch (e) {
    return ImportResult(success: false, error: e.toString());
  }
}
