import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timeflow/data/migrations/schema_v3_migration.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

part 'database.g.dart';

/// Stores [DateTime]s as offset-less wall-clock text (`2026-10-04T09:00:00`).
///
/// Task times are wall-clock times: a task at 9:00 stays at 9:00 across DST
/// changes. Fixed-width text also sorts chronologically, so range queries
/// work as plain string comparisons.
class WallClockConverter extends TypeConverter<DateTime, String> {
  const WallClockConverter();

  @override
  DateTime fromSql(String fromDb) => parseWallClock(fromDb);

  @override
  String toSql(DateTime value) => formatWallClock(value);
}

/// Tasks: standalone tasks, recurring series definitions, and stored
/// occurrences of a series (overrides).
///
/// - Standalone: `recurrence` and `seriesId` are null.
/// - Series: `recurrence` holds the RRULE; the row's start/end give the first
///   occurrence and the time of day.
/// - Override: `seriesId` + `occurrenceDate` say which generated occurrence
///   this row replaces. `isCancelled` marks a deleted occurrence.
@DataClassName('TaskRow')
@TableIndex(name: 'tasks_start_at', columns: {#startAt})
@TableIndex(
  name: 'tasks_series_occurrence',
  columns: {#seriesId, #occurrenceDate},
  unique: true,
)
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get startAt => text().map(const WallClockConverter())();
  TextColumn get endAt => text().map(const WallClockConverter())();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get reminderMinutes => integer().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('none'))();
  TextColumn get recurrence => text().nullable()();
  TextColumn get seriesId => text().nullable()();

  /// `yyyy-MM-dd` date the series scheduled this occurrence on.
  TextColumn get occurrenceDate => text().nullable()();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) await migrateToSchemaV3(this, m, from);
    },
  );

  static QueryExecutor _open() => driftDatabase(
    name: 'timeflow',
    native: DriftNativeOptions(
      // Keep the file name the app has always used.
      databasePath: () async => p.join(
        (await getApplicationDocumentsDirectory()).path,
        'timeflow.db',
      ),
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
