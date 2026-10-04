import 'package:intl/intl.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/time/local_date.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayShort(int weekday) => _weekdayShort[weekday - 1];

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th'
  };
}

/// A sentence describing how [rule] repeats for a series starting on [start],
/// e.g. "Every 2 weeks on Mon, Thu, until Mar 1, 2027".
String describeRecurrence(RecurrenceRule rule, LocalDate start) {
  final n = rule.interval;
  String every(String unit) => n == 1 ? 'Every $unit' : 'Every $n ${unit}s';

  final base = switch (rule.frequency) {
    Frequency.daily => n == 1 ? 'Every day' : 'Every $n days',
    Frequency.weekly => () {
        final days = rule.weekdays.isEmpty ? {start.weekday} : rule.weekdays;
        if (n == 1 &&
            days.length == 5 &&
            !days.contains(DateTime.saturday) &&
            !days.contains(DateTime.sunday)) {
          return 'Every weekday (Mon–Fri)';
        }
        if (n == 1 && days.length == 7) return 'Every day';
        final sorted = days.toList()..sort();
        final names = sorted.length == 1
            ? _weekdayLong[sorted.single - 1]
            : sorted.map(weekdayShort).join(', ');
        return '${every('week')} on $names';
      }(),
    Frequency.monthly => '${every('month')} on the ${_ordinal(start.day)}'
        '${start.day > 28 ? ' (or last day)' : ''}',
    Frequency.yearly =>
      '${every('year')} on ${DateFormat.MMMMd().format(start.startOfDay)}',
  };
  if (rule.until == null) return base;
  return '$base, until ${DateFormat.yMMMd().format(rule.until!.startOfDay)}';
}
