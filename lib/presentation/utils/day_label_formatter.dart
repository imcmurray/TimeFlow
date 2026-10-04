import 'package:intl/intl.dart';

/// Shared day-label formatting used by day boundary markers and dividers.
class DayLabelFormatter {
  /// Full label: "Today", "Tomorrow", "Yesterday", "Last Monday", "Mon, Feb 27".
  static String full(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 6) {
      return DateFormat('EEEE').format(date); // Just day name for this week
    } else if (difference < -1 && difference >= -6) {
      return 'Last ${DateFormat('EEEE').format(date)}';
    }

    return DateFormat('EEE, MMM d').format(date);
  }

  /// Compact label: "Today", "Tomorrow", "Yesterday", short date.
  static String compact(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, MMM d').format(date);
  }
}
