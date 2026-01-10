import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';

/// Represents a date range for fetching tasks.
@immutable
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.start.year == start.year &&
      other.start.month == start.month &&
      other.start.day == start.day &&
      other.end.year == end.year &&
      other.end.month == end.month &&
      other.end.day == end.day;

  @override
  int get hashCode => Object.hash(
        start.year,
        start.month,
        start.day,
        end.year,
        end.month,
        end.day,
      );
}

/// Global task repository instance.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Notifier that triggers rebuilds when tasks change.
class TaskNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyTasksChanged() {
    state++;
  }
}

/// Provider to notify widgets when tasks have been modified.
final taskNotifierProvider = NotifierProvider<TaskNotifier, int>(
  TaskNotifier.new,
);

/// Returns all tasks for a specific date.
///
/// Watches the taskNotifier to rebuild when tasks change.
final tasksForDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  ref.watch(taskNotifierProvider);
  return ref.read(taskRepositoryProvider).getTasksForDate(date);
});

/// Returns all tasks.
final allTasksProvider = Provider<List<Task>>((ref) {
  ref.watch(taskNotifierProvider);
  return ref.read(taskRepositoryProvider).getAll();
});

/// Returns all tasks for a date range.
///
/// Watches the taskNotifier to rebuild when tasks change.
final tasksForRangeProvider =
    Provider.family<List<Task>, DateRange>((ref, range) {
  ref.watch(taskNotifierProvider);
  return ref.read(taskRepositoryProvider).getTasksForRange(range.start, range.end);
});

/// Returns a set of dates that have tasks scheduled.
///
/// Used by the calendar overview to show task indicators.
final datesWithTasksProvider = Provider<Set<DateTime>>((ref) {
  ref.watch(taskNotifierProvider);
  final tasks = ref.read(taskRepositoryProvider).getAll();
  return tasks
      .map((t) => DateTime(t.startTime.year, t.startTime.month, t.startTime.day))
      .toSet();
});
