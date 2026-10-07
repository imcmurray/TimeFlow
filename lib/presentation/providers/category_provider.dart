import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/repositories/category_repository.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/providers/clock_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

/// Every category in display order, kept up to date.
final categoriesProvider = StreamProvider<List<TaskCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Finds categories by id. Unknown ids (a removed category, or one from a
/// backup or link that isn't here) show as [TaskCategory.none].
@immutable
class CategoryLookup {
  final List<TaskCategory> all;
  final Map<String, TaskCategory> _byId;

  CategoryLookup(this.all) : _byId = {for (final c in all) c.id: c};

  TaskCategory operator [](String id) => _byId[id] ?? TaskCategory.none;

  bool contains(String id) => _byId.containsKey(id);

  @override
  bool operator ==(Object other) =>
      other is CategoryLookup && listEquals(other.all, all);

  @override
  int get hashCode => Object.hashAll(all);
}

/// The categories as a lookup. Until the database has answered it holds the
/// built-ins, so the first frame already shows the right colours.
///
/// Overridden for shared schedules, which carry their own categories.
final categoryLookupProvider = Provider<CategoryLookup>((ref) {
  final loaded = ref.watch(categoriesProvider).value;
  return CategoryLookup(loaded ?? builtInCategories);
});

/// How many events use each category, keyed by id. Recounted each minute,
/// so tasks move from upcoming to past as time passes.
final categoryUsageProvider =
    StreamProvider.autoDispose<Map<String, CategoryUsage>>((ref) {
      return ref
          .watch(categoryRepositoryProvider)
          .watchUsage(currentMinute(ref));
    });
