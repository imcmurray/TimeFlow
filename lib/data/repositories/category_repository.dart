import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/datasources/task_row_mapper.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:uuid/uuid.dart';

/// How many events use a category.
///
/// One-off tasks count as [past] or [upcoming] by their start time. A
/// repeating task counts once, in [repeating], however many times it occurs.
@immutable
class CategoryUsage {
  final int past;
  final int upcoming;
  final int repeating;

  const CategoryUsage({this.past = 0, this.upcoming = 0, this.repeating = 0});

  static const unused = CategoryUsage();

  int get total => past + upcoming + repeating;
  bool get inUse => total > 0;

  /// e.g. "12 past · 3 upcoming · 1 repeating", or "Not used".
  String describe() {
    if (!inUse) return 'Not used';
    return [
      if (past > 0) '$past past',
      if (upcoming > 0) '$upcoming upcoming',
      if (repeating > 0) '$repeating repeating',
    ].join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryUsage &&
      other.past == past &&
      other.upcoming == upcoming &&
      other.repeating == repeating;

  @override
  int get hashCode => Object.hash(past, upcoming, repeating);
}

/// Storage for the categories people file tasks under.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();
  static String newId() => 'c-${_uuid.v4()}';

  $CategoriesTable get _categories => _db.categories;

  /// Every category in display order.
  Stream<List<TaskCategory>> watchAll() => _ordered().watch();

  Future<List<TaskCategory>> getAll() => _ordered().get();

  Selectable<TaskCategory> _ordered() =>
      (_db.select(_categories)..orderBy([
            (c) => OrderingTerm(expression: c.sortOrder),
            (c) => OrderingTerm(expression: c.name),
          ]))
          .map((r) => r.toCategory());

  /// Usage of every category that has events, keyed by id, as of [now].
  /// Overrides of repeating tasks and cancelled occurrences aren't counted.
  Stream<Map<String, CategoryUsage>> watchUsage(DateTime now) => _db
      .customSelect(
        'SELECT category, '
        'SUM(CASE WHEN recurrence IS NULL AND start_at < ?1 THEN 1 ELSE 0 END) '
        'AS past, '
        'SUM(CASE WHEN recurrence IS NULL AND start_at >= ?1 THEN 1 ELSE 0 END) '
        'AS upcoming, '
        'SUM(CASE WHEN recurrence IS NOT NULL THEN 1 ELSE 0 END) AS repeating '
        'FROM tasks WHERE series_id IS NULL AND is_cancelled = 0 '
        'GROUP BY category',
        variables: [Variable.withString(formatWallClock(now))],
        readsFrom: {_db.tasks},
      )
      .watch()
      .map(
        (rows) => {
          for (final r in rows)
            r.read<String>('category'): CategoryUsage(
              past: r.read<int>('past'),
              upcoming: r.read<int>('upcoming'),
              repeating: r.read<int>('repeating'),
            ),
        },
      );

  Future<Map<String, CategoryUsage>> usage(DateTime now) =>
      watchUsage(now).first;

  /// Adds [category] at the end of the list (or right after [after]) and
  /// returns it with its id and position.
  Future<TaskCategory> add(TaskCategory category, {String? after}) {
    return _db.transaction(() async {
      final all = await getAll();
      final index = after == null
          ? all.length
          : all.indexWhere((c) => c.id == after) + 1;
      final created = category.copyWith(
        id: category.id.isEmpty ? newId() : category.id,
        builtIn: false,
        sortOrder: index,
      );
      final ordered = [...all]..insert(index.clamp(0, all.length), created);
      await _writeOrder(ordered);
      return created;
    });
  }

  /// Saves changes to an existing category. Its events follow, since they
  /// refer to it by id.
  Future<void> update(TaskCategory category) => _db
      .into(_categories)
      .insertOnConflictUpdate(categoryToCompanion(category));

  /// Moves every event (including occurrences of repeating tasks) from
  /// category [from] to [to].
  Future<void> reassign(String from, String to) =>
      (_db.update(_db.tasks)..where((t) => t.category.equals(from))).write(
        TasksCompanion(category: Value(to)),
      );

  /// Removes a category, moving its events to [moveTo] (None by default).
  Future<void> remove(String id, {String moveTo = TaskCategory.noneId}) {
    return _db.transaction(() async {
      await reassign(id, moveTo);
      await (_db.delete(_categories)..where((c) => c.id.equals(id))).go();
    });
  }

  /// Puts categories in the given order.
  Future<void> reorder(List<String> ids) {
    return _db.transaction(() async {
      final byId = {for (final c in await getAll()) c.id: c};
      await _writeOrder([
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ]);
    });
  }

  Future<void> _writeOrder(List<TaskCategory> ordered) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_categories, [
      for (var i = 0; i < ordered.length; i++)
        categoryToCompanion(ordered[i].copyWith(sortOrder: i)),
    ]),
  );

  /// Makes [incoming] categories (from a shared schedule) available here and
  /// returns the local id to use for each incoming id. A category that
  /// exists here under the same id or name (ignoring case) is reused;
  /// anything else is added.
  Future<Map<String, String>> adopt(Iterable<TaskCategory> incoming) {
    return _db.transaction(() async {
      final mapping = <String, String>{};
      for (final c in incoming) {
        if (c.isNone) continue;
        final all = await getAll();
        final match =
            all.where((l) => l.id == c.id).firstOrNull ??
            all
                .where((l) => l.name.toLowerCase() == c.name.toLowerCase())
                .firstOrNull;
        mapping[c.id] = match?.id ?? (await add(c.copyWith(id: newId()))).id;
      }
      return mapping;
    });
  }

  /// Adds or replaces categories (from a backup).
  Future<void> upsertAll(Iterable<TaskCategory> categories) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(
      _categories,
      categories.map(categoryToCompanion).toList(),
    ),
  );
}
