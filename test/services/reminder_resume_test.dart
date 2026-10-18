import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/services/reminder_coordinator.dart';
import 'package:timeflow/services/task_service.dart';

import '../helpers/test_db.dart';

/// task_repository_external_write_test proves the repository can be told that
/// another connection wrote; this proves the app actually tells it, on the one
/// event that matters. Without the call in [didChangeAppLifecycleState] a
/// reminder answered from the lock screen left the task red until a restart
/// (TimeFlow#68), and nothing in the suite would have noticed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 300));

  test('coming back to the foreground shows what the background isolate '
      'wrote', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dir = Directory.systemTemp.createTempSync('timeflow_resume');
    final file = File('${dir.path}/timeflow.db');
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final app = AppDatabase(NativeDatabase(file));
    final background = AppDatabase(NativeDatabase(file));
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(app),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await app.close();
      await background.close();
      dir.deleteSync(recursive: true);
    });

    final appRepo = container.read(taskRepositoryProvider);
    await TaskService(
      appRepo,
    ).create(draft('Lunch', start: DateTime(2026, 6, 3, 12)));

    final emitted = <List<Task>>[];
    final sub = appRepo
        .watchRange(DateTime(2026, 6, 3), DateTime(2026, 6, 4))
        .listen(emitted.add);
    await settle();
    expect(emitted.last.single.isCompleted, isFalse);

    // The reminder's Completed button, handled in the other isolate.
    final backgroundRepo = TaskRepository(background);
    final seen = (await backgroundRepo.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).single;
    await TaskService(backgroundRepo).setCompleted(seen, true);
    await settle();
    expect(
      emitted.last.single.isCompleted,
      isFalse,
      reason: 'the write went through the other connection',
    );

    // What the observer registered in ReminderCoordinator.start does when iOS
    // brings the app to the front.
    container
        .read(reminderCoordinatorProvider)
        .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();
    expect(emitted.last.single.isCompleted, isTrue);
    await sub.cancel();
  });
}
