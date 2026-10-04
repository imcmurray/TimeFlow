import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/plugins/server_flow/domain/csv_validation.dart';

void main() {
  group('CsvValidator', () {
    test('passes with all mandatory columns', () {
      expect(
        () => CsvValidator.validate(['host', 'command', 'start_time', 'user']),
        returnsNormally,
      );
    });

    test('passes with extra columns', () {
      expect(
        () => CsvValidator.validate(
            ['host', 'command', 'start_time', 'user', 'category', 'os']),
        returnsNormally,
      );
    });

    test('throws when missing one column', () {
      try {
        CsvValidator.validate(['command', 'start_time', 'user']);
        fail('Expected CsvValidationException');
      } on CsvValidationException catch (e) {
        expect(e.missingColumns, ['host']);
      }
    });

    test('throws when missing multiple columns', () {
      try {
        CsvValidator.validate(['host']);
        fail('Expected CsvValidationException');
      } on CsvValidationException catch (e) {
        expect(
            e.missingColumns, containsAll(['command', 'start_time', 'user']));
      }
    });

    test('handles whitespace in headers', () {
      expect(
        () => CsvValidator.validate(
            [' host ', ' command', 'start_time ', ' user ']),
        returnsNormally,
      );
    });

    test('handles case-insensitive headers', () {
      expect(
        () => CsvValidator.validate(['HOST', 'Command', 'START_TIME', 'User']),
        returnsNormally,
      );
    });

    test('throws on empty headers list', () {
      expect(
        () => CsvValidator.validate([]),
        throwsA(isA<CsvValidationException>()),
      );
    });
  });
}
