import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';

/// Global task repository instance.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Notifier that triggers rebuilds when tasks change.
class TaskNotifier extends StateNotifier<int> {
  TaskNotifier() : super(0);

  void notifyTasksChanged() {
    state++;
  }
}

/// Provider to notify widgets when tasks have been modified.
final taskNotifierProvider = StateNotifierProvider<TaskNotifier, int>((ref) {
  return TaskNotifier();
});

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
