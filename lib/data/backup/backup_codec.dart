import 'dart:convert';

import 'package:timeflow/data/migrations/legacy_recurrence.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// Raised when a backup file can't be read.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Reads and writes TimeFlow backup files.
///
/// Version 2 (current) stores rows as they are kept in the database: series
/// with their rule, overrides, cancelled occurrences. Version 1 files (and
/// the pre-1.0 web storage) hold pre-generated recurring instances and are
/// converted on import.
class BackupCodec {
  const BackupCodec._();

  static const currentVersion = 2;

  static String encode(List<StoredTask> rows, {DateTime? exportedAt}) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'timeflow-backup',
      'version': currentVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'tasks': [for (final r in rows) _rowToJson(r)],
    });
  }

  /// Parses a backup file. Throws [BackupFormatException] if it isn't one.
  static List<StoredTask> decode(
    String source, {
    required String Function() newId,
  }) {
    final Object? data;
    try {
      data = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('This file is not a TimeFlow backup.');
    }
    if (data is! Map<String, dynamic> || data['tasks'] is! List) {
      throw const BackupFormatException('This file is not a TimeFlow backup.');
    }
    final version = data['version'];
    final tasks = (data['tasks'] as List).cast<Object?>();
    try {
      switch (version) {
        case 1:
          return decodeLegacyList(tasks, newId: newId);
        case 2:
          return [for (final t in tasks) _rowFromJson(_map(t))];
        default:
          throw BackupFormatException(
            'This backup was made by a newer version of TimeFlow '
            '(format $version). Update the app to restore it.',
          );
      }
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      throw BackupFormatException('The backup file is damaged ($e).');
    }
  }

  /// Converts a list of pre-1.0 task JSON objects (version 1 backups and the
  /// pre-1.0 web storage) to rows.
  static List<StoredTask> decodeLegacyList(
    List<Object?> tasks, {
    required String Function() newId,
  }) {
    final legacy = [
      for (final t in tasks)
        () {
          final j = _map(t);
          return LegacyTask(
            Task(
              id: j['id'] as String,
              title: j['title'] as String,
              description: j['description'] as String?,
              startTime: parseWallClock(j['startTime'] as String),
              endTime: parseWallClock(j['endTime'] as String),
              isImportant: j['isImportant'] as bool? ?? false,
              isCompleted: j['isCompleted'] as bool? ?? false,
              reminderMinutes: j['reminderMinutes'] as int?,
              notes: j['notes'] as String?,
              attachmentPath: j['attachmentPath'] as String?,
              color: j['color'] as String?,
              category: TaskCategoryExtension.fromString(
                j['category'] as String?,
              ),
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ),
            pattern: j['recurringPattern'] as String?,
            templateId: j['recurringTemplateId'] as String?,
          );
        }(),
    ];
    return collapseLegacyRecurrence(legacy, newId: newId);
  }

  static Map<String, dynamic> _map(Object? o) {
    if (o is! Map<String, dynamic>) {
      throw const BackupFormatException('The backup file is damaged.');
    }
    return o;
  }

  static Map<String, Object?> _rowToJson(StoredTask r) {
    final t = r.task;
    return {
      'id': t.id,
      'title': t.title,
      if (t.description != null) 'description': t.description,
      if (t.notes != null) 'notes': t.notes,
      'start': formatWallClock(t.startTime),
      'end': formatWallClock(t.endTime),
      'isImportant': t.isImportant,
      'isCompleted': t.isCompleted,
      if (t.reminderMinutes != null) 'reminderMinutes': t.reminderMinutes,
      if (t.attachmentPath != null) 'attachmentPath': t.attachmentPath,
      if (t.color != null) 'color': t.color,
      'category': t.category.value,
      if (!t.isOccurrence && t.recurrence != null)
        'recurrence': t.recurrence!.toRRule(),
      if (t.seriesId != null) 'seriesId': t.seriesId,
      if (t.occurrenceDate != null) 'occurrenceDate': t.occurrenceDate!.toIso(),
      if (r.isCancelled) 'isCancelled': true,
      'createdAt': t.createdAt.toUtc().toIso8601String(),
      'updatedAt': t.updatedAt.toUtc().toIso8601String(),
    };
  }

  static StoredTask _rowFromJson(Map<String, dynamic> j) {
    final recurrence = j['recurrence'] as String?;
    final occurrenceDate = j['occurrenceDate'] as String?;
    return StoredTask(
      Task(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        notes: j['notes'] as String?,
        startTime: parseWallClock(j['start'] as String),
        endTime: parseWallClock(j['end'] as String),
        isImportant: j['isImportant'] as bool? ?? false,
        isCompleted: j['isCompleted'] as bool? ?? false,
        reminderMinutes: j['reminderMinutes'] as int?,
        attachmentPath: j['attachmentPath'] as String?,
        color: j['color'] as String?,
        category: TaskCategoryExtension.fromString(j['category'] as String?),
        recurrence: recurrence != null
            ? RecurrenceRule.parse(recurrence)
            : null,
        seriesId: j['seriesId'] as String?,
        occurrenceDate: occurrenceDate != null
            ? LocalDate.parseIso(occurrenceDate)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(j['updatedAt'] as String).toLocal(),
      ),
      isCancelled: j['isCancelled'] as bool? ?? false,
    );
  }
}
