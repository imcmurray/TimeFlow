import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/recurrence/series_expander.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// A task as stored before 1.0. Recurring tasks were pre-generated: every
/// occurrence was its own row, linked by a shared [templateId] and tagged
/// with a [pattern] name ('daily', 'weekly', ...).
class LegacyTask {
  final Task task;
  final String? pattern;
  final String? templateId;

  const LegacyTask(this.task, {this.pattern, this.templateId});
}

/// A task row in the current storage model.
class StoredTask {
  final Task task;

  /// For overrides: the occurrence was deleted.
  final bool isCancelled;

  const StoredTask(this.task, {this.isCancelled = false});
}

/// Converts pre-1.0 tasks to the series model.
///
/// Each group of pre-generated instances becomes one series (which now
/// repeats indefinitely instead of stopping after the last pre-generated
/// copy). Instances the series would produce unchanged are dropped. Edited or
/// completed ones become overrides, and dates the user had deleted become
/// cancelled overrides. Instances that no longer line up with the pattern are
/// kept as standalone tasks so nothing is lost.
///
/// [newId] supplies ids for cancelled-override rows.
List<StoredTask> collapseLegacyRecurrence(
  List<LegacyTask> legacy, {
  required String Function() newId,
}) {
  final result = <StoredTask>[];
  final groups = <String, List<LegacyTask>>{};

  for (final l in legacy) {
    final rule = RecurrenceRule.fromLegacyPattern(l.pattern);
    if (l.templateId == null || rule == null) {
      result.add(StoredTask(_standalone(l.task)));
    } else {
      groups.putIfAbsent(l.templateId!, () => []).add(l);
    }
  }

  for (final entry in groups.entries) {
    result.addAll(_collapseGroup(entry.key, entry.value, newId));
  }
  return result;
}

Task _standalone(Task t) =>
    t.copyWith(recurrence: null, seriesId: null, occurrenceDate: null);

List<StoredTask> _collapseGroup(
  String templateId,
  List<LegacyTask> group,
  String Function() newId,
) {
  final pattern = group.first.pattern;
  final sorted = group.map((l) => l.task).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  // Pre-1.0 stepped day-based patterns by 24 hours of absolute time, so
  // every instance after a DST change landed an hour off the time the user
  // picked. Undo exactly that shift, relative to the first instance.
  final firstOffset = sorted.first.startTime.timeZoneOffset;
  final instances = _dayStepped.contains(pattern)
      ? [
          for (final t in sorted)
            () {
              final shift = t.startTime.timeZoneOffset - firstOffset;
              return shift == Duration.zero
                  ? t
                  : t.copyWith(
                      startTime: t.startTime.subtract(shift),
                      endTime: t.endTime.subtract(shift));
            }()
        ]
      : sorted;
  final rule = RecurrenceRule.fromLegacyPattern(group.first.pattern)!;
  if (instances.length < 2) {
    return [for (final t in instances) StoredTask(_standalone(t))];
  }

  // The series takes its time of day and length from the most common values,
  // and its other fields from the latest instance, which reflects the most
  // recent "edit all future" change.
  final minuteOfDayMode = _mode(instances.map((t) => minuteOfDay(t.startTime)));
  final durationMode = _mode(instances.map((t) => t.durationMinutes));
  final latest = instances.last;
  final firstDate = LocalDate.of(instances.first.startTime);
  final seriesStart = firstDate.at(0, minuteOfDayMode);

  final series = latest.copyWith(
    id: templateId,
    startTime: seriesStart,
    endTime: addWallMinutes(seriesStart, durationMode),
    isCompleted: false,
    recurrence: rule,
    seriesId: null,
    occurrenceDate: null,
  );
  final result = <StoredTask>[StoredTask(series)];

  final byDate = <LocalDate, Task>{};
  for (final t in instances) {
    final date = LocalDate.of(t.startTime);
    if (byDate.containsKey(date)) {
      result.add(StoredTask(_standalone(t)));
    } else {
      byDate[date] = t;
    }
  }

  final lastDate = LocalDate.of(instances.last.startTime);
  for (final date
      in rule.occurrences(firstDate, from: firstDate, to: lastDate)) {
    final generated = SeriesExpander.occurrenceOn(series, date);
    final instance = byDate.remove(date);
    if (instance == null) {
      result.add(StoredTask(
        generated.copyWith(id: newId(), recurrence: null, isVirtual: false),
        isCancelled: true,
      ));
      continue;
    }
    if (!instance.sameContentAs(generated)) {
      result.add(StoredTask(instance.copyWith(
        recurrence: null,
        seriesId: series.id,
        occurrenceDate: date,
      )));
    }
  }

  // Whatever is left doesn't fall on a date the pattern produces.
  for (final t in byDate.values) {
    result.add(StoredTask(_standalone(t)));
  }
  return result;
}

const _dayStepped = {'daily', 'weekdays', 'weekly', 'fortnightly'};

int _mode(Iterable<int> values) {
  final counts = <int, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}
