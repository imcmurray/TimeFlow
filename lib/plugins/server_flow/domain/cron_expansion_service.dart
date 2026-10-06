import 'package:cron_expression_parser/cron_expression_parser.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/plugins/server_flow/data/cron_job_model.dart';

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
    bool scheduleInUtc = true,
  }) {
    final effectiveFrom = from ?? job.startTime;
    final effectiveUntil = until ?? effectiveFrom.add(const Duration(days: 30));
    // With an explicit range, only occurrences inside it are returned.
    final ranged = from != null || until != null;
    List<TimelineEvent> single() {
      final event = _jobToEvent(job, job.startTime, 0);
      final end = event.endTime ?? event.startTime;
      if (ranged &&
          (end.isBefore(effectiveFrom) ||
              !event.startTime.isBefore(effectiveUntil))) {
        return const [];
      }
      return [event];
    }

    // Single event for null or 'once' schedule
    if (job.schedule == null || job.schedule!.toLowerCase() == 'once') {
      return single();
    }

    try {
      final cron = Cron.parse(job.schedule!);
      // The parser always works in UTC. For schedules in local time, run it
      // on the local wall-clock readings and read the results back as local.
      DateTime toParser(DateTime t) {
        if (scheduleInUtc) return t.toUtc();
        final l = t.toLocal();
        return DateTime.utc(l.year, l.month, l.day, l.hour, l.minute, l.second);
      }

      DateTime fromParser(DateTime t) => scheduleInUtc
          ? t.toLocal()
          : DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
      final occurrences = cron
          .toList(toParser(effectiveFrom), toParser(effectiveUntil))
          .map(fromParser)
          .toList();

      final capped = occurrences.length > maxOccurrences
          ? occurrences.sublist(0, maxOccurrences)
          : occurrences;

      final events = <TimelineEvent>[];
      for (var i = 0; i < capped.length; i++) {
        events.add(_jobToEvent(job, capped[i], i));
      }

      // Without a range, a job with no upcoming runs still shows once.
      if (events.isEmpty && !ranged) return single();

      return events;
    } catch (_) {
      // If cron expression is unparseable, treat as single event
      return single();
    }
  }

  static TimelineEvent _jobToEvent(CronJob job, DateTime startTime, int index) {
    final duration = job.endTime != null
        ? job.endTime!.difference(job.startTime)
        : Duration(seconds: job.duration);

    final endTime = duration > Duration.zero ? startTime.add(duration) : null;

    return TimelineEvent(
      id: '${job.id}@${startTime.millisecondsSinceEpoch}',
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
