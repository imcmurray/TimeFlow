import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/services/task_service.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late TaskService service;

  setUp(() {
    db = memoryDatabase();
    repo = TaskRepository(db);
    service = TaskService(repo, clock: () => DateTime(2026, 6, 1, 12));
  });
  tearDown(() => db.close());

  Future<List<Task>> day(int month, int d) =>
      repo.getRange(DateTime(2026, month, d), DateTime(2026, month, d + 1));

  Future<List<Task>> range(DateTime from, DateTime to) =>
      repo.getRange(from, to);

  group('standalone tasks', () {
    test('create, read back, complete, delete', () async {
      final t = await service.create(
        draft('Dentist', start: DateTime(2026, 6, 3, 14)),
      );
      var tasks = await day(6, 3);
      expect(tasks.single.title, 'Dentist');
      expect(tasks.single.id, t.id);

      await service.setCompleted(tasks.single, true);
      tasks = await day(6, 3);
      expect(tasks.single.isCompleted, isTrue);

      await service.delete(tasks.single, EditScope.thisOnly);
      expect(await day(6, 3), isEmpty);
    });

    test('a task crossing midnight shows on both days', () async {
      await service.create(
        draft('Night shift', start: DateTime(2026, 6, 3, 22), minutes: 240),
      );
      expect((await day(6, 3)).length, 1);
      expect((await day(6, 4)).length, 1);
      expect(await day(6, 5), isEmpty);
    });

    test('editing can clear optional fields', () async {
      await service.create(
        draft('Call', start: DateTime(2026, 6, 3, 9), reminder: 15),
      );
      final t = (await day(6, 3)).single;
      await service.update(t, t.copyWith(reminderMinutes: null), EditScope.all);
      expect((await day(6, 3)).single.reminderMinutes, isNull);
    });

    test('adding a recurrence turns a task into a series', () async {
      await service.create(draft('Meds', start: DateTime(2026, 6, 3, 8)));
      final t = (await day(6, 3)).single;
      await service.update(
        t,
        t.copyWith(recurrence: RecurrenceRule.daily),
        EditScope.all,
      );
      final week = await range(DateTime(2026, 6, 3), DateTime(2026, 6, 10));
      expect(week.length, 7);
      expect(week.every((o) => o.isOccurrence && o.title == 'Meds'), isTrue);
    });
  });

  group('series', () {
    late Task series;
    setUp(() async {
      series = await service.create(
        draft(
          'Walk dogs',
          start: DateTime(2026, 6, 1, 7),
          minutes: 30,
          rule: RecurrenceRule.daily,
        ),
      );
    });

    test('occurrences are generated indefinitely', () async {
      expect((await day(6, 1)).single.isVirtual, isTrue);
      final later = await range(DateTime(2027, 6, 1), DateTime(2027, 6, 2));
      expect(later.single.title, 'Walk dogs');
      expect(await repo.count(), 1);
    });

    test('completing one occurrence affects only that day', () async {
      await service.setCompleted((await day(6, 2)).single, true);
      expect((await day(6, 2)).single.isCompleted, isTrue);
      expect((await day(6, 2)).single.isVirtual, isFalse);
      expect((await day(6, 3)).single.isCompleted, isFalse);
      // Toggling back reuses the stored override.
      await service.setCompleted((await day(6, 2)).single, false);
      expect((await day(6, 2)).single.isCompleted, isFalse);
      expect((await repo.overridesOf(series.id)).length, 1);
    });

    test('edit this occurrence only', () async {
      final occ = (await day(6, 3)).single;
      await service.update(
        occ,
        occ.copyWith(
          title: 'Long walk',
          startTime: DateTime(2026, 6, 3, 8),
          endTime: DateTime(2026, 6, 3, 9),
        ),
        EditScope.thisOnly,
      );
      final moved = (await day(6, 3)).single;
      expect(moved.title, 'Long walk');
      expect(moved.startTime.hour, 8);
      expect(moved.recurrence, RecurrenceRule.daily);
      expect((await day(6, 4)).single.title, 'Walk dogs');
    });

    test('moving an occurrence to another day keeps its slot empty', () async {
      final occ = (await day(6, 3)).single;
      await service.update(
        occ,
        occ.copyWith(
          startTime: DateTime(2026, 6, 4, 18),
          endTime: DateTime(2026, 6, 4, 18, 30),
        ),
        EditScope.thisOnly,
      );
      expect(await day(6, 3), isEmpty);
      expect((await day(6, 4)).length, 2);
    });

    test('delete this occurrence only', () async {
      await service.delete((await day(6, 3)).single, EditScope.thisOnly);
      expect(await day(6, 3), isEmpty);
      expect(await day(6, 4), isNotEmpty);
    });

    test('delete this and future', () async {
      await service.delete((await day(6, 5)).single, EditScope.thisAndFuture);
      final june = await range(DateTime(2026, 6, 1), DateTime(2026, 7, 1));
      expect(june.map((t) => t.startTime.day), [1, 2, 3, 4]);
    });

    test('delete all removes the series and its overrides', () async {
      await service.setCompleted((await day(6, 2)).single, true);
      await service.delete((await day(6, 4)).single, EditScope.all);
      expect(await range(DateTime(2026, 6, 1), DateTime(2026, 7, 1)), isEmpty);
      expect(await repo.count(), 0);
    });

    test(
      'edit all: rename and retime carries over to plain overrides',
      () async {
        await service.setCompleted((await day(6, 2)).single, true);
        final renamedByHand = (await day(6, 3)).single;
        await service.update(
          renamedByHand,
          renamedByHand.copyWith(title: 'Vet visit'),
          EditScope.thisOnly,
        );

        final occ = (await day(6, 10)).single;
        await service.update(
          occ,
          occ.copyWith(
            title: 'Morning walk',
            startTime: DateTime(2026, 6, 10, 6, 30),
            endTime: DateTime(2026, 6, 10, 7, 15),
          ),
          EditScope.all,
        );

        final d2 = (await day(6, 2)).single;
        expect(d2.title, 'Morning walk');
        expect(d2.isCompleted, isTrue);
        expect(d2.startTime, DateTime(2026, 6, 2, 6, 30));
        expect(d2.durationMinutes, 45);
        final d3 = (await day(6, 3)).single;
        expect(d3.title, 'Vet visit', reason: 'individual edit is kept');
        final d20 = (await day(6, 20)).single;
        expect(d20.title, 'Morning walk');
        expect(d20.startTime.hour, 6);
      },
    );

    test('edit this and future splits the series', () async {
      await service.setCompleted((await day(6, 2)).single, true);
      await service.setCompleted((await day(6, 12)).single, true);
      final occ = (await day(6, 10)).single;
      await service.update(
        occ,
        occ.copyWith(
          title: 'Evening walk',
          startTime: DateTime(2026, 6, 10, 19),
          endTime: DateTime(2026, 6, 10, 19, 30),
        ),
        EditScope.thisAndFuture,
      );

      expect((await day(6, 9)).single.title, 'Walk dogs');
      expect((await day(6, 2)).single.isCompleted, isTrue);
      final d10 = (await day(6, 10)).single;
      expect(d10.title, 'Evening walk');
      expect(d10.startTime.hour, 19);
      final d12 = (await day(6, 12)).single;
      expect(d12.title, 'Evening walk');
      expect(d12.isCompleted, isTrue, reason: 'completion survives the split');
      expect(d12.startTime.hour, 19);
      expect(await repo.count(), 2);
    });

    test(
      'this and future on the first occurrence edits the whole series',
      () async {
        final occ = (await day(6, 1)).single;
        await service.update(
          occ,
          occ.copyWith(title: 'Walk'),
          EditScope.thisAndFuture,
        );
        expect(await repo.count(), 1);
        expect((await day(6, 5)).single.title, 'Walk');
      },
    );

    test('changing the pattern for this and future', () async {
      final occ = (await day(6, 8)).single; // a Monday
      await service.update(
        occ,
        occ.copyWith(recurrence: RecurrenceRule.weekly),
        EditScope.thisAndFuture,
      );
      final june = await range(DateTime(2026, 6, 1), DateTime(2026, 7, 1));
      expect(june.map((t) => t.startTime.day), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        15,
        22,
        29,
      ]);
    });

    test('stop repeating keeps history and leaves one plain task', () async {
      await service.setCompleted((await day(6, 2)).single, true);
      final occ = (await day(6, 5)).single;
      await service.update(occ, occ.copyWith(recurrence: null), EditScope.all);
      final june = await range(DateTime(2026, 6, 1), DateTime(2026, 7, 1));
      expect(june.map((t) => t.startTime.day), [1, 2, 3, 4, 5]);
      expect(june.last.isRecurring, isFalse);
      expect(june[1].isCompleted, isTrue);
    });

    test('watchRange emits on change', () async {
      final stream = repo.watchRange(
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
      );
      final seen = <bool>[];
      final sub = stream.listen((t) => seen.add(t.single.isCompleted));
      await pumpEventQueue();
      await service.setCompleted((await day(6, 2)).single, true);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isFalse);
      expect(seen.last, isTrue);
    });
  });

  group('backup', () {
    test('round-trips series, overrides and cancellations', () async {
      final s = await service.create(
        draft(
          'Meds',
          start: DateTime(2026, 6, 1, 8),
          rule: RecurrenceRule.daily,
        ),
      );
      await service.create(draft('Dentist', start: DateTime(2026, 6, 3, 14)));
      await service.setCompleted((await day(6, 2)).single, true);
      await service.delete(
        (await day(6, 4)).firstWhere((t) => t.seriesId == s.id),
        EditScope.thisOnly,
      );
      final json = await repo.exportToJson();
      final before = await range(DateTime(2026, 6, 1), DateTime(2026, 6, 8));

      await repo.clear();
      expect(await repo.importFromJson(json), 2);
      final after = await range(DateTime(2026, 6, 1), DateTime(2026, 6, 8));
      expect(
        after.map((t) => (t.title, t.startTime, t.isCompleted)),
        before.map((t) => (t.title, t.startTime, t.isCompleted)),
      );
      expect(after.where((t) => t.startTime.day == 4), isEmpty);
    });

    test('rejects files that are not backups', () async {
      expect(() => repo.importFromJson('hello'), throwsA(isA<Exception>()));
      expect(
        () => repo.importFromJson('{"version": 9, "tasks": []}'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('photos', () {
    test('stored, carried by backups, and pruned when unused', () async {
      final photo = Uint8List.fromList([1, 2, 3, 4]);
      final ref = await repo.saveAttachment(photo, 'image/jpeg');
      final task = await service.create(draft('Vet',
          start: DateTime(2026, 6, 3, 9)).copyWith(attachmentPath: ref));
      expect((await repo.attachment(ref))!.bytes, photo);

      final json = await repo.exportToJson();
      await repo.clear();
      expect(await repo.attachment(ref), isNull);
      await repo.importFromJson(json);
      expect((await repo.attachment(ref))!.bytes, photo);

      expect(await repo.pruneAttachments(), 0);
      final stored = (await day(6, 3)).single;
      await service.update(stored, stored.copyWith(attachmentPath: null),
          EditScope.all);
      expect(await repo.pruneAttachments(), 1);
      expect(await repo.attachment(ref), isNull);
      expect(task.attachmentPath, ref);
    });
  });

  test('LocalDate keys survive in overrides', () async {
    final s = await service.create(
      draft('X', start: DateTime(2026, 6, 1, 8), rule: RecurrenceRule.daily),
    );
    await service.setCompleted((await day(6, 2)).single, true);
    final o = (await repo.overridesOf(s.id)).single;
    expect(o.task.occurrenceDate, LocalDate(2026, 6, 2));
  });
}
