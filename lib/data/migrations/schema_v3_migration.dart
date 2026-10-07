import 'package:drift/drift.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/datasources/task_row_mapper.dart';
import 'package:timeflow/data/migrations/legacy_recurrence.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:uuid/uuid.dart';

/// Migrates a schema 1/2 database to schema 3.
///
/// Schema 3 stores task times as wall-clock text instead of epoch seconds,
/// and stores recurring tasks as a rule plus overrides instead of
/// pre-generated rows. The table is rebuilt: old rows are read, converted in
/// Dart (epoch -> local wall clock using the device's time zone), and
/// written into the new table.
Future<void> migrateToSchemaV3(AppDatabase db, Migrator m, int from) async {
  final rows = await db.customSelect('SELECT * FROM tasks').get();
  await db.customStatement('ALTER TABLE tasks RENAME TO tasks_v2');
  await m.createTable(db.tasks);
  await m.createIndex(db.tasksStartAt);
  await m.createIndex(db.tasksSeriesOccurrence);
  await m.createTable(db.attachments);

  final legacy = rows.map((r) => legacyTaskFromV2Row(r.data)).toList();
  final stored = collapseLegacyRecurrence(legacy, newId: const Uuid().v4);
  await db.batch((b) => b.insertAll(db.tasks, stored.map(storedToCompanion)));

  await db.customStatement('DROP TABLE tasks_v2');
}

/// Reads a row of the schema 1/2 `tasks` table. Times were epoch seconds.
LegacyTask legacyTaskFromV2Row(Map<String, Object?> r) {
  DateTime time(String column) =>
      DateTime.fromMillisecondsSinceEpoch((r[column] as int) * 1000);
  bool flag(String column) => (r[column] as int? ?? 0) != 0;

  return LegacyTask(
    Task(
      id: r['id'] as String,
      title: r['title'] as String,
      description: r['description'] as String?,
      startTime: time('start_time'),
      endTime: time('end_time'),
      isImportant: flag('is_important'),
      isCompleted: flag('is_completed'),
      reminderMinutes: r['reminder_minutes'] as int?,
      notes: r['notes'] as String?,
      attachmentPath: r['attachment_path'] as String?,
      color: r['color'] as String?,
      categoryId: r['category'] as String? ?? TaskCategory.noneId,
      createdAt: time('created_at'),
      updatedAt: time('updated_at'),
    ),
    pattern: r['recurring_pattern'] as String?,
    templateId: r['recurring_template_id'] as String?,
  );
}
