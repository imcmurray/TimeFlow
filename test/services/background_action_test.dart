import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/reminder_ack_provider.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/services/background_breadcrumb.dart';
import 'package:timeflow/services/notification_service.dart';
import 'package:timeflow/services/reminder_actions.dart';
import 'package:timeflow/services/reminder_coordinator.dart';
import 'package:timeflow/services/task_service.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late Task task;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await BackgroundBreadcrumb.clear();
    db = memoryDatabase();
    tasks = TaskRepository(db);
    // A reminder that has just fired, which is the only state these buttons
    // are ever pressed in.
    final start = DateTime.now().add(const Duration(minutes: 10));
    await TaskService(
      tasks,
    ).create(draft('Collect the car', start: start, reminder: 10));
    task = (await tasks.getRange(
      start.subtract(const Duration(days: 1)),
      start.add(const Duration(days: 1)),
    )).single;
  });
  tearDown(() => db.close());

  Future<ReminderAck?> ackOf(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return ReminderAcksNotifier.load(prefs)[id];
  }

  ReminderResponse response(ReminderAction? action) =>
      ReminderResponse(ReminderPayload(task.id, task.startTime), action);

  /// Re-read the way production does, through the same occurrence lookup.
  Future<Task> reread() async =>
      (await findTask(tasks, ReminderPayload(task.id, task.startTime)))!;

  test('Completed marks the task done, with the app closed', () async {
    await applyInBackground(tasks, response(ReminderActions.completed), task);
    final after = await reread();
    expect(after.isCompleted, isTrue);
  });

  test('and so does a "done" button from the older build', () async {
    await applyInBackground(tasks, response(ReminderActions.legacyDone), task);
    expect((await reread()).isCompleted, isTrue);
  });

  test('Dismiss leaves the task alone and clears the in-app alert', () async {
    await applyInBackground(tasks, response(ReminderActions.dismiss), task);
    final after = await reread();
    expect(after.isCompleted, isFalse, reason: 'dismiss is "seen", not "done"');
    // The red card has to go too, or the app keeps nagging about a reminder the
    // tester already answered on the lock screen (TimeFlow#68).
    expect((await ackOf(task.id))?.acknowledged, isTrue);
    expect(
      reminderStateOf(after, DateTime.now(), await ackOf(task.id)),
      ReminderState.acknowledged,
    );
  });

  test(
    'a snooze stands even when the new notification cannot be scheduled',
    () async {
      // There is no notification plugin in a test, so scheduling throws here —
      // which is the point: the ack is written first, so the alert stops either
      // way, and the breadcrumb says the reschedule is what failed.
      await applyInBackground(tasks, response(ReminderActions.snooze5), task);
      final ack = await ackOf(task.id);
      expect(ack?.snoozedUntil, isNotNull);
      expect(
        ack!.snoozedUntil!.difference(DateTime.now()).inMinutes,
        closeTo(5, 1),
      );
      expect((await reread()).isCompleted, isFalse);
      expect(await BackgroundBreadcrumb.read(), contains('not rescheduled'));
    },
  );

  test(
    'a plain tap changes nothing: the app opens and takes it from there',
    () async {
      await applyInBackground(tasks, response(null), task);
      expect((await reread()).isCompleted, isFalse);
      expect(await ackOf(task.id), isNull);
    },
  );
}
