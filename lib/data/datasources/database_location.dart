import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _fileName = 'timeflow.db';

/// Where the database lives on this device.
///
/// Phones and macOS keep it in the app's documents folder, which is private
/// to the app there. On Linux and Windows that folder is the user's own
/// Documents, so the database lives in the app's support folder instead
/// (e.g. ~/.local/share/com.rinserepeatlabs.timeflow), and a database left
/// in Documents by earlier versions is moved there once.
Future<String> databasePath() async {
  final documents = p.join(
    (await getApplicationDocumentsDirectory()).path,
    _fileName,
  );
  if (!(Platform.isLinux || Platform.isWindows)) return documents;

  final supportDir = await getApplicationSupportDirectory();
  await supportDir.create(recursive: true);
  final target = p.join(supportDir.path, _fileName);
  if (!File(target).existsSync() && File(documents).existsSync()) {
    try {
      await moveDatabaseFiles(from: documents, to: target);
    } catch (e) {
      debugPrint('Could not move the database out of Documents: $e');
      return documents; // keep using the old copy rather than start empty
    }
  }
  return target;
}

/// Moves a SQLite database and its -wal/-shm companions.
@visibleForTesting
Future<void> moveDatabaseFiles({
  required String from,
  required String to,
}) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final source = File('$from$suffix');
    if (!source.existsSync()) continue;
    try {
      await source.rename('$to$suffix');
    } on FileSystemException {
      // Different file systems: copy, then remove the original.
      await source.copy('$to$suffix');
      await source.delete();
    }
  }
}
