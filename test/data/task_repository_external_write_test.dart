import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/services/background_breadcrumb.dart';
import 'package:timeflow/services/notification_service.dart';
import 'package:timeflow/services/reminder_actions.dart';
import 'package:timeflow/services/reminder_coordinator.dart';
import 'package:timeflow/services/task_service.dart';

import '../helpers/test_db.dart';

/// The app and a reminder action's background isolate each open their own
/// connection to the same file. Drift only invalidates its streams for writes
/// made through the connection that owns them.
void main() {
  late Directory dir;
  late AppDatabase app;
  late AppDatabase background;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('timeflow_external_write');
    final file = File('${dir.path}/timeflow.db');
    // Each on its own isolate, as in the app: a connection waiting on SQLite's
    // busy timeout blocks its thread, so two on one thread would deadlock.
    app = AppDatabase(NativeDatabase.createInBackground(file));
    background = AppDatabase(NativeDatabase.createInBackground(file));
  });

  tearDown(() async {
    await app.close();
    await background.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 300));

  test('a completion written by another connection shows once the app '
      'marks tasks changed', () async {
    final appRepo = TaskRepository(app);
    final created = await TaskService(
      appRepo,
    ).create(draft('Lunch', start: DateTime(2026, 6, 3, 12)));

    final emitted = <List<Task>>[];
    final sub = appRepo
        .watchRange(DateTime(2026, 6, 3), DateTime(2026, 6, 4))
        .listen(emitted.add);
    await settle();
    expect(emitted.last.single.isCompleted, isFalse);

    // What notificationBackgroundHandler does: its own repository, its own
    // connection.
    final backgroundRepo = TaskRepository(background);
    final seen = (await backgroundRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).single;
    expect(seen.id, created.id);
    await TaskService(backgroundRepo).setCompleted(seen, true);

    // The app's stream doesn't hear about it on its own...
    await settle();
    expect(
      emitted.last.single.isCompleted,
      isFalse,
      reason: 'drift should not see the other connection write',
    );

    // ...until the app comes back to the foreground and says so.
    appRepo.markChangedElsewhere();
    await settle();
    expect(emitted.last.single.isCompleted, isTrue);
    await sub.cancel();
  });

  test('the other connection can save while the app is reading', () async {
    final appRepo = TaskRepository(app);
    await TaskService(
      appRepo,
    ).create(draft('Lunch', start: DateTime(2026, 6, 3, 12)));
    final backgroundRepo = TaskRepository(background);
    final seen = (await backgroundRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).single;

    // What the tester's breadcrumb caught: the task was found and written,
    // then COMMIT failed with "database is locked". iOS had started the
    // app's main isolate for the same launch and it was reading tasks, and
    // under SQLite's default rollback journal a reader blocks a writer's
    // commit. A plain BEGIN takes that reader's lock and holds it.
    //
    // Two connections in one process never wait for each other, whatever
    // busy_timeout says: SQLite returns SQLITE_BUSY without calling the busy
    // handler rather than risk a deadlock. So a test that has the app hold a
    // write lock can't pass, and the timeout is not what saves this. WAL is:
    // it lets a reader and a writer run at once.
    await app.customStatement('BEGIN;');
    await app.customSelect('SELECT count(*) FROM tasks;').getSingle();

    await TaskService(backgroundRepo).setCompleted(seen, true);
    await app.customStatement('COMMIT;');
    final after = await appRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    );
    expect(after.single.isCompleted, isTrue);
  });

  test('a save made while the app is writing waits and lands', () async {
    await BackgroundBreadcrumb.clear();
    addTearDown(BackgroundBreadcrumb.clear);
    final appRepo = TaskRepository(app);
    await TaskService(
      appRepo,
    ).create(draft('Lunch', start: DateTime(2026, 6, 3, 12)));
    final backgroundRepo = TaskRepository(background);
    final seen = (await backgroundRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).single;

    // WAL is no help when the app's isolate is the one writing. What the other
    // connection does then depends on the SQLite underneath: on Linux it is
    // refused at once and writeWithRetries waits and tries again; on macOS it
    // honours busy_timeout and simply waits out the app's transaction. Either
    // way the save has to land, which is what this asserts. The retry itself
    // is pinned in background_write_retry_test.dart, where the refusal is
    // forced rather than left to the platform. Holding it for less than the
    // first retry's wait is the real shape — a first launch seeding
    // categories, say, not something that stays locked.
    final inside = Completer<void>();
    final appBusy = app.transaction(() async {
      await app.customStatement('UPDATE tasks SET title = title;');
      inside.complete();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await inside.future;

    await applyInBackground(
      backgroundRepo,
      ReminderResponse(
        ReminderPayload(seen.id, seen.startTime),
        ReminderActions.completed,
      ),
      seen,
    );
    await appBusy;

    // Null where nothing was refused; where something was, only the waits.
    final crumb = await BackgroundBreadcrumb.read();
    expect(
      (crumb ?? '')
          .split('\n')
          .where((l) => l.isNotEmpty)
          .every((l) => l.contains(BackgroundBreadcrumb.locked)),
      isTrue,
      reason: 'a refusal may be retried, never fail: $crumb',
    );
    final after = await appRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    );
    expect(after.single.isCompleted, isTrue);
  });
}
