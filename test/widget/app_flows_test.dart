import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/helpers/task_actions.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/onboarding_screen.dart';
import 'package:timeflow/presentation/screens/settings_screen.dart';
import 'package:timeflow/presentation/screens/share_screen.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';

import '../helpers/pump_app.dart';

Task _draft(String title, DateTime start, {RecurrenceRule? rule}) => Task(
  id: 'x',
  title: title,
  startTime: start,
  endTime: start.add(const Duration(hours: 1)),
  recurrence: rule,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

DateTime _soon() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).add(const Duration(minutes: 30));
}

void main() {
  testWidgets('the timeline shows today\'s tasks around the NOW line', (
    tester,
  ) async {
    final container = await pumpApp(tester, const TimelineScreen());
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(_draft('Walk the dogs', _soon())),
    );
    await settle(tester);
    expect(find.text('Walk the dogs'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('creating a task from the editor saves it', (tester) async {
    final container = await pumpApp(tester, const TaskDetailScreen());
    await tester.enterText(find.byType(TextField).first, 'Dentist');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final count = await tester.runAsync(
      () => container.read(taskRepositoryProvider).count(),
    );
    expect(count, 1);
  });

  testWidgets('the editor refuses a task without a title', (tester) async {
    await pumpApp(tester, const TaskDetailScreen());
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Give the task a name'), findsOneWidget);
  });

  testWidgets('editing a repeating task asks which occurrences to change', (
    tester,
  ) async {
    final container = await pumpApp(tester, const SizedBox());
    final occurrence = await tester.runAsync(() async {
      await container
          .read(taskServiceProvider)
          .create(_draft('Meds', _soon(), rule: RecurrenceRule.daily));
      final start = _soon();
      final tasks = await container
          .read(taskRepositoryProvider)
          .getRange(
            DateTime(start.year, start.month, start.day),
            DateTime(start.year, start.month, start.day + 1),
          );
      return tasks.single;
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: TaskDetailScreen(task: occurrence)),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Morning meds');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('This is a repeating task'), findsOneWidget);
    expect(find.text('Only this one'), findsOneWidget);
    expect(find.text('This and all later ones'), findsOneWidget);
    await tester.tap(find.text('Only this one'));
    await settle(tester);
    final overrides = await tester.runAsync(
      () => container
          .read(taskRepositoryProvider)
          .overridesOf(occurrence!.seriesId!),
    );
    expect(overrides!.single.task.title, 'Morning meds');
  });

  testWidgets('the undo snackbar after deleting a task times out', (
    tester,
  ) async {
    late WidgetRef ref;
    late BuildContext context;
    final container = await pumpApp(
      tester,
      Scaffold(
        body: Consumer(
          builder: (c, r, _) {
            ref = r;
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final task = await tester.runAsync(
      () => container.read(taskServiceProvider).create(_draft('Gym', _soon())),
    );
    await tester.runAsync(() => TaskActions(ref).delete(context, task!));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Deleted "Gym"'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Deleted "Gym"'), findsNothing);
  });

  testWidgets('onboarding can start with a sample day', (tester) async {
    final container = await pumpApp(
      tester,
      const OnboardingScreen(),
      prefs: {'timeflow_first_launch': true},
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start with a sample day'));
    await settle(tester);
    final count = await tester.runAsync(
      () => container.read(taskRepositoryProvider).count(),
    );
    expect(count, greaterThanOrEqualTo(4));
  });

  testWidgets('the share screen previews the day and offers a link', (
    tester,
  ) async {
    final container = await pumpApp(tester, const SizedBox());
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(_draft('Feed Biscuit', _soon())),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ShareScreen(date: _soon())),
      ),
    );
    await settle(tester);
    expect(find.text('Feed Biscuit'), findsOneWidget);
    expect(find.text('Share link'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('settings opens and shows its sections', (tester) async {
    await pumpApp(tester, const SettingsScreen());
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Reminders'), 300);
    expect(find.text('Task reminders'), findsOneWidget);
  });
}
