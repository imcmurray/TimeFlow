import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/time/local_date.dart';

List<LocalDate> _dates(
  RecurrenceRule rule,
  LocalDate start,
  LocalDate from,
  LocalDate to,
) => rule.occurrences(start, from: from, to: to).toList();

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  group('daily', () {
    test('every day from the start', () {
      expect(
        _dates(
          RecurrenceRule.daily,
          d(2026, 1, 30),
          d(2026, 1, 1),
          d(2026, 2, 2),
        ),
        [d(2026, 1, 30), d(2026, 1, 31), d(2026, 2, 1), d(2026, 2, 2)],
      );
    });

    test('interval keeps alignment with the start when skipping ahead', () {
      const rule = RecurrenceRule(frequency: Frequency.daily, interval: 3);
      expect(_dates(rule, d(2026, 1, 1), d(2026, 1, 5), d(2026, 1, 12)), [
        d(2026, 1, 7),
        d(2026, 1, 10),
      ]);
    });

    test('stops at until (inclusive)', () {
      final rule = RecurrenceRule.daily.endingOn(d(2026, 1, 3));
      expect(_dates(rule, d(2026, 1, 1), d(2026, 1, 1), d(2026, 12, 31)), [
        d(2026, 1, 1),
        d(2026, 1, 2),
        d(2026, 1, 3),
      ]);
    });

    test('nothing before the series start', () {
      expect(
        _dates(
          RecurrenceRule.daily,
          d(2026, 5, 1),
          d(2026, 4, 1),
          d(2026, 4, 30),
        ),
        isEmpty,
      );
    });

    test('keeps going years later', () {
      expect(
        _dates(
          RecurrenceRule.daily,
          d(2026, 1, 1),
          d(2031, 6, 1),
          d(2031, 6, 1),
        ),
        [d(2031, 6, 1)],
      );
    });
  });

  group('weekly', () {
    test('defaults to the start weekday', () {
      // 2026-10-06 is a Tuesday.
      expect(
        _dates(
          RecurrenceRule.weekly,
          d(2026, 10, 6),
          d(2026, 10, 1),
          d(2026, 10, 31),
        ),
        [d(2026, 10, 6), d(2026, 10, 13), d(2026, 10, 20), d(2026, 10, 27)],
      );
    });

    test('weekdays skips weekends', () {
      // Fri 2026-10-09 .. Tue 2026-10-13.
      expect(
        _dates(
          RecurrenceRule.weekdaysOnly,
          d(2026, 10, 9),
          d(2026, 10, 9),
          d(2026, 10, 13),
        ),
        [d(2026, 10, 9), d(2026, 10, 12), d(2026, 10, 13)],
      );
    });

    test('fortnightly with several days stays on alternate weeks', () {
      const rule = RecurrenceRule(
        frequency: Frequency.weekly,
        interval: 2,
        weekdays: {DateTime.monday, DateTime.thursday},
      );
      // Series starts Thu 2026-10-01; its week starts Mon 2026-09-28.
      expect(_dates(rule, d(2026, 10, 1), d(2026, 10, 1), d(2026, 10, 31)), [
        d(2026, 10, 1),
        d(2026, 10, 12),
        d(2026, 10, 15),
        d(2026, 10, 26),
        d(2026, 10, 29),
      ]);
      // Skipping ahead lands on the same alternate weeks.
      expect(_dates(rule, d(2026, 10, 1), d(2026, 10, 20), d(2026, 10, 31)), [
        d(2026, 10, 26),
        d(2026, 10, 29),
      ]);
    });
  });

  group('monthly and yearly', () {
    test('month-end start clamps without drifting', () {
      expect(
        _dates(
          RecurrenceRule.monthly,
          d(2026, 1, 31),
          d(2026, 1, 1),
          d(2026, 5, 31),
        ),
        [
          d(2026, 1, 31),
          d(2026, 2, 28),
          d(2026, 3, 31),
          d(2026, 4, 30),
          d(2026, 5, 31),
        ],
      );
    });

    test('quarterly skipping ahead', () {
      expect(
        _dates(
          RecurrenceRule.quarterly,
          d(2026, 1, 15),
          d(2027, 2, 1),
          d(2027, 12, 31),
        ),
        [d(2027, 4, 15), d(2027, 7, 15), d(2027, 10, 15)],
      );
    });

    test('Feb 29 yearly falls back to Feb 28', () {
      expect(
        _dates(
          RecurrenceRule.yearly,
          d(2028, 2, 29),
          d(2028, 1, 1),
          d(2032, 12, 31),
        ),
        [
          d(2028, 2, 29),
          d(2029, 2, 28),
          d(2030, 2, 28),
          d(2031, 2, 28),
          d(2032, 2, 29),
        ],
      );
    });

    test('occursOn', () {
      expect(
        RecurrenceRule.monthly.occursOn(d(2026, 1, 31), d(2026, 2, 28)),
        isTrue,
      );
      expect(
        RecurrenceRule.monthly.occursOn(d(2026, 1, 31), d(2026, 2, 27)),
        isFalse,
      );
    });
  });

  group('serialization', () {
    test('round-trips every preset and a custom rule', () {
      final rules = [
        RecurrenceRule.daily,
        RecurrenceRule.weekdaysOnly,
        RecurrenceRule.weekly,
        RecurrenceRule.fortnightly,
        RecurrenceRule.monthly,
        RecurrenceRule.bimonthly,
        RecurrenceRule.quarterly,
        RecurrenceRule.yearly,
        RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 3,
          weekdays: const {DateTime.sunday, DateTime.wednesday},
          until: d(2027, 3, 1),
        ),
      ];
      for (final rule in rules) {
        expect(
          RecurrenceRule.parse(rule.toRRule()),
          rule,
          reason: rule.toRRule(),
        );
      }
      expect(
        RecurrenceRule.weekdaysOnly.toRRule(),
        'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
    });

    test('rejects what it does not understand', () {
      expect(() => RecurrenceRule.parse('FREQ=HOURLY'), throwsFormatException);
      expect(() => RecurrenceRule.parse('INTERVAL=2'), throwsFormatException);
      expect(
        () => RecurrenceRule.parse('FREQ=DAILY;BYSETPOS=1'),
        throwsFormatException,
      );
    });

    test('maps legacy pattern names', () {
      expect(
        RecurrenceRule.fromLegacyPattern('fortnightly'),
        RecurrenceRule.fortnightly,
      );
      expect(RecurrenceRule.fromLegacyPattern(null), isNull);
      expect(RecurrenceRule.fromLegacyPattern('hourly'), isNull);
    });
  });
}
