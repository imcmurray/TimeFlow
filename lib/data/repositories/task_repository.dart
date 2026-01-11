import 'dart:convert';

import 'package:timeflow/domain/entities/task.dart';

import 'task_repository_stub.dart'
    if (dart.library.io) 'task_repository_native.dart'
    if (dart.library.html) 'task_repository_web.dart' as impl;

/// Abstract repository interface for task storage.
///
/// Platform-specific implementations are selected at compile time:
/// - Native (desktop/mobile): Uses Drift/SQLite
/// - Web: Uses SharedPreferences with JSON
abstract class TaskRepository {
  /// Factory constructor that returns platform-specific implementation.
  factory TaskRepository() = impl.TaskRepositoryImpl;

  /// Returns all tasks that overlap with the given date.
  Future<List<Task>> getTasksForDate(DateTime date);

  /// Returns all tasks that overlap with the given date range.
  Future<List<Task>> getTasksForRange(DateTime startDate, DateTime endDate);

  /// Returns a task by its ID, or null if not found.
  Future<Task?> getById(String id);

  /// Saves a task (insert or update).
  Future<void> save(Task task);

  /// Saves multiple tasks at once.
  Future<void> saveAll(List<Task> tasks);

  /// Returns all tasks with the given recurring template ID.
  Future<List<Task>> getByTemplateId(String templateId);

  /// Updates all tasks with the given template ID from the given date onwards.
  Future<void> updateFutureByTemplateId(
    String templateId,
    DateTime fromDate,
    Task Function(Task) update,
  );

  /// Deletes a task by its ID.
  Future<void> delete(String id);

  /// Deletes all tasks with the given recurring template ID.
  Future<void> deleteByTemplateId(String templateId);

  /// Deletes all future tasks with the given template ID.
  Future<void> deleteFutureByTemplateId(String templateId, DateTime fromDate);

  /// Returns all tasks.
  Future<List<Task>> getAll();

  /// Clears all tasks.
  Future<void> clear();

  /// Returns count of all tasks.
  Future<int> count();

  /// Exports all tasks to a JSON string.
  Future<String> exportToJson() async {
    final tasks = await getAll();
    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }

  /// Imports tasks from a JSON string.
  Future<int> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final tasksList = data['tasks'] as List<dynamic>;
    final tasks = tasksList
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
    await saveAll(tasks);
    return tasks.length;
  }
}
