import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/reminders/reminder_planner.dart';

Task t(String id, DateTime start, {int? reminder = 10, bool done = false}) {
  final c = DateTime(2026);
  return Task(
    id: id,
    title: id,
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    reminderMinutes: reminder,
    isCompleted: done,
    createdAt: c,
    updatedAt: c,
  );
}

void main() {
  final now = DateTime(2026, 6, 1, 12);
  const planner = ReminderPlanner(horizon: Duration(days: 2), limit: 3);

  test('plans future reminders soonest first', () {
    final plan = planner.plan([
      t('b', DateTime(2026, 6, 1, 15)),
      t('a', DateTime(2026, 6, 1, 13)),
    ], now: now);
    expect(plan.map((p) => p.task.id), ['a', 'b']);
    expect(plan.first.fireAt, DateTime(2026, 6, 1, 12, 50));
  });

  test('skips completed, reminderless, already-due and out-of-horizon', () {
    final plan = planner.plan([
      t('done', DateTime(2026, 6, 1, 13), done: true),
      t('none', DateTime(2026, 6, 1, 13), reminder: null),
      t('due', DateTime(2026, 6, 1, 12, 5)),
      t('far', DateTime(2026, 6, 5, 9)),
      t('ok', DateTime(2026, 6, 2, 9)),
    ], now: now);
    expect(plan.map((p) => p.task.id), ['ok']);
  });

  test('caps the number of reminders', () {
    final tasks = [
      for (var h = 13; h < 20; h++) t('t$h', DateTime(2026, 6, 1, h)),
    ];
    expect(planner.plan(tasks, now: now).map((p) => p.task.id), [
      't13',
      't14',
      't15',
    ]);
  });

  test('snoozes move the reminder', () {
    final plan = planner.plan(
      [t('a', DateTime(2026, 6, 1, 13))],
      now: now,
      snoozedUntil: {'a': DateTime(2026, 6, 1, 12, 55)},
    );
    expect(plan.single.fireAt, DateTime(2026, 6, 1, 12, 55));
  });

  test('notification ids are stable and positive', () {
    final a = PlannedReminder.notificationIdFor('series@20260601');
    expect(a, PlannedReminder.notificationIdFor('series@20260601'));
    expect(a, isNot(PlannedReminder.notificationIdFor('series@20260602')));
    expect(a, greaterThan(0));
  });
}
