// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

/// Picks a CSV file on web using HTML5 file input.
/// Returns the file contents as a string, or null if cancelled.
Future<String?> pickCsvFile() async {
  final completer = Completer<String?>();

  final input = html.FileUploadInputElement()..accept = '.csv,.tsv,.txt';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsText(files.first);
    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) {
      completer.complete(null);
    });
  });

  return completer.future;
}
