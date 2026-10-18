import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
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

    // The app is in a transaction, as it is while starting up on a
    // background launch. Drift begins native transactions IMMEDIATE, so this
    // holds the write lock; without a busy timeout the other connection's
    // save failed at once with "database is locked" (code 5).
    final inside = Completer<void>();
    final appBusy = app.transaction(() async {
      await appRepo.getRange(DateTime(2026, 6, 3), DateTime(2026, 6, 4));
      inside.complete();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await inside.future;

    await TaskService(backgroundRepo).setCompleted(seen, true);
    await appBusy;
    final after = await appRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    );
    expect(after.single.isCompleted, isTrue);
  });
}
