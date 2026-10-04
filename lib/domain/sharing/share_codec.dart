import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// A schedule packed into a share link.
@immutable
class SharedSchedule {
  /// Optional heading, e.g. "Biscuit's routine".
  final String? title;
  final List<Task> tasks;

  const SharedSchedule({this.title, required this.tasks});
}

/// Packs schedules into the `#` part of a TimeFlow web link.
///
/// The fragment never reaches a server, so a shared schedule travels only
/// inside the link. Tasks are stored compactly (wall-clock start, length,
/// title, optional details) and deflate-compressed; a day of a dozen tasks
/// makes a link of well under a kilobyte.
class ShareCodec {
  const ShareCodec._();

  static const _version = 1;
  static const fragmentPrefix = '/s/';

  /// The link that opens [schedule] in the TimeFlow web app at [appUrl].
  static Uri link(Uri appUrl, SharedSchedule schedule) =>
      appUrl.replace(fragment: '$fragmentPrefix${encode(schedule)}');

  /// The schedule in [fragment] (a URL's `#` part), or null if it isn't a
  /// share link or can't be read.
  static SharedSchedule? fromFragment(String fragment) {
    if (!fragment.startsWith(fragmentPrefix)) return null;
    try {
      return decode(fragment.substring(fragmentPrefix.length));
    } catch (_) {
      return null;
    }
  }

  static String encode(SharedSchedule schedule) {
    final json = jsonEncode({
      'v': _version,
      if (schedule.title != null) 'n': schedule.title,
      't': [
        for (final t in schedule.tasks)
          [
            t.title,
            _compactTime(t.startTime),
            t.durationMinutes,
            (t.isImportant ? 1 : 0) | (t.isCompleted ? 2 : 0),
            t.category.index,
            t.description ?? '',
            t.notes ?? '',
          ],
      ],
    });
    final deflated = const ZLibEncoder().encode(utf8.encode(json), level: 9);
    return base64Url.encode(deflated).replaceAll('=', '');
  }

  static SharedSchedule decode(String data) {
    final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
    final json = utf8.decode(
      const ZLibDecoder().decodeBytes(base64Url.decode(padded)),
    );
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['v'] != _version) {
      throw const FormatException('Unsupported share link version');
    }
    final created = DateTime.now();
    final tasks = <Task>[];
    final list = (map['t'] as List).cast<List<dynamic>>();
    for (var i = 0; i < list.length; i++) {
      final row = list[i];
      final start = _parseCompactTime(row[1] as String);
      final flags = row[3] as int;
      final categoryIndex = row[4] as int;
      final description = row[5] as String;
      final notes = row[6] as String;
      tasks.add(
        Task(
          id: 'shared-$i',
          title: row[0] as String,
          startTime: start,
          endTime: addWallMinutes(start, row[2] as int),
          isImportant: flags & 1 != 0,
          isCompleted: flags & 2 != 0,
          category:
              categoryIndex >= 0 && categoryIndex < TaskCategory.values.length
              ? TaskCategory.values[categoryIndex]
              : TaskCategory.none,
          description: description.isEmpty ? null : description,
          notes: notes.isEmpty ? null : notes,
          createdAt: created,
          updatedAt: created,
        ),
      );
    }
    return SharedSchedule(title: map['n'] as String?, tasks: tasks);
  }

  /// `yyyyMMddHHmm`.
  static String _compactTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}${two(t.hour)}${two(t.minute)}';
  }

  static DateTime _parseCompactTime(String s) => DateTime(
    int.parse(s.substring(0, 4)),
    int.parse(s.substring(4, 6)),
    int.parse(s.substring(6, 8)),
    int.parse(s.substring(8, 10)),
    int.parse(s.substring(10, 12)),
  );
}
