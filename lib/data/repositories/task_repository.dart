import 'package:timeflow/domain/entities/task.dart';

/// In-memory repository for task storage.
///
/// Stores tasks in a map keyed by their unique ID, allowing multiple
/// tasks at the same time slot. For persistent storage, this can be
/// replaced with a Drift database implementation.
class TaskRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  final Map<String, Task> _tasks = {};

  /// Returns all tasks that overlap with the given date.
  List<Task> getTasksForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _tasks.values.where((task) {
      return task.startTime.isBefore(dayEnd) && task.endTime.isAfter(dayStart);
    }).toList();
  }

  /// Returns all tasks that overlap with the given date range.
  List<Task> getTasksForRange(DateTime startDate, DateTime endDate) {
    final rangeStart = DateTime(startDate.year, startDate.month, startDate.day);
    final rangeEnd = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    return _tasks.values.where((task) {
      return task.startTime.isBefore(rangeEnd) && task.endTime.isAfter(rangeStart);
    }).toList();
  }

  /// Returns a task by its ID, or null if not found.
  Task? getById(String id) => _tasks[id];

  /// Saves a task (insert or update).
  void save(Task task) {
    _tasks[task.id] = task;
  }

  /// Saves multiple tasks at once.
  void saveAll(List<Task> tasks) {
    for (final task in tasks) {
      _tasks[task.id] = task;
    }
  }

  /// Returns all tasks with the given recurring template ID.
  List<Task> getByTemplateId(String templateId) {
    return _tasks.values
        .where((task) => task.recurringTemplateId == templateId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Updates all tasks with the given template ID that are on or after the given date.
  /// Applies the update function to each matching task.
  void updateFutureByTemplateId(
    String templateId,
    DateTime fromDate,
    Task Function(Task) update,
  ) {
    final tasksToUpdate = _tasks.values
        .where((task) =>
            task.recurringTemplateId == templateId &&
            !task.startTime.isBefore(fromDate))
        .toList();

    for (final task in tasksToUpdate) {
      _tasks[task.id] = update(task);
    }
  }

  /// Deletes a task by its ID.
  void delete(String id) {
    _tasks.remove(id);
  }

  /// Deletes all tasks with the given recurring template ID.
  void deleteByTemplateId(String templateId) {
    _tasks.removeWhere((_, task) => task.recurringTemplateId == templateId);
  }

  /// Deletes all future tasks with the given template ID (from the given date onwards).
  void deleteFutureByTemplateId(String templateId, DateTime fromDate) {
    _tasks.removeWhere((_, task) =>
        task.recurringTemplateId == templateId &&
        !task.startTime.isBefore(fromDate));
  }

  /// Returns all tasks.
  List<Task> getAll() => _tasks.values.toList();

  /// Clears all tasks.
  void clear() {
    _tasks.clear();
  }
}
