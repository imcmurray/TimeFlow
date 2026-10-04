import 'package:flutter/foundation.dart';
import 'package:timeflow/domain/time/local_date.dart';

/// How often a recurring task repeats.
enum Frequency { daily, weekly, monthly, yearly }

/// A repeat rule for a recurring task series, expressed in calendar dates so
/// occurrences stay at the same wall-clock time across DST changes.
///
/// Serialized as a small subset of RFC 5545 RRULE, e.g.
/// `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;UNTIL=20261231`.
@immutable
class RecurrenceRule {
  final Frequency frequency;

  /// Repeat every [interval] units of [frequency] (>= 1).
  final int interval;

  /// For weekly rules: the weekdays (DateTime.monday..sunday) to repeat on.
  /// Empty means "the weekday of the series start".
  final Set<int> weekdays;

  /// Last date (inclusive) an occurrence may fall on; null repeats forever.
  final LocalDate? until;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const {},
    this.until,
  }) : assert(interval >= 1);

  static const daily = RecurrenceRule(frequency: Frequency.daily);
  static const weekdaysOnly = RecurrenceRule(
    frequency: Frequency.weekly,
    weekdays: {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    },
  );
  static const weekly = RecurrenceRule(frequency: Frequency.weekly);
  static const fortnightly =
      RecurrenceRule(frequency: Frequency.weekly, interval: 2);
  static const monthly = RecurrenceRule(frequency: Frequency.monthly);
  static const bimonthly =
      RecurrenceRule(frequency: Frequency.monthly, interval: 2);
  static const quarterly =
      RecurrenceRule(frequency: Frequency.monthly, interval: 3);
  static const yearly = RecurrenceRule(frequency: Frequency.yearly);

  /// The rule a pre-1.0 `recurringPattern` string stood for.
  static RecurrenceRule? fromLegacyPattern(String? pattern) =>
      switch (pattern) {
        'daily' => daily,
        'weekdays' => weekdaysOnly,
        'weekly' => weekly,
        'fortnightly' => fortnightly,
        'monthly' => monthly,
        'bimonthly' => bimonthly,
        'quarterly' => quarterly,
        'yearly' => yearly,
        _ => null,
      };

  RecurrenceRule copyWith({
    Frequency? frequency,
    int? interval,
    Set<int>? weekdays,
    LocalDate? until,
    bool clearUntil = false,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      until: clearUntil ? null : (until ?? this.until),
    );
  }

  /// The same rule ending on [date] (inclusive).
  RecurrenceRule endingOn(LocalDate date) => copyWith(until: date);

  /// Whether this rule repeats in the same pattern as [other], ignoring [until].
  bool samePatternAs(RecurrenceRule other) =>
      frequency == other.frequency &&
      interval == other.interval &&
      setEquals(weekdays, other.weekdays);

  /// Occurrence dates of a series starting on [start], within [from]..[to]
  /// (both inclusive), in ascending order.
  Iterable<LocalDate> occurrences(
    LocalDate start, {
    required LocalDate from,
    required LocalDate to,
  }) sync* {
    final last = until != null && until!.isBefore(to) ? until! : to;
    if (last.isBefore(start) || last.isBefore(from)) return;

    switch (frequency) {
      case Frequency.daily:
        // Jump straight to the first candidate at or after `from`.
        var offset = 0;
        if (from.isAfter(start)) {
          final days = start.daysUntil(from);
          offset = (days + interval - 1) ~/ interval * interval;
        }
        for (var d = start.addDays(offset);
            !d.isAfter(last);
            d = d.addDays(interval)) {
          yield d;
        }

      case Frequency.weekly:
        final days = weekdays.isEmpty ? {start.weekday} : weekdays;
        final weekStart = start.startOfWeek;
        var weekIndex = 0;
        if (from.isAfter(weekStart)) {
          final weeks = weekStart.daysUntil(from.startOfWeek) ~/ 7;
          weekIndex = weeks ~/ interval * interval;
        }
        while (true) {
          final week = weekStart.addDays(weekIndex * 7);
          if (week.isAfter(last)) return;
          for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
            if (!days.contains(wd)) continue;
            final d = week.addDays(wd - DateTime.monday);
            if (d.isBefore(start) || d.isBefore(from)) continue;
            if (d.isAfter(last)) return;
            yield d;
          }
          weekIndex += interval;
        }

      case Frequency.monthly:
      case Frequency.yearly:
        final step = frequency == Frequency.yearly ? 12 * interval : interval;
        var n = 0;
        if (from.isAfter(start)) {
          final months =
              (from.year - start.year) * 12 + (from.month - start.month);
          n = (months - 1).clamp(0, months) ~/ step;
        }
        while (true) {
          // Always derive from the series start so Jan 31 -> Feb 28 -> Mar 31.
          final d = start.addMonthsClamped(n * step);
          if (d.isAfter(last)) return;
          if (!d.isBefore(from)) yield d;
          n++;
        }
    }
  }

  /// Whether [date] is an occurrence of a series starting on [start].
  bool occursOn(LocalDate start, LocalDate date) =>
      occurrences(start, from: date, to: date).isNotEmpty;

  /// Serializes to an RRULE-style string.
  String toRRule() {
    final parts = <String>['FREQ=${frequency.name.toUpperCase()}'];
    if (interval != 1) parts.add('INTERVAL=$interval');
    if (weekdays.isNotEmpty) {
      final sorted = weekdays.toList()..sort();
      parts.add('BYDAY=${sorted.map((d) => _dayCodes[d - 1]).join(',')}');
    }
    if (until != null) parts.add('UNTIL=${until!.compact}');
    return parts.join(';');
  }

  /// Parses a string produced by [toRRule]. Throws [FormatException] on input
  /// it doesn't understand.
  factory RecurrenceRule.parse(String rrule) {
    Frequency? frequency;
    var interval = 1;
    var weekdays = <int>{};
    LocalDate? until;
    for (final part in rrule.split(';')) {
      final eq = part.indexOf('=');
      if (eq < 0) throw FormatException('Bad RRULE part', part);
      final key = part.substring(0, eq);
      final value = part.substring(eq + 1);
      switch (key) {
        case 'FREQ':
          frequency = Frequency.values.firstWhere(
            (f) => f.name.toUpperCase() == value,
            orElse: () => throw FormatException('Bad FREQ', value),
          );
        case 'INTERVAL':
          interval = int.parse(value);
          if (interval < 1) throw FormatException('Bad INTERVAL', value);
        case 'BYDAY':
          weekdays = value.split(',').map((code) {
            final i = _dayCodes.indexOf(code);
            if (i < 0) throw FormatException('Bad BYDAY', value);
            return i + 1;
          }).toSet();
        case 'UNTIL':
          until = LocalDate.parseCompact(value);
        default:
          throw FormatException('Unsupported RRULE part', part);
      }
    }
    if (frequency == null) throw FormatException('Missing FREQ', rrule);
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      weekdays: weekdays,
      until: until,
    );
  }

  static const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule && samePatternAs(other) && until == other.until;

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        Object.hashAllUnordered(weekdays),
        until,
      );

  @override
  String toString() => 'RecurrenceRule(${toRRule()})';
}
