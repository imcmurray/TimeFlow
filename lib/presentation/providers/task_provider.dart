import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/services/task_service.dart';

/// An inclusive range of calendar days.
@immutable
class DayRange {
  final LocalDate first;
  final LocalDate last;

  const DayRange(this.first, this.last);

  const DayRange.single(LocalDate day) : this(day, day);

  /// Start of [first] (inclusive).
  DateTime get start => first.startOfDay;

  /// Start of the day after [last] (exclusive).
  DateTime get end => last.addDays(1).startOfDay;

  bool contains(LocalDate day) => !day.isBefore(first) && !day.isAfter(last);

  @override
  bool operator ==(Object other) =>
      other is DayRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'DayRange($first..$last)';
}

/// The app database. Overridden in tests with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(appDatabaseProvider)),
);

final taskServiceProvider = Provider<TaskService>(
  (ref) => TaskService(ref.watch(taskRepositoryProvider)),
);

/// Tasks and occurrences overlapping a range of days, kept up to date.
final tasksInRangeProvider =
    StreamProvider.autoDispose.family<List<Task>, DayRange>((ref, range) {
  return ref.watch(taskRepositoryProvider).watchRange(range.start, range.end);
});

/// Tasks and occurrences on one day.
final tasksForDayProvider =
    StreamProvider.autoDispose.family<List<Task>, LocalDate>((ref, day) {
  final range = DayRange.single(day);
  return ref.watch(taskRepositoryProvider).watchRange(range.start, range.end);
});

/// The days of a month (given by any date in it) that have at least one task.
final monthTaskDaysProvider =
    StreamProvider.autoDispose.family<Set<LocalDate>, LocalDate>((ref, month) {
  final first = LocalDate(month.year, month.month, 1);
  final last = LocalDate(month.year, month.month + 1, 0);
  final range = DayRange(first, last);
  return ref
      .watch(taskRepositoryProvider)
      .watchRange(range.start, range.end)
      .map((tasks) => {
            for (final t in tasks)
              for (var d = LocalDate.of(t.startTime);
                  !d.isAfter(LocalDate.of(t.endTime)) && !d.isAfter(last);
                  d = d.addDays(1))
                // A task ending exactly at midnight doesn't occupy the next day.
                if (!d.isBefore(first) &&
                    (d == LocalDate.of(t.startTime) ||
                        t.endTime.isAfter(d.startOfDay)))
                  d,
          });
});
