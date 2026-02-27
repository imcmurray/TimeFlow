/// Shared offset calculation for mapping DateTime ↔ pixel positions on the timeline.
class TimelineOffset {
  /// Calculate the pixel offset for a given [dateTime] on the timeline.
  ///
  /// Parameters:
  /// - [dateTime]: The point in time to locate.
  /// - [referenceDate]: The "today" anchor date (midnight).
  /// - [hourHeight]: Pixels per hour (zoom level).
  /// - [daysLoadedBefore]: Number of past days loaded above/below reference.
  /// - [daysLoadedAfter]: Number of future days loaded.
  /// - [upcomingTasksAboveNow]: If true, future is at the top.
  static double forDateTime({
    required DateTime dateTime,
    required DateTime referenceDate,
    required double hourHeight,
    required int daysLoadedBefore,
    required int daysLoadedAfter,
    required bool upcomingTasksAboveNow,
  }) {
    final hoursFromReference =
        dateTime.difference(referenceDate).inMinutes / 60.0;

    if (upcomingTasksAboveNow) {
      final referenceOffset = daysLoadedAfter * 24 * hourHeight;
      return referenceOffset - (hoursFromReference * hourHeight);
    } else {
      final referenceOffset = daysLoadedBefore * 24 * hourHeight;
      return referenceOffset + (hoursFromReference * hourHeight);
    }
  }

  /// Calculate the [DateTime] at a given pixel [offset] on the timeline (inverse of [forDateTime]).
  static DateTime atOffset({
    required double offset,
    required DateTime referenceDate,
    required double hourHeight,
    required int daysLoadedBefore,
    required int daysLoadedAfter,
    required bool upcomingTasksAboveNow,
  }) {
    final referenceOffset = upcomingTasksAboveNow
        ? daysLoadedAfter * 24 * hourHeight
        : daysLoadedBefore * 24 * hourHeight;

    double hoursFromReference;
    if (upcomingTasksAboveNow) {
      hoursFromReference = (referenceOffset - offset) / hourHeight;
    } else {
      hoursFromReference = (offset - referenceOffset) / hourHeight;
    }

    return referenceDate
        .add(Duration(minutes: (hoursFromReference * 60).round()));
  }
}
