import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/backup/backup_codec.dart';
import 'package:timeflow/data/repositories/task_repository.dart';

/// Before 1.0 the web build kept all tasks as one JSON list in browser
/// storage. Moves them into the database once, then removes the old entry.
Future<void> migrateLegacyWebStorage(TaskRepository repo) async {
  if (!kIsWeb) return;
  const key = 'timeflow_tasks';
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(key);
  if (json == null) return;
  try {
    final list = (jsonDecode(json) as List).cast<Object?>();
    final rows =
        BackupCodec.decodeLegacyList(list, newId: TaskRepository.newId);
    await repo.importRows(rows);
    await prefs.remove(key);
  } catch (e, stack) {
    // Leave the old data in place so nothing is lost; the app still works.
    debugPrint('Could not migrate pre-1.0 web tasks: $e\n$stack');
  }
}
