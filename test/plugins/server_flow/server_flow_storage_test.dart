import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/plugins/server_flow/data/csv_parser.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

import '../../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late AppDatabase db;
  late ProviderContainer container;

  late SharedPreferences prefs;

  setUp(() async {
    prefs = await SharedPreferences.getInstance();
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'imported jobs are stored and a recurring job shows every day',
    () async {
      // First run long ago; runs daily at 02:30.
      final result = CsvParser.parse(
        'host,command,start_time,user,schedule\n'
        'web-01,/usr/bin/backup.sh,2025-01-01T02:30:00,root,30 2 * * *\n'
        'db-01,/usr/bin/vacuum,2025-01-01T03:00:00,postgres,once\n',
      );
      await container.read(cronJobRepositoryProvider).saveAll(result.jobs);
      expect(
        (await container.read(cronJobRepositoryProvider).getAll()).length,
        2,
      );

      final today = LocalDate(2026, 10, 5);
      final sub = container.listen(
        serverFlowEventsForRangeProvider(DayRange.single(today)),
        (_, _) {},
      );
      addTearDown(sub.close);
      final events = await container.read(
        serverFlowEventsForRangeProvider(DayRange.single(today)).future,
      );
      final titles = events.map((e) => e.title).toList();
      expect(
        titles,
        contains('/usr/bin/backup.sh'),
        reason: 'recurring jobs keep appearing after their first run',
      );
      expect(
        titles,
        isNot(contains('/usr/bin/vacuum')),
        reason: 'a one-off job only appears on its own day',
      );
      final backup = events.firstWhere((e) => e.title == '/usr/bin/backup.sh');
      expect(
        backup.startTime,
        DateTime(2026, 10, 5, 2, 30),
        reason: 'schedules default to this device time zone',
      );

      // Imported jobs travel with backups.
      final tasks = container.read(taskRepositoryProvider);
      final backupJson = await tasks.exportToJson();
      await container.read(cronJobRepositoryProvider).clear();
      expect(await container.read(cronJobRepositoryProvider).getAll(), isEmpty);
      await tasks.importFromJson(backupJson);
      expect(
        (await container.read(cronJobRepositoryProvider).getAll()).length,
        2,
      );

      await container.read(cronJobRepositoryProvider).clear();
      expect(await container.read(cronJobRepositoryProvider).getAll(), isEmpty);
    },
  );
}
