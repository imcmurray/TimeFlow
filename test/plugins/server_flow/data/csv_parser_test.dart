import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/plugins/server_flow/data/csv_parser.dart';
import 'package:timeflow/plugins/server_flow/domain/csv_validation.dart';

import '../../../test_helpers/sample_csvs.dart';

void main() {
  group('CsvParser', () {
    test('parses all columns correctly', () {
      final result = CsvParser.parse(validCsvAllColumns, importBatchId: 'test');

      expect(result.jobs, hasLength(3));
      expect(result.errors, isEmpty);
      expect(result.totalRows, 3);

      final job = result.jobs.first;
      expect(job.host, 'web-prod-01');
      expect(job.command, '/usr/bin/backup.sh');
      expect(job.startTime, DateTime.utc(2025, 1, 15, 2, 30));
      expect(job.user, 'root');
      expect(job.category, 'backup');
      expect(job.duration, 3600);
      expect(job.schedule, '0 2 * * *');
      expect(job.os, 'linux');
    });

    test('parses mandatory-only columns', () {
      final result = CsvParser.parse(
        validCsvMandatoryOnly,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(2));
      expect(result.errors, isEmpty);

      final job = result.jobs.first;
      expect(job.host, 'web-prod-01');
      expect(job.category, 'uncategorized');
      expect(job.duration, 0);
      expect(job.schedule, isNull);
      expect(job.os, 'linux');
    });

    test('throws on missing mandatory column', () {
      expect(
        () => CsvParser.parse(csvMissingHostColumn),
        throwsA(isA<CsvValidationException>()),
      );
    });

    test('throws on missing multiple columns', () {
      try {
        CsvParser.parse(csvMissingMultipleColumns);
        fail('Expected CsvValidationException');
      } on CsvValidationException catch (e) {
        expect(e.missingColumns, contains('command'));
        expect(e.missingColumns, contains('user'));
      }
    });

    test('parses semicolon-delimited CSV', () {
      final result = CsvParser.parse(
        validCsvSemicolonDelimited,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(2));
      expect(result.errors, isEmpty);
      expect(result.jobs.first.host, 'web-prod-01');
    });

    test('parses tab-delimited CSV', () {
      final result = CsvParser.parse(
        validCsvTabDelimited,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(2));
      expect(result.errors, isEmpty);
      expect(result.jobs.first.host, 'web-prod-01');
    });

    test('handles case-insensitive headers', () {
      final result = CsvParser.parse(
        validCsvCaseInsensitiveHeaders,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(1));
      expect(result.jobs.first.host, 'web-prod-01');
    });

    test('collects unparseable start_time as non-fatal error', () {
      final result = CsvParser.parse(
        csvUnparseableStartTime,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(1));
      expect(result.errors, hasLength(1));
      expect(result.errors.first.row, 2);
    });

    test('end_time overrides duration', () {
      final result = CsvParser.parse(
        csvEndTimeOverridesDuration,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(1));
      final job = result.jobs.first;
      expect(job.endTime, DateTime.utc(2025, 1, 15, 4, 0));
      expect(job.duration, 3600); // still set, but endTime takes precedence
      expect(job.effectiveEndTime, DateTime.utc(2025, 1, 15, 4, 0));
    });

    test('empty optional fields use defaults', () {
      final result = CsvParser.parse(
        csvEmptyOptionalDefaults,
        importBatchId: 'test',
      );

      expect(result.jobs, hasLength(1));
      final job = result.jobs.first;
      expect(job.category, 'uncategorized');
      expect(job.duration, 0);
      expect(job.schedule, isNull);
      expect(job.os, 'linux');
    });

    test('throws on empty content', () {
      expect(
        () => CsvParser.parse(csvEmptyContent),
        throwsA(isA<CsvValidationException>()),
      );
    });

    test('returns empty jobs for header-only CSV', () {
      final result = CsvParser.parse(csvHeaderOnly, importBatchId: 'test');
      expect(result.jobs, isEmpty);
      expect(result.errors, isEmpty);
    });

    test('assigns import batch id to all jobs', () {
      final result = CsvParser.parse(
        validCsvMandatoryOnly,
        importBatchId: 'batch-42',
      );

      for (final job in result.jobs) {
        expect(job.importBatchId, 'batch-42');
      }
    });
  });
}
