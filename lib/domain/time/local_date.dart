import 'package:flutter/foundation.dart';

/// A calendar date with no time or time zone.
///
/// Day arithmetic happens in UTC internally, so adding days never drifts by an
/// hour across DST changes the way `DateTime.add(Duration(days: n))` does on
/// local times.
@immutable
class LocalDate implements Comparable<LocalDate> {
  final int year;
  final int month;
  final int day;

  const LocalDate._(this.year, this.month, this.day);

  /// Normalizes out-of-range values, like the DateTime constructor does
  /// (e.g. month 13 rolls into the next year).
  factory LocalDate(int year, int month, int day) {
    final utc = DateTime.utc(year, month, day);
    return LocalDate._(utc.year, utc.month, utc.day);
  }

  /// The calendar date of a local [DateTime].
  factory LocalDate.of(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  factory LocalDate.today() => LocalDate.of(DateTime.now());

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = Monday ... 7 = Sunday, as in [DateTime.weekday].
  int get weekday => _utc.weekday;

  LocalDate addDays(int days) => LocalDate(year, month, day + days);

  /// Adds months, clamping the day to the target month's length
  /// (Jan 31 + 1 month = Feb 28/29).
  LocalDate addMonthsClamped(int months) {
    final firstOfTarget = LocalDate(year, month + months, 1);
    final length =
        DateTime.utc(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    return LocalDate._(
      firstOfTarget.year,
      firstOfTarget.month,
      day > length ? length : day,
    );
  }

  /// The Monday on or before this date.
  LocalDate get startOfWeek => addDays(DateTime.monday - weekday);

  /// Whole days from this date to [other] (negative if [other] is earlier).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Local midnight at the start of this date.
  DateTime get startOfDay => DateTime(year, month, day);

  /// This date at the given local wall-clock time. Minutes past 59 (or hours
  /// past 23) roll forward, so `at(0, 90)` is 01:30.
  DateTime at(int hour, int minute) => DateTime(year, month, day, hour, minute);

  /// `yyyyMMdd`, as used in RRULE UNTIL values and occurrence ids.
  String get compact =>
      '${year.toString().padLeft(4, '0')}${_two(month)}${_two(day)}';

  /// `yyyy-MM-dd`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  static LocalDate parseCompact(String s) {
    if (s.length < 8) throw FormatException('Bad compact date', s);
    return LocalDate(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  }

  static LocalDate parseIso(String s) {
    final parts = s.split('-');
    if (parts.length != 3) throw FormatException('Bad ISO date', s);
    return LocalDate(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
