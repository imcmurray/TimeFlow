import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/recurrence/series_expander.dart';
import 'package:timeflow/domain/time/local_date.dart';

import '../helpers/dst.dart';

Task series({
  required DateTime start,
  required DateTime end,
  RecurrenceRule rule = RecurrenceRule.daily,
}) {
  final t = DateTime(2026, 1, 1);
  return Task(
    id: 's1',
    title: 'Walk the dogs',
    startTime: start,
    endTime: end,
    reminderMinutes: 10,
    recurrence: rule,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('occurrences are virtual, keyed by date, and carry series fields', () {
    final s = series(
        start: DateTime(2026, 6, 1, 9), end: DateTime(2026, 6, 1, 9, 30));
    final occ = SeriesExpander.occurrencesOf(s,
            from: DateTime(2026, 6, 3), to: DateTime(2026, 6, 5))
        .toList();
    expect(occ.map((o) => o.occurrenceDate),
        [LocalDate(2026, 6, 3), LocalDate(2026, 6, 4)]);
    final first = occ.first;
    expect(first.id, 's1@20260603');
    expect(first.isVirtual, isTrue);
    expect(first.seriesId, 's1');
    expect(first.title, 'Walk the dogs');
    expect(first.reminderMinutes, 10);
    expect(first.recurrence, RecurrenceRule.daily);
    expect(first.startTime, DateTime(2026, 6, 3, 9));
    expect(first.endTime, DateTime(2026, 6, 3, 9, 30));
  });

  test('skips dates with overrides', () {
    final s =
        series(start: DateTime(2026, 6, 1, 9), end: DateTime(2026, 6, 1, 10));
    final occ = SeriesExpander.occurrencesOf(s,
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 4),
        skip: {LocalDate(2026, 6, 2)}).toList();
    expect(occ.map((o) => o.occurrenceDate!.day), [1, 3]);
  });

  test('includes an occurrence that crosses midnight into the range', () {
    final s =
        series(start: DateTime(2026, 6, 1, 23), end: DateTime(2026, 6, 2, 1));
    final occ = SeriesExpander.occurrencesOf(s,
            from: DateTime(2026, 6, 5), to: DateTime(2026, 6, 6))
        .toList();
    expect(occ.map((o) => o.occurrenceDate!.day), [4, 5]);
    expect(occ.first.endTime, DateTime(2026, 6, 5, 1));
  });

  group('across DST changes', () {
    test('a daily 9:00 task stays at 9:00', () {
      final s = series(
          start: DateTime(2026, 3, 1, 9), end: DateTime(2026, 3, 1, 9, 45));
      final occ = SeriesExpander.occurrencesOf(s,
              from: DateTime(2026, 3, 6), to: DateTime(2026, 3, 11))
          .toList();
      expect(occ.map((o) => o.startTime.hour), everyElement(9));
      expect(occ.map((o) => o.durationMinutes), everyElement(45));
      final fall = SeriesExpander.occurrencesOf(s,
              from: DateTime(2026, 10, 30), to: DateTime(2026, 11, 4))
          .toList();
      expect(fall.map((o) => o.startTime.hour), everyElement(9));
    }, skip: skipWithoutDst);

    test('a weekly task keeps its wall-clock time', () {
      final s = series(
          start: DateTime(2026, 10, 25, 18),
          end: DateTime(2026, 10, 25, 19),
          rule: RecurrenceRule.weekly);
      final occ = SeriesExpander.occurrencesOf(s,
              from: DateTime(2026, 10, 20), to: DateTime(2026, 11, 20))
          .toList();
      expect(occ.map((o) => o.startTime.hour), everyElement(18));
      expect(occ.map((o) => o.occurrenceDate!.weekday),
          everyElement(DateTime.sunday));
    }, skip: skipWithoutDst);
  });
}
