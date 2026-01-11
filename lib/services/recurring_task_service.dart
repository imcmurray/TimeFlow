import 'package:uuid/uuid.dart';
import 'package:timeflow/domain/entities/task.dart';

/// Service for generating recurring task instances from a template task.
class RecurringTaskService {
  static const _uuid = Uuid();

  /// Maximum instances to generate per pattern type.
  static const Map<String, int> _maxInstances = {
    'daily': 90,
    'weekdays': 90,
    'weekly': 52,
    'fortnightly': 26,
    'monthly': 12,
    'bimonthly': 6,
    'quarterly': 4,
    'yearly': 5,
  };

  /// Generate recurring task instances from a template task.
  ///
  /// Returns a list of task instances including the original.
  /// Each instance has a unique ID but shares the same [recurringTemplateId].
  static List<Task> generateInstances(Task template) {
    if (template.recurringPattern == null) {
      return [template];
    }

    final pattern = template.recurringPattern!;
    final maxCount = _maxInstances[pattern] ?? 12;
    final templateId = _uuid.v4();
    final instances = <Task>[];
    final now = DateTime.now();

    var currentStart = template.startTime;
    var currentEnd = template.endTime;

    for (var i = 0; i < maxCount; i++) {
      instances.add(template.copyWith(
        id: _uuid.v4(),
        startTime: currentStart,
        endTime: currentEnd,
        recurringTemplateId: templateId,
        createdAt: now,
        updatedAt: now,
      ));

      final nextDates = _getNextOccurrence(currentStart, currentEnd, pattern);
      currentStart = nextDates.$1;
      currentEnd = nextDates.$2;
    }

    return instances;
  }

  /// Calculate the next occurrence based on the pattern.
  static (DateTime, DateTime) _getNextOccurrence(
    DateTime start,
    DateTime end,
    String pattern,
  ) {
    final duration = end.difference(start);

    switch (pattern) {
      case 'daily':
        return (
          start.add(const Duration(days: 1)),
          end.add(const Duration(days: 1)),
        );

      case 'weekdays':
        var nextStart = start.add(const Duration(days: 1));
        while (nextStart.weekday == DateTime.saturday ||
            nextStart.weekday == DateTime.sunday) {
          nextStart = nextStart.add(const Duration(days: 1));
        }
        return (nextStart, nextStart.add(duration));

      case 'weekly':
        return (
          start.add(const Duration(days: 7)),
          end.add(const Duration(days: 7)),
        );

      case 'fortnightly':
        return (
          start.add(const Duration(days: 14)),
          end.add(const Duration(days: 14)),
        );

      case 'monthly':
        return _addMonths(start, end, 1);

      case 'bimonthly':
        return _addMonths(start, end, 2);

      case 'quarterly':
        return _addMonths(start, end, 3);

      case 'yearly':
        return _addMonths(start, end, 12);

      default:
        return (
          start.add(const Duration(days: 7)),
          end.add(const Duration(days: 7)),
        );
    }
  }

  /// Add months to a date, handling month boundaries correctly.
  static (DateTime, DateTime) _addMonths(
    DateTime start,
    DateTime end,
    int months,
  ) {
    final duration = end.difference(start);
    var newYear = start.year;
    var newMonth = start.month + months;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = start.day > daysInNewMonth ? daysInNewMonth : start.day;

    final newStart = DateTime(
      newYear,
      newMonth,
      newDay,
      start.hour,
      start.minute,
      start.second,
    );

    return (newStart, newStart.add(duration));
  }

  /// Get the display label for a recurring pattern.
  static String getPatternLabel(String? pattern) {
    switch (pattern) {
      case 'daily':
        return 'Daily';
      case 'weekdays':
        return 'Weekdays';
      case 'weekly':
        return 'Weekly';
      case 'fortnightly':
        return 'Fortnightly';
      case 'monthly':
        return 'Monthly';
      case 'bimonthly':
        return 'Every 2 Months';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Does not repeat';
    }
  }
}
