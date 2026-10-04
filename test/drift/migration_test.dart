import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/time/local_date.dart';

import '../helpers/dst.dart';
import 'generated/schema.dart';
import 'generated/schema_v2.dart' as v2;

/// Schema 2 stored DateTimes as epoch seconds.
int _epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('schema v2 upgrades to the v3 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  group('v2 data', () {
    final created = DateTime(2026, 5, 1);

    v2.TasksCompanion legacy(
      String id,
      String title,
      DateTime start, {
      int minutes = 30,
      bool completed = false,
      String? pattern,
      String? template,
    }) => v2.TasksCompanion.insert(
      id: id,
      title: title,
      startTime: _epoch(start),
      endTime: _epoch(start.add(Duration(minutes: minutes))),
      isCompleted: Value(completed ? 1 : 0),
      recurringPattern: Value(pattern),
      recurringTemplateId: Value(template),
      reminderMinutes: const Value(10),
      createdAt: _epoch(created),
      updatedAt: _epoch(created),
    );

    Future<TaskRepository> migrate(List<v2.TasksCompanion> rows) async {
      final schema = await verifier.schemaAt(2);
      final old = v2.DatabaseAtV2(schema.newConnection());
      await old.batch((b) => b.insertAll(old.tasks, rows));
      await old.close();
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      return TaskRepository(db);
    }

    test('plain tasks keep their wall-clock times', () async {
      final repo = await migrate([
        legacy('a', 'Dentist', DateTime(2026, 6, 3, 14, 15)),
      ]);
      final tasks = await repo.getRange(
        DateTime(2026, 6, 3),
        DateTime(2026, 6, 4),
      );
      expect(tasks.single.title, 'Dentist');
      expect(tasks.single.startTime, DateTime(2026, 6, 3, 14, 15));
      expect(tasks.single.reminderMinutes, 10);
      expect(tasks.single.isRecurring, isFalse);
    });

    test('pre-generated daily instances collapse into a series', () async {
      // Daily 7:00 from June 1 to June 10. June 4 was deleted, June 2 was
      // completed, June 6 renamed.
      final rows = <v2.TasksCompanion>[];
      for (var d = 1; d <= 10; d++) {
        if (d == 4) continue;
        rows.add(
          legacy(
            'i$d',
            d == 6 ? 'Vet' : 'Walk dogs',
            DateTime(2026, 6, d, 7),
            completed: d == 2,
            pattern: 'daily',
            template: 'tpl',
          ),
        );
      }
      final repo = await migrate(rows);

      expect(await repo.count(), 1);
      final series = await repo.getSeries('tpl');
      expect(series!.recurrence, RecurrenceRule.daily);
      expect(series.startTime, DateTime(2026, 6, 1, 7));

      final june = await repo.getRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 11),
      );
      expect(june.map((t) => t.startTime.day), [1, 2, 3, 5, 6, 7, 8, 9, 10]);
      expect(june[1].isCompleted, isTrue);
      expect(june.firstWhere((t) => t.startTime.day == 6).title, 'Vet');

      final overrides = await repo.overridesOf('tpl');
      expect(overrides.map((o) => o.task.occurrenceDate).toSet(), {
        LocalDate(2026, 6, 2),
        LocalDate(2026, 6, 4),
        LocalDate(2026, 6, 6),
      });

      // It no longer stops after the last pre-generated copy.
      final later = await repo.getRange(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
      );
      expect(later.single.title, 'Walk dogs');
    });

    test('instances an hour off after DST are put back', () async {
      // Pre-1.0 stepped daily tasks by 24h of absolute time, so after the
      // March 8 change the "7:00" instances were stored at 8:00.
      final rows = <v2.TasksCompanion>[];
      var t = DateTime(2026, 3, 5, 7);
      for (var i = 0; i < 8; i++) {
        rows.add(legacy('d$i', 'Meds', t, pattern: 'daily', template: 'm'));
        t = t.add(const Duration(days: 1));
      }
      final repo = await migrate(rows);
      final days = await repo.getRange(
        DateTime(2026, 3, 5),
        DateTime(2026, 3, 13),
      );
      expect(days.map((d) => d.startTime.hour), everyElement(7));
      expect(await repo.overridesOf('m'), isEmpty);
    }, skip: skipWithoutDst);
  });
}
