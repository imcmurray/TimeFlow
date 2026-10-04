import 'package:csv/csv.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/domain/csv_validation.dart';

/// Result of parsing a CSV file.
class CsvParseResult {
  final List<CronJob> jobs;
  final List<CsvParseError> errors;
  final int totalRows;

  const CsvParseResult({
    required this.jobs,
    required this.errors,
    required this.totalRows,
  });
}

/// A non-fatal parsing error for a specific row.
class CsvParseError {
  final int row;
  final String message;

  const CsvParseError({required this.row, required this.message});

  @override
  String toString() => 'Row $row: $message';
}

/// Parses CSV text into [CronJob] objects.
class CsvParser {
  /// Parses [csvText] and returns a [CsvParseResult].
  ///
  /// Uses auto-delimiter detection (comma, semicolon, tab).
  /// Throws [CsvValidationException] if mandatory columns are missing.
  static CsvParseResult parse(String csvText, {String? importBatchId}) {
    final batchId =
        importBatchId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final importedAt = DateTime.now();

    final converter = const CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    );

    // Normalize line endings
    final normalized = csvText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Auto-detect delimiter
    final delimiter = _detectDelimiter(normalized);

    final rows = converter.convert(
      normalized,
      fieldDelimiter: delimiter,
    );

    if (rows.isEmpty) {
      throw CsvValidationException(['host', 'command', 'start_time', 'user']);
    }

    // Parse headers (case-insensitive, trimmed)
    final headers =
        rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

    // Validate mandatory columns
    CsvValidator.validate(headers);

    // Build column index map
    final colIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      colIndex[headers[i]] = i;
    }

    final jobs = <CronJob>[];
    final errors = <CsvParseError>[];
    final dataRows = rows.skip(1).toList();

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNum = i + 2; // 1-indexed, skip header

      // Skip empty rows
      if (row.isEmpty ||
          (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue;
      }

      try {
        final job = _parseRow(row, colIndex, batchId, importedAt, rowNum);
        jobs.add(job);
      } catch (e) {
        errors.add(CsvParseError(row: rowNum, message: e.toString()));
      }
    }

    return CsvParseResult(
      jobs: jobs,
      errors: errors,
      totalRows: dataRows.length,
    );
  }

  static CronJob _parseRow(
    List<dynamic> row,
    Map<String, int> colIndex,
    String batchId,
    DateTime importedAt,
    int rowNum,
  ) {
    String getField(String name) {
      final idx = colIndex[name];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final host = getField('host');
    final command = getField('command');
    final startTimeStr = getField('start_time');
    final user = getField('user');

    if (host.isEmpty || command.isEmpty || user.isEmpty) {
      throw FormatException('Missing mandatory field value in row $rowNum');
    }

    final startTime = DateTime.tryParse(startTimeStr);
    if (startTime == null) {
      throw FormatException('Unparseable start_time: "$startTimeStr"');
    }

    // Optional fields
    final category = getField('category');
    final durationStr = getField('duration');
    final schedule = getField('schedule');
    final os = getField('os');
    final endTimeStr = getField('end_time');

    DateTime? endTime;
    if (endTimeStr.isNotEmpty) {
      endTime = DateTime.tryParse(endTimeStr);
    }

    int duration = 0;
    if (durationStr.isNotEmpty) {
      duration = int.tryParse(durationStr) ?? 0;
    }

    return CronJob(
      id: '${batchId}_$rowNum',
      host: host,
      command: command,
      startTime: startTime,
      endTime: endTime,
      user: user,
      category: category.isEmpty ? 'uncategorized' : category,
      duration: duration,
      schedule: schedule.isEmpty ? null : schedule,
      os: os.isEmpty ? 'linux' : os,
      importBatchId: batchId,
      importedAt: importedAt,
    );
  }

  /// Auto-detect the delimiter by counting occurrences in the first line.
  static String _detectDelimiter(String text) {
    final firstLine = text.split('\n').first;
    final commas = ','.allMatches(firstLine).length;
    final semicolons = ';'.allMatches(firstLine).length;
    final tabs = '\t'.allMatches(firstLine).length;

    if (tabs >= commas && tabs >= semicolons && tabs > 0) return '\t';
    if (semicolons > commas && semicolons > 0) return ';';
    return ',';
  }
}
