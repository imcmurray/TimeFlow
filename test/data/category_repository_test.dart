import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/category_repository.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/services/task_service.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;
  late TaskRepository tasks;
  late TaskService service;
  final now = DateTime(2026, 6, 10, 12);

  setUp(() {
    db = memoryDatabase();
    categories = CategoryRepository(db);
    tasks = TaskRepository(db);
    service = TaskService(tasks, clock: () => now);
  });
  tearDown(() => db.close());

  Future<void> task(
    String title,
    DateTime start, {
    String category = 'health',
    RecurrenceRule? rule,
  }) => service.create(
    draft(title, start: start, rule: rule).copyWith(categoryId: category),
  );

  const errands = TaskCategory(
    id: '',
    name: 'Errands',
    icon: 'shopping_cart',
    colorValue: 0xFFFFCA28,
  );

  test('a new database has the built-ins in their order', () async {
    final all = await categories.getAll();
    expect(all.map((c) => c.id), [for (final c in builtInCategories) c.id]);
    expect(all.every((c) => c.builtIn), isTrue);
  });

  test('counts past, upcoming and repeating events per category', () async {
    await task('Run', DateTime(2026, 6, 1, 7));
    await task('Gym', DateTime(2026, 6, 9, 18));
    await task('Physio', DateTime(2026, 6, 12, 9));
    await task('Vitamins', DateTime(2026, 5, 1, 8), rule: RecurrenceRule.daily);
    await task('Standup', DateTime(2026, 6, 11, 9), category: 'meeting');

    final usage = await categories.usage(now);
    expect(
      usage['health'],
      const CategoryUsage(past: 2, upcoming: 1, repeating: 1),
    );
    expect(usage['health']!.describe(), '2 past · 1 upcoming · 1 repeating');
    expect(usage['meeting'], const CategoryUsage(upcoming: 1));
    expect(usage['family'], isNull);
  });

  test('editing an occurrence does not count the series twice', () async {
    await task('Vitamins', DateTime(2026, 6, 1, 8), rule: RecurrenceRule.daily);
    final occurrence = (await tasks.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).single;
    await service.update(
      occurrence,
      occurrence.copyWith(title: 'Vitamins + fish oil'),
      EditScope.thisOnly,
    );
    expect(
      (await categories.usage(now))['health'],
      const CategoryUsage(repeating: 1),
    );
  });

  test('add appends, or goes right after a category', () async {
    final a = await categories.add(errands);
    expect(a.id, startsWith('c-'));
    expect(a.builtIn, isFalse);
    expect((await categories.getAll()).last.id, a.id);

    final b = await categories.add(
      errands.copyWith(name: 'Errands (big)'),
      after: 'health',
    );
    final ids = (await categories.getAll()).map((c) => c.id).toList();
    expect(ids.indexOf(b.id), ids.indexOf('health') + 1);
  });

  test('removing a category moves its events, including overrides', () async {
    await task('Run', DateTime(2026, 6, 1, 7));
    await task('Vitamins', DateTime(2026, 6, 1, 8), rule: RecurrenceRule.daily);
    final occurrence = (await tasks.getRange(
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
    )).firstWhere((t) => t.title == 'Vitamins');
    await service.update(
      occurrence,
      occurrence.copyWith(title: 'Vitamins + fish oil'),
      EditScope.thisOnly,
    );

    await categories.remove('health', moveTo: 'personal');
    expect((await categories.getAll()).any((c) => c.id == 'health'), isFalse);
    final june = await tasks.getRange(DateTime(2026, 6), DateTime(2026, 7));
    expect(june, isNotEmpty);
    expect(june.every((t) => t.categoryId == 'personal'), isTrue);

    await categories.remove('personal');
    final after = await tasks.getRange(DateTime(2026, 6), DateTime(2026, 7));
    expect(after.every((t) => t.categoryId == TaskCategory.noneId), isTrue);
  });

  test('reorder saves the new order', () async {
    final ids = (await categories.getAll()).map((c) => c.id).toList();
    await categories.reorder(ids.reversed.toList());
    expect((await categories.getAll()).map((c) => c.id), ids.reversed);
  });

  test('adopt reuses categories by id or name and adds the rest', () async {
    final mine = await categories.add(errands);
    final mapping = await categories.adopt([
      builtInCategory('health')!,
      errands.copyWith(id: 'shared-0', name: 'ERRANDS'),
      errands.copyWith(id: 'shared-1', name: 'Dog'),
    ]);
    expect(mapping['health'], 'health');
    expect(mapping['shared-0'], mine.id);
    final dog = (await categories.getAll()).firstWhere((c) => c.name == 'Dog');
    expect(mapping['shared-1'], dog.id);
  });

  test('backups carry categories and restore them', () async {
    final custom = await categories.add(errands);
    await categories.update(
      builtInCategory('health')!.copyWith(name: 'Fitness'),
    );
    await task('Groceries', DateTime(2026, 6, 12, 17), category: custom.id);
    final json = await tasks.exportToJson();

    await categories.remove(custom.id);
    await categories.update(builtInCategory('health')!);
    await tasks.clear();
    await tasks.importFromJson(json);

    final all = await categories.getAll();
    expect(all.firstWhere((c) => c.id == custom.id).name, 'Errands');
    expect(all.firstWhere((c) => c.id == 'health').name, 'Fitness');
    final restored = await tasks.getRange(
      DateTime(2026, 6, 12),
      DateTime(2026, 6, 13),
    );
    expect(restored.single.categoryId, custom.id);
  });
}
