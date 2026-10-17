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
    app = AppDatabase(NativeDatabase(file));
    background = AppDatabase(NativeDatabase(file));
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
}
