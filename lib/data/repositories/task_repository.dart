import 'package:drift/drift.dart';
import 'package:timeflow/data/backup/backup_codec.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/datasources/task_row_mapper.dart';
import 'package:timeflow/data/migrations/legacy_recurrence.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/recurrence/series_expander.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:uuid/uuid.dart';

/// Storage for tasks, series and occurrence overrides.
///
/// Reads return what the timeline shows: standalone tasks plus the
/// occurrences of every series (stored overrides and generated ones), never
/// series definitions or cancelled occurrences. The write methods are
/// primitives; [TaskService] builds the user-level operations on top.
class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  /// Overrides more than this many days before a range can't affect it
  /// (no task is allowed to be that long).
  static const _maxSpanDays = 31;

  $TasksTable get _tasks => _db.tasks;

  // ---------------------------------------------------------------- reading

  /// Tasks and occurrences overlapping [from]..[to) (end exclusive), sorted
  /// by start time.
  Future<List<Task>> getRange(DateTime from, DateTime to) async {
    final fromS = formatWallClock(from);
    final toS = formatWallClock(to);

    final seriesRows = await (_db.select(
      _tasks,
    )..where((t) => t.recurrence.isNotNull())).get();
    final rules = {
      for (final s in seriesRows) s.id: RecurrenceRule.parse(s.recurrence!),
    };

    final concrete =
        await (_db.select(_tasks)..where(
              (t) =>
                  t.recurrence.isNull() &
                  t.isCancelled.equals(false) &
                  t.startAt.isSmallerThanValue(toS) &
                  t.endAt.isBiggerThanValue(fromS),
            ))
            .get();

    final result = [
      for (final row in concrete)
        row.toTask(
          seriesRule: row.seriesId != null ? rules[row.seriesId] : null,
        ),
    ];

    if (seriesRows.isNotEmpty) {
      final windowStart = LocalDate.of(from).addDays(-_maxSpanDays).toIso();
      final windowEnd = LocalDate.of(to).toIso();
      final overridden =
          await (_db.selectOnly(_tasks)
                ..addColumns([_tasks.seriesId, _tasks.occurrenceDate])
                ..where(
                  _tasks.seriesId.isNotNull() &
                      _tasks.occurrenceDate.isBiggerOrEqualValue(windowStart) &
                      _tasks.occurrenceDate.isSmallerOrEqualValue(windowEnd),
                ))
              .get();
      final skip = <String, Set<LocalDate>>{};
      for (final r in overridden) {
        skip
            .putIfAbsent(r.read(_tasks.seriesId)!, () => {})
            .add(LocalDate.parseIso(r.read(_tasks.occurrenceDate)!));
      }
      for (final s in seriesRows) {
        if (s.startAt.isAfter(to)) continue;
        result.addAll(
          SeriesExpander.occurrencesOf(
            s.toTask(),
            from: from,
            to: to,
            skip: skip[s.id] ?? const {},
          ),
        );
      }
    }

    result.sort((a, b) {
      final c = a.startTime.compareTo(b.startTime);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return result;
  }

  /// [getRange], re-run whenever tasks change.
  Stream<List<Task>> watchRange(DateTime from, DateTime to) => _db
      .customSelect('SELECT 1', readsFrom: {_tasks})
      .watch()
      .asyncMap((_) => getRange(from, to));

  /// Emits whenever any task changes.
  Stream<void> get changes =>
      _db.tableUpdates(TableUpdateQuery.onTable(_tasks));

  /// A stored task, series or override by id.
  Future<Task?> getStored(String id) async {
    final row = await (_db.select(
      _tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final rule = row.seriesId == null
        ? null
        : (await getSeries(row.seriesId!))?.recurrence;
    return row.toTask(seriesRule: rule);
  }

  Future<Task?> getSeries(String seriesId) async {
    final row =
        await (_db.select(_tasks)
              ..where((t) => t.id.equals(seriesId) & t.recurrence.isNotNull()))
            .getSingleOrNull();
    return row?.toTask();
  }

  /// Stored overrides of a series (including cancelled ones), optionally only
  /// those on or after [from].
  Future<List<StoredTask>> overridesOf(
    String seriesId, {
    LocalDate? from,
  }) async {
    final query = _db.select(_tasks)
      ..where((t) {
        var e = t.seriesId.equals(seriesId);
        if (from != null) {
          e = e & t.occurrenceDate.isBiggerOrEqualValue(from.toIso());
        }
        return e;
      });
    final rule = (await getSeries(seriesId))?.recurrence;
    return [
      for (final row in await query.get())
        StoredTask(row.toTask(seriesRule: rule), isCancelled: row.isCancelled),
    ];
  }

  /// Number of things the user created: standalone tasks and series.
  Future<int> count() async {
    final c = _tasks.id.count();
    final row =
        await (_db.selectOnly(_tasks)
              ..addColumns([c])
              ..where(_tasks.seriesId.isNull()))
            .getSingle();
    return row.read(c) ?? 0;
  }

  // ---------------------------------------------------------------- writing

  /// Inserts or replaces a standalone task, series, or override. An override
  /// replaces any other override for the same series and date.
  Future<void> upsert(Task task, {bool isCancelled = false}) {
    return _db.transaction(() async {
      if (task.seriesId != null && task.occurrenceDate != null) {
        await (_db.delete(_tasks)..where(
              (t) =>
                  t.seriesId.equals(task.seriesId!) &
                  t.occurrenceDate.equals(task.occurrenceDate!.toIso()) &
                  t.id.equals(task.id).not(),
            ))
            .go();
      }
      await _db
          .into(_tasks)
          .insertOnConflictUpdate(
            taskToCompanion(task, isCancelled: isCancelled),
          );
    });
  }

  Future<void> upsertAll(Iterable<StoredTask> rows) {
    return _db.batch(
      (b) => b.insertAllOnConflictUpdate(
        _tasks,
        rows.map(storedToCompanion).toList(),
      ),
    );
  }

  Future<void> delete(String id) =>
      (_db.delete(_tasks)..where((t) => t.id.equals(id))).go();

  /// Deletes a series and all its overrides.
  Future<void> deleteSeries(String seriesId) => (_db.delete(
    _tasks,
  )..where((t) => t.id.equals(seriesId) | t.seriesId.equals(seriesId))).go();

  /// Deletes a series' overrides dated on or after [from].
  Future<void> deleteOverridesFrom(String seriesId, LocalDate from) =>
      (_db.delete(_tasks)..where(
            (t) =>
                t.seriesId.equals(seriesId) &
                t.occurrenceDate.isBiggerOrEqualValue(from.toIso()),
          ))
          .go();

  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_tasks).go();
    await _db.delete(_db.attachments).go();
  });

  // ------------------------------------------------------------ attachments

  static const attachmentScheme = 'attachment:';

  /// Stores a photo and returns the reference to put in
  /// [Task.attachmentPath].
  Future<String> saveAttachment(Uint8List bytes, String mimeType) async {
    final id = newId();
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: id,
            mimeType: mimeType,
            bytes: bytes,
            createdAt: DateTime.now(),
          ),
        );
    return '$attachmentScheme$id';
  }

  /// The photo a [Task.attachmentPath] reference points to.
  Future<({Uint8List bytes, String mimeType})?> attachment(
    String reference,
  ) async {
    if (!reference.startsWith(attachmentScheme)) return null;
    final id = reference.substring(attachmentScheme.length);
    final row = await (_db.select(
      _db.attachments,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : (bytes: row.bytes, mimeType: row.mimeType);
  }

  /// Deletes photos no task refers to any more.
  Future<int> pruneAttachments() {
    return _db.customUpdate(
      'DELETE FROM attachments WHERE '
      "'$attachmentScheme' || id NOT IN "
      '(SELECT attachment_path FROM tasks WHERE attachment_path IS NOT NULL)',
      updates: {_db.attachments},
      updateKind: UpdateKind.delete,
    );
  }

  // ----------------------------------------------------------------- backup

  Future<String> exportToJson() async {
    final rows = await _db.select(_tasks).get();
    final attachments = await _db.select(_db.attachments).get();
    final pluginData = await _db.select(_db.pluginData).get();
    final categories = await _db.select(_db.categories).get();
    return BackupCodec.encode(
      [
        for (final r in rows)
          StoredTask(r.toTask(), isCancelled: r.isCancelled),
      ],
      attachments: [
        for (final a in attachments)
          BackupAttachment(a.id, a.mimeType, a.bytes),
      ],
      pluginData: [
        for (final v in pluginData)
          BackupPluginValue(v.pluginId, v.key, v.value),
      ],
      categories: [for (final c in categories) c.toCategory()],
    );
  }

  /// Restores a backup, merging it with existing tasks (same ids are
  /// replaced). Returns the number of tasks and series restored.
  /// Throws [BackupFormatException] for files that aren't backups.
  Future<int> importFromJson(String json) async {
    final backup = BackupCodec.decodeBackup(json, newId: newId);
    await _db.transaction(() async {
      for (final a in backup.attachments) {
        await _db
            .into(_db.attachments)
            .insertOnConflictUpdate(
              AttachmentsCompanion.insert(
                id: a.id,
                mimeType: a.mimeType,
                bytes: a.bytes,
                createdAt: DateTime.now(),
              ),
            );
      }
      for (final v in backup.pluginData) {
        await _db
            .into(_db.pluginData)
            .insertOnConflictUpdate(
              PluginDataCompanion.insert(
                pluginId: v.pluginId,
                key: v.key,
                value: v.value,
                updatedAt: DateTime.now(),
              ),
            );
      }
      // Categories with the same id are replaced; others are kept.
      await _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.categories, [
          for (final c in backup.categories) categoryToCompanion(c),
        ]),
      );
      await importRows(backup.rows);
    });
    return backup.rows.where((r) => r.task.seriesId == null).length;
  }

  Future<void> importRows(List<StoredTask> rows) {
    return _db.transaction(() async {
      for (final r in rows) {
        await upsert(r.task, isCancelled: r.isCancelled);
      }
    });
  }
}
