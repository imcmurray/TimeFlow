/// Exception thrown when mandatory CSV columns are missing.
class CsvValidationException implements Exception {
  final List<String> missingColumns;

  CsvValidationException(this.missingColumns);

  @override
  String toString() =>
      'CsvValidationException: missing mandatory columns: ${missingColumns.join(', ')}';
}

/// Validates CSV headers against the required column set.
class CsvValidator {
  static const mandatoryColumns = ['host', 'command', 'start_time', 'user'];

  /// Validates that [headers] contain all mandatory columns.
  ///
  /// Headers are expected to be lowercase and trimmed.
  /// Throws [CsvValidationException] listing any missing columns.
  static void validate(List<String> headers) {
    final normalizedHeaders =
        headers.map((h) => h.trim().toLowerCase()).toSet();
    final missing = mandatoryColumns
        .where((col) => !normalizedHeaders.contains(col))
        .toList();

    if (missing.isNotEmpty) {
      throw CsvValidationException(missing);
    }
  }
}
