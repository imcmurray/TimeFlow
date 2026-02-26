import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';
import 'package:cron_timeflow/plugins/server_flow/data/csv_parser.dart';
import 'package:cron_timeflow/plugins/server_flow/domain/cron_expansion_service.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/filter_provider.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/grouping_provider.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/utils/color_palette.dart';
import 'package:cron_timeflow/presentation/providers/task_provider.dart';

/// Repository for cron jobs.
final cronJobRepositoryProvider = Provider<CronJobRepository>((ref) {
  return CronJobRepository();
});

/// Notifier to trigger rebuilds when cron jobs change.
class CronJobNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyJobsChanged() {
    state++;
  }
}

final cronJobNotifierProvider = NotifierProvider<CronJobNotifier, int>(
  CronJobNotifier.new,
);

/// All imported cron jobs.
final allCronJobsProvider = FutureProvider<List<CronJob>>((ref) async {
  ref.watch(cronJobNotifierProvider);
  return ref.read(cronJobRepositoryProvider).getAll();
});

/// Expanded timeline events for a date range, colored by grouping mode and
/// filtered by the active ServerFlow filter.
final serverFlowEventsForRangeProvider =
    FutureProvider.family<List<TimelineEvent>, DateRange>((ref, range) async {
  ref.watch(cronJobNotifierProvider);
  final grouping = ref.watch(groupingProvider);
  final filter = ref.watch(serverFlowFilterProvider);
  final repo = ref.read(cronJobRepositoryProvider);
  final jobs = await repo.getForRange(range.start, range.end);

  final events = <TimelineEvent>[];
  for (final job in jobs) {
    events.addAll(CronExpansionService.expand(
      job,
      from: range.start,
      until: range.end,
    ));
  }

  // Assign colors based on grouping mode
  var colored = events.map((event) {
    final label = switch (grouping.mode) {
      GroupingMode.host => event.groupKey ?? 'unknown',
      GroupingMode.category => event.categoryLabel ?? 'uncategorized',
      GroupingMode.user => event.metadata['user']?.toString() ?? 'unknown',
    };
    final color = grouping.colorOverrides[label] ??
        ColorPalette.colorForLabel(label);
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

  return colored;
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

      final repo = ref.read(cronJobRepositoryProvider);
      await repo.saveAll(result.jobs);

      ref.read(cronJobNotifierProvider.notifier).notifyJobsChanged();
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

final csvImportProvider =
    NotifierProvider<CsvImportNotifier, CsvImportState>(CsvImportNotifier.new);
