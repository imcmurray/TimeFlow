import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/widgets/filter_modal.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';

/// In-memory repository for tests.
class _MockCronJobRepository implements CronJobRepository {
  final List<CronJob> _jobs;

  _MockCronJobRepository(this._jobs);

  @override
  Future<void> saveAll(List<CronJob> jobs) async {}
  @override
  Future<List<CronJob>> getAll() async => _jobs;
  @override
  Future<List<CronJob>> getForRange(DateTime start, DateTime end) async =>
      _jobs;
  @override
  Future<List<CronJob>> getByBatchId(String batchId) async => [];
  @override
  Future<void> deleteByBatchId(String batchId) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<List<String>> getDistinctHosts() async =>
      _jobs.map((j) => j.host).toSet().toList();
  @override
  Future<List<String>> getDistinctCategories() async => _jobs
      .where((j) => j.category != 'uncategorized')
      .map((j) => j.category)
      .toSet()
      .toList();
  @override
  Future<List<String>> getDistinctUsers() async =>
      _jobs.map((j) => j.user).toSet().toList();
}

void main() {
  final now = DateTime.now();
  final sampleJobs = [
    CronJob(
      id: '1',
      host: 'web-01',
      command: '/usr/bin/backup',
      startTime: DateTime(2024, 1, 15, 2, 0),
      user: 'root',
      category: 'backup',
      importBatchId: 'batch-1',
      importedAt: now,
    ),
    CronJob(
      id: '2',
      host: 'db-01',
      command: '/usr/bin/cleanup',
      startTime: DateTime(2024, 1, 15, 3, 0),
      user: 'postgres',
      category: 'maintenance',
      importBatchId: 'batch-1',
      importedAt: now,
    ),
    CronJob(
      id: '3',
      host: 'web-01',
      command: '/usr/bin/deploy',
      startTime: DateTime(2024, 1, 15, 4, 0),
      user: 'deploy',
      category: 'deployment',
      importBatchId: 'batch-1',
      importedAt: now,
    ),
  ];

  Widget buildTestApp({List<CronJob>? jobs}) {
    final repo = _MockCronJobRepository(jobs ?? sampleJobs);
    return ProviderScope(
      overrides: [
        cronJobRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFilterModal(context),
              child: const Text('Open Filter'),
            ),
          ),
        ),
      ),
    );
  }

  group('FilterModal', () {
    testWidgets('shows filter modal with sections', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Events'), findsOneWidget);
      expect(find.text('Hosts'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      // Time Range may be off-screen in the initial sheet size;
      // verify it exists even if offstage
      expect(
        find.text('Time Range', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('renders host chips from repository', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('web-01'), findsOneWidget);
      expect(find.text('db-01'), findsOneWidget);
    });

    testWidgets('renders category chips from repository', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('backup'), findsOneWidget);
      expect(find.text('maintenance'), findsOneWidget);
      expect(find.text('deployment'), findsOneWidget);
    });

    testWidgets('renders user chips from repository', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('root'), findsOneWidget);
      expect(find.text('postgres'), findsOneWidget);
      expect(find.text('deploy'), findsOneWidget);
    });

    testWidgets('tapping a host chip toggles selection', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap 'web-01' chip
      await tester.tap(find.text('web-01'));
      await tester.pumpAndSettle();

      // Reset button should appear when filter is active
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('reset button clears all filters', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select a host
      await tester.tap(find.text('web-01'));
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);

      // Tap reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Reset button should disappear when filter is inactive
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('close button dismisses modal', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Events'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Filter Events'), findsNothing);
    });

    testWidgets('user search filters user chips', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // All users visible as FilterChips initially
      List<FilterChip> getChips() =>
          tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      List<String> getChipLabels() =>
          getChips().map((c) => (c.label as Text).data!).toList();

      expect(getChipLabels(), containsAll(['root', 'postgres', 'deploy']));

      // Search for 'root' — typing into the TextField also shows 'root' as
      // EditableText, so verify via FilterChip widgets instead
      await tester.enterText(find.byType(TextField), 'root');
      await tester.pumpAndSettle();

      final labels = getChipLabels();
      // Host chips (web-01, db-01) + category chips + only 'root' user chip
      expect(labels, contains('root'));
      expect(labels, isNot(contains('postgres')));
      expect(labels, isNot(contains('deploy')));
    });

    testWidgets('shows "No data available" when no jobs exist', (tester) async {
      await tester.pumpWidget(buildTestApp(jobs: []));
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Each empty section should show "No data available"
      expect(find.text('No data available'), findsNWidgets(3));
    });

    testWidgets('range slider is present', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // RangeSlider may be below the initial visible area of the sheet;
      // verify it exists even if offstage
      expect(
        find.byType(RangeSlider, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('00:00 - 24:00', skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
