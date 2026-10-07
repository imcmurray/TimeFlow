import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/category_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/categories_screen.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';

import '../helpers/pump_app.dart';

Task _task(String title, DateTime start, String category) => Task(
  id: 'x',
  title: title,
  startTime: start,
  endTime: start.add(const Duration(hours: 1)),
  categoryId: category,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final lastWeek = DateTime.now().subtract(const Duration(days: 7));

  testWidgets('the Categories page shows how many events use each one', (
    tester,
  ) async {
    final container = await pumpApp(tester, const CategoriesScreen());
    await tester.runAsync(() async {
      final service = container.read(taskServiceProvider);
      await service.create(_task('Run', lastWeek, 'health'));
      await service.create(_task('Gym', tomorrow, 'health'));
    });
    await settle(tester);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('1 past · 1 upcoming'), findsOneWidget);
    expect(find.text('Not used'), findsWidgets);
  });

  testWidgets('adding a category from the Categories page', (tester) async {
    final container = await pumpApp(tester, const CategoriesScreen());
    await settle(tester);
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), 'Errands');
    await tester.tap(find.byKey(const Key('category-save')));
    await settle(tester);
    await tester.pumpAndSettle();
    final all = await tester.runAsync(
      () => container.read(categoryRepositoryProvider).getAll(),
    );
    expect(all!.last.name, 'Errands');
    expect(find.text('Errands'), findsOneWidget);
  });

  testWidgets('names must be unique', (tester) async {
    await pumpApp(tester, const CategoriesScreen());
    await settle(tester);
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), 'health');
    await tester.tap(find.byKey(const Key('category-save')));
    await tester.pump();
    expect(
      find.text('There is already a category called "health"'),
      findsOneWidget,
    );
  });

  Future<void> renameHealth(WidgetTester tester, String key) async {
    await tester.longPress(find.text('Health'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rename-field')), 'Fitness');
    await tester.tap(find.text('Rename'));
    await settle(tester);
    expect(find.text('"Health" is in use'), findsOneWidget);
    expect(find.textContaining('1 upcoming event'), findsOneWidget);
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  testWidgets('renaming an in-use category can update all events', (
    tester,
  ) async {
    final container = await pumpApp(tester, const CategoriesScreen());
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(_task('Gym', tomorrow, 'health')),
    );
    await settle(tester);
    await renameHealth(tester, 'update-all');
    final lookup = container.read(categoryLookupProvider);
    expect(lookup['health'].name, 'Fitness');
    expect(lookup.all.where((c) => c.name == 'Health'), isEmpty);
  });

  testWidgets('or save the change as a new category', (tester) async {
    final container = await pumpApp(tester, const CategoriesScreen());
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(_task('Gym', tomorrow, 'health')),
    );
    await settle(tester);
    await renameHealth(tester, 'save-as-new');
    final lookup = container.read(categoryLookupProvider);
    expect(lookup['health'].name, 'Health');
    final fitness = lookup.all.singleWhere((c) => c.name == 'Fitness');
    final ids = lookup.all.map((c) => c.id).toList();
    expect(ids.indexOf(fitness.id), ids.indexOf('health') + 1);
    // The existing event stays on Health.
    final usage = await tester.runAsync(
      () => container.read(categoryRepositoryProvider).usage(DateTime.now()),
    );
    expect(usage!['health']!.upcoming, 1);
    expect(usage[fitness.id], isNull);
  });

  testWidgets('removing an in-use category moves its events', (tester) async {
    final container = await pumpApp(tester, const CategoriesScreen());
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(_task('Gym', tomorrow, 'health')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('remove-health')));
    await settle(tester);
    expect(find.textContaining('Move them to'), findsOneWidget);
    await tester.tap(find.byKey(const Key('move-to')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-remove')));
    await settle(tester);
    final usage = await tester.runAsync(
      () => container.read(categoryRepositoryProvider).usage(DateTime.now()),
    );
    expect(usage!['personal']!.upcoming, 1);
    expect(usage['health'], isNull);
    expect(find.text('Health'), findsNothing);
  });

  testWidgets('the task editor picks, adds and renames categories', (
    tester,
  ) async {
    final container = await pumpApp(tester, const TaskDetailScreen());
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Groceries');
    final field = find.byKey(const Key('category-field'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();

    // Long-press renames in place (nothing uses it yet, so no question).
    await tester.longPress(find.byKey(const Key('pick-meeting')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rename-field')), 'Calls');
    await tester.tap(find.text('Rename'));
    await settle(tester);
    expect(find.text('Calls'), findsOneWidget);

    // A new category is created and picked.
    await tester.tap(find.byKey(const Key('new-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), 'Errands');
    await tester.tap(find.byKey(const Key('category-save')));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: field, matching: find.text('Errands')),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await settle(tester);
    final saved = await tester.runAsync(() async {
      final now = DateTime.now();
      return container
          .read(taskRepositoryProvider)
          .getRange(
            now.subtract(const Duration(days: 1)),
            now.add(const Duration(days: 2)),
          );
    });
    final errands = container
        .read(categoryLookupProvider)
        .all
        .singleWhere((c) => c.name == 'Errands');
    expect(saved!.single.categoryId, errands.id);
  });
}
