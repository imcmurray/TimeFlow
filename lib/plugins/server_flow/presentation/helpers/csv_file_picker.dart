import 'package:file_picker/file_picker.dart';

/// Lets the user pick a CSV (or TSV) file and returns its text, or null if
/// they cancelled. Works on every platform, including the web.
Future<String?> pickCsvFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'tsv', 'txt'],
    dialogTitle: 'Import scheduled jobs',
  );
  return file?.xFile.readAsString();
}
