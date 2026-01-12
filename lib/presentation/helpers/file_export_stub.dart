/// Stub implementation - should never be used at runtime.
/// Conditional imports will select the correct platform implementation.

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
/// On desktop: Saves to ~/Documents
/// On mobile: Opens share dialog
/// On web: Triggers browser download
Future<ExportResult> exportJsonFile(String content, String fileName) {
  throw UnsupportedError('Cannot export without a platform implementation');
}

/// Picks a JSON file and returns its content.
/// Returns null if user cancels.
Future<ImportResult> pickAndReadJsonFile() {
  throw UnsupportedError('Cannot import without a platform implementation');
}
