import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart' as domain;

/// Native implementation using Drift/SQLite.
class TaskRepositoryImpl implements TaskRepository {
  late final AppDatabase _database;

  TaskRepositoryImpl() {
    _database = AppDatabase();
  }

  /// Convert domain Task to Drift TasksCompanion for inserts/updates.
  TasksCompanion _toCompanion(domain.Task task) {
    return TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      startTime: Value(task.startTime),
      endTime: Value(task.endTime),
      isImportant: Value(task.isImportant),
      isCompleted: Value(task.isCompleted),
      reminderMinutes: Value(task.reminderMinutes),
      recurringPattern: Value(task.recurringPattern),
      recurringTemplateId: Value(task.recurringTemplateId),
      notes: Value(task.notes),
      attachmentPath: Value(task.attachmentPath),
      color: Value(task.color),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
    );
  }

  /// Convert Drift Task row to domain Task entity.
  domain.Task _fromRow(Task row) {
    return domain.Task(
      id: row.id,
      title: row.title,
      description: row.description,
      startTime: row.startTime,
      endTime: row.endTime,
      isImportant: row.isImportant,
      isCompleted: row.isCompleted,
      reminderMinutes: row.reminderMinutes,
      recurringPattern: row.recurringPattern,
      recurringTemplateId: row.recurringTemplateId,
      notes: row.notes,
      attachmentPath: row.attachmentPath,
      color: row.color,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<List<domain.Task>> getTasksForDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = _database.select(_database.tasks)
      ..where((t) =>
          t.startTime.isSmallerThanValue(dayEnd) &
          t.endTime.isBiggerThanValue(dayStart));

    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<domain.Task>> getTasksForRange(
      DateTime startDate, DateTime endDate) async {
    final rangeStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final rangeEnd = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    final query = _database.select(_database.tasks)
      ..where((t) =>
          t.startTime.isSmallerThanValue(rangeEnd) &
          t.endTime.isBiggerThanValue(rangeStart));

    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<domain.Task?> getById(String id) async {
    final query = _database.select(_database.tasks)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<void> save(domain.Task task) async {
    await _database
        .into(_database.tasks)
        .insertOnConflictUpdate(_toCompanion(task));
  }

  @override
  Future<void> saveAll(List<domain.Task> tasks) async {
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.tasks,
        tasks.map(_toCompanion).toList(),
      );
    });
  }

  @override
  Future<List<domain.Task>> getByTemplateId(String templateId) async {
    final query = _database.select(_database.tasks)
      ..where((t) => t.recurringTemplateId.equals(templateId))
      ..orderBy([(t) => OrderingTerm.asc(t.startTime)]);

    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> updateFutureByTemplateId(
    String templateId,
    DateTime fromDate,
    domain.Task Function(domain.Task) update,
  ) async {
    final tasks = await getByTemplateId(templateId);
    final tasksToUpdate =
        tasks.where((t) => !t.startTime.isBefore(fromDate)).toList();

    await _database.batch((batch) {
      for (final task in tasksToUpdate) {
        final updated = update(task);
        batch.replace(_database.tasks, _toCompanion(updated));
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(_database.tasks)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteByTemplateId(String templateId) async {
    await (_database.delete(_database.tasks)
          ..where((t) => t.recurringTemplateId.equals(templateId)))
        .go();
  }

  @override
  Future<void> deleteFutureByTemplateId(
      String templateId, DateTime fromDate) async {
    await (_database.delete(_database.tasks)
          ..where((t) =>
              t.recurringTemplateId.equals(templateId) &
              t.startTime.isBiggerOrEqualValue(fromDate)))
        .go();
  }

  @override
  Future<List<domain.Task>> getAll() async {
    final rows = await _database.select(_database.tasks).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> clear() async {
    await _database.delete(_database.tasks).go();
  }

  @override
  Future<int> count() async {
    final countExpression = _database.tasks.id.count();
    final query = _database.selectOnly(_database.tasks)
      ..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
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
        .map((json) => domain.Task.fromJson(json as Map<String, dynamic>))
        .toList();
    await saveAll(tasks);
    return tasks.length;
  }
}
