import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// Generates the occurrences of recurring task series.
class SeriesExpander {
  const SeriesExpander._();

  /// Id of the generated occurrence of [seriesId] on [date].
  static String occurrenceId(String seriesId, LocalDate date) =>
      '$seriesId@${date.compact}';

  /// The (virtual) occurrence of [series] scheduled on [date], whether or not
  /// the rule actually produces that date.
  static Task occurrenceOn(Task series, LocalDate date) {
    final start = date.at(series.startTime.hour, series.startTime.minute);
    return Task(
      id: occurrenceId(series.id, date),
      title: series.title,
      description: series.description,
      startTime: start,
      endTime: addWallMinutes(start, series.durationMinutes),
      isImportant: series.isImportant,
      reminderMinutes: series.reminderMinutes,
      notes: series.notes,
      attachmentPath: series.attachmentPath,
      color: series.color,
      categoryId: series.categoryId,
      recurrence: series.recurrence,
      seriesId: series.id,
      occurrenceDate: date,
      isVirtual: true,
      createdAt: series.createdAt,
      updatedAt: series.updatedAt,
    );
  }

  /// Virtual occurrences of [series] that overlap [from]..[to) (end
  /// exclusive), skipping the dates in [skip] (dates that have a stored
  /// override or were cancelled).
  static Iterable<Task> occurrencesOf(
    Task series, {
    required DateTime from,
    required DateTime to,
    Set<LocalDate> skip = const {},
  }) sync* {
    final rule = series.recurrence;
    if (rule == null) return;
    // An occurrence that starts on an earlier day can still reach into the
    // range if the task is longer than a day or crosses midnight.
    final spanDays =
        (series.durationMinutes + minuteOfDay(series.startTime)) ~/ (24 * 60);
    final dates = rule.occurrences(
      LocalDate.of(series.startTime),
      from: LocalDate.of(from).addDays(-spanDays),
      to: LocalDate.of(to),
    );
    for (final date in dates) {
      if (skip.contains(date)) continue;
      final occurrence = occurrenceOn(series, date);
      if (occurrence.startTime.isBefore(to) &&
          occurrence.endTime.isAfter(from)) {
        yield occurrence;
      }
    }
  }
}
