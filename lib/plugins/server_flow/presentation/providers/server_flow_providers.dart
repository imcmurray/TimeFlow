import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/plugin_storage.dart';
import 'package:timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:timeflow/plugins/server_flow/data/cron_job_repository.dart';
import 'package:timeflow/plugins/server_flow/data/csv_parser.dart';
import 'package:timeflow/plugins/server_flow/domain/cron_expansion_service.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/filter_provider.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/grouping_provider.dart';
import 'package:timeflow/plugins/server_flow/presentation/utils/color_palette.dart';
import 'package:timeflow/plugins/server_flow/domain/display_mode_transform.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// Repository for cron jobs, in ServerFlow's plugin storage.
final cronJobRepositoryProvider = Provider<CronJobRepository>((ref) {
  return PluginStorageCronJobRepository(
    PluginStorage(ref.watch(appDatabaseProvider), 'server_flow'),
  );
});

/// Whether cron schedules are in UTC (true) or this device's time zone.
class CronUtcNotifier extends Notifier<bool> {
  static const _key = 'server_flow_cron_utc';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool utc) {
    state = utc;
    ref.read(sharedPreferencesProvider).setBool(_key, utc);
  }
}

final cronUtcProvider = NotifierProvider<CronUtcNotifier, bool>(
  CronUtcNotifier.new,
);

/// All imported cron jobs, kept up to date.
final allCronJobsProvider = StreamProvider<List<CronJob>>(
  (ref) => ref.watch(cronJobRepositoryProvider).watchAll(),
);

/// Expanded timeline events for a date range, colored by grouping mode and
/// filtered by the active ServerFlow filter.
final serverFlowEventsForRangeProvider = FutureProvider.autoDispose
    .family<List<TimelineEvent>, DayRange>((ref, range) async {
      final grouping = ref.watch(groupingProvider);
      final filter = ref.watch(serverFlowFilterProvider);
      // Every job, not just those whose first run is in range: a recurring job
      // imported last month still runs today.
      final jobs = await ref.watch(allCronJobsProvider.future);
      final scheduleInUtc = ref.watch(cronUtcProvider);

      final events = <TimelineEvent>[];
      for (final job in jobs) {
        events.addAll(
          CronExpansionService.expand(
            job,
            from: range.start,
            until: range.end,
            maxOccurrences: 5000,
            scheduleInUtc: scheduleInUtc,
          ),
        );
      }

      // Assign colors based on grouping mode
      var colored = events.map((event) {
        final label = switch (grouping.mode) {
          GroupingMode.host => event.groupKey ?? 'unknown',
          GroupingMode.category => event.categoryLabel ?? 'uncategorized',
          GroupingMode.user => event.metadata['user']?.toString() ?? 'unknown',
        };
        final color =
            grouping.colorOverrides[label] ?? ColorPalette.colorForLabel(label);
        return event.copyWith(color: color);
      }).toList();

      // Apply filters
      if (filter.isActive) {
        colored = colored.where((event) {
          // Host filter
          if (filter.selectedHosts.isNotEmpty) {
            final host = event.groupKey ?? 'unknown';
            if (!filter.selectedHosts.contains(host)) return false;
          }
          // Category filter
          if (filter.selectedCategories.isNotEmpty) {
            final category = event.categoryLabel ?? 'uncategorized';
            if (!filter.selectedCategories.contains(category)) return false;
          }
          // User filter
          if (filter.selectedUsers.isNotEmpty) {
            final user = event.metadata['user']?.toString() ?? 'unknown';
            if (!filter.selectedUsers.contains(user)) return false;
          }
          // Time range filter
          if (filter.timeRangeStartHour != null ||
              filter.timeRangeEndHour != null) {
            final eventHour =
                event.startTime.hour + event.startTime.minute / 60.0;
            final startHour = filter.timeRangeStartHour ?? 0.0;
            final endHour = filter.timeRangeEndHour ?? 24.0;
            if (eventHour < startHour || eventHour > endHour) return false;
          }
          return true;
        }).toList();
      }

      // Apply display mode transform (stage 4)
      final displayState = ref.watch(displayModeProvider);
      final transformed = DisplayModeTransform.apply(
        events: colored,
        mode: displayState.mode,
        clusterWindow: displayState.clusterWindow,
      );

      return transformed;
    });

/// State for CSV import process.
enum CsvImportStatus { idle, parsing, saving, done, error }

class CsvImportState {
  final CsvImportStatus status;
  final CsvParseResult? result;
  final String? errorMessage;

  const CsvImportState({
    this.status = CsvImportStatus.idle,
    this.result,
    this.errorMessage,
  });

  bool get isActive =>
      status == CsvImportStatus.parsing || status == CsvImportStatus.saving;
}

class CsvImportNotifier extends Notifier<CsvImportState> {
  @override
  CsvImportState build() => const CsvImportState();

  Future<void> importCsv(String csvText) async {
    state = const CsvImportState(status: CsvImportStatus.parsing);

    try {
      final result = CsvParser.parse(csvText);
      state = CsvImportState(status: CsvImportStatus.saving, result: result);

      await ref.read(cronJobRepositoryProvider).saveAll(result.jobs);
      state = CsvImportState(status: CsvImportStatus.done, result: result);
    } catch (e) {
      state = CsvImportState(
        status: CsvImportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const CsvImportState();
  }
}

final csvImportProvider = NotifierProvider<CsvImportNotifier, CsvImportState>(
  CsvImportNotifier.new,
);
