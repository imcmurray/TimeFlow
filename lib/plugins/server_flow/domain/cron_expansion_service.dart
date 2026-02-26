import 'package:cron_expression_parser/cron_expression_parser.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';

/// Expands a [CronJob] with a schedule into multiple [TimelineEvent]s.
class CronExpansionService {
  /// Expands [job] into timeline events.
  ///
  /// - If [job.schedule] is null or `'once'`, returns a single event.
  /// - Otherwise parses as a cron expression and generates up to
  ///   [maxOccurrences] events between [from] and [until].
  static List<TimelineEvent> expand(
    CronJob job, {
    int maxOccurrences = 50,
    DateTime? from,
    DateTime? until,
  }) {
    final effectiveFrom = from ?? job.startTime;
    final effectiveUntil =
        until ?? effectiveFrom.add(const Duration(days: 30));

    // Single event for null or 'once' schedule
    if (job.schedule == null || job.schedule!.toLowerCase() == 'once') {
      return [_jobToEvent(job, job.startTime, 0)];
    }

    try {
      final cron = Cron.parse(job.schedule!);
      final occurrences = cron.toList(effectiveFrom.toUtc(), effectiveUntil.toUtc());

      final capped = occurrences.length > maxOccurrences
          ? occurrences.sublist(0, maxOccurrences)
          : occurrences;

      final events = <TimelineEvent>[];
      for (var i = 0; i < capped.length; i++) {
        events.add(_jobToEvent(job, capped[i].toLocal(), i));
      }

      // If no occurrences found within range, return one at the original startTime
      if (events.isEmpty) {
        return [_jobToEvent(job, job.startTime, 0)];
      }

      return events;
    } catch (_) {
      // If cron expression is unparseable, treat as single event
      return [_jobToEvent(job, job.startTime, 0)];
    }
  }

  static TimelineEvent _jobToEvent(CronJob job, DateTime startTime, int index) {
    final duration = job.endTime != null
        ? job.endTime!.difference(job.startTime)
        : Duration(seconds: job.duration);

    final endTime = duration > Duration.zero
        ? startTime.add(duration)
        : null;

    return TimelineEvent(
      id: '${job.id}_$index',
      pluginId: 'server_flow',
      title: job.command,
      subtitle: job.host,
      startTime: startTime,
      endTime: endTime,
      groupKey: job.host,
      categoryLabel: job.category,
      metadata: {
        'host': job.host,
        'command': job.command,
        'user': job.user,
        'schedule': job.schedule,
        'os': job.os,
        'category': job.category,
        'importBatchId': job.importBatchId,
      },
    );
  }
}
