import 'package:drift/drift.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/migrations/legacy_recurrence.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/local_date.dart';

/// Converts between drift rows and domain [Task]s.
extension TaskRowMapping on TaskRow {
  /// The domain task for this row. [seriesRule] fills in the repeat rule for
  /// overrides, whose own row doesn't store it.
  Task toTask({RecurrenceRule? seriesRule}) => Task(
    id: id,
    title: title,
    description: description,
    notes: notes,
    startTime: startAt,
    endTime: endAt,
    isImportant: isImportant,
    isCompleted: isCompleted,
    reminderMinutes: reminderMinutes,
    attachmentPath: attachmentPath,
    color: color,
    categoryId: category,
    recurrence: recurrence != null
        ? RecurrenceRule.parse(recurrence!)
        : seriesRule,
    seriesId: seriesId,
    occurrenceDate: occurrenceDate != null
        ? LocalDate.parseIso(occurrenceDate!)
        : null,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

TasksCompanion taskToCompanion(Task task, {bool isCancelled = false}) =>
    TasksCompanion.insert(
      id: task.id,
      title: task.title,
      description: Value(task.description),
      notes: Value(task.notes),
      startAt: task.startTime,
      endAt: task.endTime,
      isImportant: Value(task.isImportant),
      isCompleted: Value(task.isCompleted),
      reminderMinutes: Value(task.reminderMinutes),
      attachmentPath: Value(task.attachmentPath),
      color: Value(task.color),
      category: Value(task.categoryId),
      // Only series rows store the rule; occurrences inherit it.
      recurrence: Value(task.isOccurrence ? null : task.recurrence?.toRRule()),
      seriesId: Value(task.seriesId),
      occurrenceDate: Value(task.occurrenceDate?.toIso()),
      isCancelled: Value(isCancelled),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );

TasksCompanion storedToCompanion(StoredTask s) =>
    taskToCompanion(s.task, isCancelled: s.isCancelled);

/// Converts between drift rows and [TaskCategory]s.
extension CategoryRowMapping on CategoryRow {
  TaskCategory toCategory() => TaskCategory(
    id: id,
    name: name,
    icon: icon,
    colorValue: color,
    sortOrder: sortOrder,
    builtIn: builtIn,
  );
}

CategoriesCompanion categoryToCompanion(TaskCategory c) =>
    CategoriesCompanion.insert(
      id: c.id,
      name: c.name,
      icon: c.icon,
      color: c.colorValue,
      sortOrder: Value(c.sortOrder),
      builtIn: Value(c.builtIn),
    );
