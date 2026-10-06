import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/data/datasources/database_location.dart';

void main() {
  test('moves the database and its WAL files together', () async {
    final dir = await Directory.systemTemp.createTemp('timeflow_move');
    addTearDown(() => dir.delete(recursive: true));
    final from = '${dir.path}/old.db';
    final to = '${dir.path}/new/timeflow.db';
    await Directory('${dir.path}/new').create();
    await File(from).writeAsString('db');
    await File('$from-wal').writeAsString('wal');

    await moveDatabaseFiles(from: from, to: to);

    expect(File(from).existsSync(), isFalse);
    expect(File('$from-wal').existsSync(), isFalse);
    expect(await File(to).readAsString(), 'db');
    expect(await File('$to-wal').readAsString(), 'wal');
    expect(File('$to-shm').existsSync(), isFalse);
  });
}
