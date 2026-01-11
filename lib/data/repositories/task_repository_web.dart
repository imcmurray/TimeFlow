import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';

/// Web implementation using SharedPreferences with JSON storage.
class TaskRepositoryImpl implements TaskRepository {
  static const _tasksKey = 'timeflow_tasks';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Map<String, Task>> _loadTasks() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_tasksKey);
    if (jsonString == null) return {};

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final tasks = <String, Task>{};
    for (final json in jsonList) {
      final task = Task.fromJson(json as Map<String, dynamic>);
      tasks[task.id] = task;
    }
    return tasks;
  }

  Future<void> _saveTasks(Map<String, Task> tasks) async {
    final prefs = await _preferences;
    final jsonList = tasks.values.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(jsonList));
  }

  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final tasks = await _loadTasks();
    return tasks.values
        .where((task) =>
            task.startTime.isBefore(dayEnd) && task.endTime.isAfter(dayStart))
        .toList();
  }

  @override
  Future<List<Task>> getTasksForRange(
      DateTime startDate, DateTime endDate) async {
    final rangeStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final rangeEnd = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    final tasks = await _loadTasks();
    return tasks.values
        .where((task) =>
            task.startTime.isBefore(rangeEnd) && task.endTime.isAfter(rangeStart))
        .toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final tasks = await _loadTasks();
    return tasks[id];
  }

  @override
  Future<void> save(Task task) async {
    final tasks = await _loadTasks();
    tasks[task.id] = task;
    await _saveTasks(tasks);
  }

  @override
  Future<void> saveAll(List<Task> taskList) async {
    final tasks = await _loadTasks();
    for (final task in taskList) {
      tasks[task.id] = task;
    }
    await _saveTasks(tasks);
  }

  @override
  Future<List<Task>> getByTemplateId(String templateId) async {
    final tasks = await _loadTasks();
    return tasks.values
        .where((task) => task.recurringTemplateId == templateId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<void> updateFutureByTemplateId(
    String templateId,
    DateTime fromDate,
    Task Function(Task) update,
  ) async {
    final tasks = await _loadTasks();
    for (final task in tasks.values) {
      if (task.recurringTemplateId == templateId &&
          !task.startTime.isBefore(fromDate)) {
        tasks[task.id] = update(task);
      }
    }
    await _saveTasks(tasks);
  }

  @override
  Future<void> delete(String id) async {
    final tasks = await _loadTasks();
    tasks.remove(id);
    await _saveTasks(tasks);
  }

  @override
  Future<void> deleteByTemplateId(String templateId) async {
    final tasks = await _loadTasks();
    tasks.removeWhere((_, task) => task.recurringTemplateId == templateId);
    await _saveTasks(tasks);
  }

  @override
  Future<void> deleteFutureByTemplateId(
      String templateId, DateTime fromDate) async {
    final tasks = await _loadTasks();
    tasks.removeWhere((_, task) =>
        task.recurringTemplateId == templateId &&
        !task.startTime.isBefore(fromDate));
    await _saveTasks(tasks);
  }

  @override
  Future<List<Task>> getAll() async {
    final tasks = await _loadTasks();
    return tasks.values.toList();
  }

  @override
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_tasksKey);
  }

  @override
  Future<int> count() async {
    final tasks = await _loadTasks();
    return tasks.length;
  }

  @override
  Future<String> exportToJson() async {
    final tasks = await getAll();
    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }

  @override
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
