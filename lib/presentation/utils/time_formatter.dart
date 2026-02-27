import 'package:intl/intl.dart';

/// Centralized time/date formatting utilities used across the presentation layer.
class TimeFormatter {
  /// Format a [DateTime] as a time string.
  ///
  /// Returns "3:45 PM" in 12-hour mode or "15:45" in 24-hour mode.
  static String formatTime(DateTime time, {bool use24HourFormat = false}) {
    if (use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Format an hour (0–23) as a label.
  ///
  /// Returns "3 PM" in 12-hour mode or "15:00" in 24-hour mode.
  /// When [showMinutes] is true, appends ":00" (e.g., "3:00 PM").
  static String formatHour(
    int hour, {
    bool use24HourFormat = false,
    bool showMinutes = false,
  }) {
    if (use24HourFormat) {
      return '${hour.toString().padLeft(2, '0')}:00';
    }
    final suffix = showMinutes ? ':00' : '';
    if (hour == 0 || hour == 24) return '12$suffix AM';
    if (hour == 12) return '12$suffix PM';
    if (hour < 12) return '$hour$suffix AM';
    return '${hour - 12}$suffix PM';
  }

  /// Format a [DateTime] as a short date for the timeline header.
  ///
  /// Returns "Today", "Tomorrow", "Yesterday", or "Mon, Feb 26".
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  /// Format a [DateTime] as a full date string for share/export screens.
  ///
  /// Returns "Wednesday, February 26".
  static String formatDateFull(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  /// Format a [DateTime] as a compact date for task detail screens.
  ///
  /// Returns "Today", "Tomorrow", "Yesterday", or "Wed, Feb 26".
  static String formatDateCompact(DateTime date) {
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
