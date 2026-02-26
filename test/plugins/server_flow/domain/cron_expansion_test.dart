import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/domain/cron_expansion_service.dart';

void main() {
  final baseJob = CronJob(
    id: 'job-1',
    host: 'web-prod-01',
    command: '/usr/bin/backup.sh',
    startTime: DateTime.utc(2025, 1, 15, 0, 0),
    user: 'root',
    category: 'backup',
    duration: 3600,
    importBatchId: 'batch-1',
    importedAt: DateTime.utc(2025, 1, 15, 0, 0),
  );

  group('CronExpansionService', () {
    test('null schedule returns single event', () {
      final job = baseJob.copyWith(schedule: null);
      final events = CronExpansionService.expand(job);

      expect(events, hasLength(1));
      expect(events.first.startTime, job.startTime);
      expect(events.first.pluginId, 'server_flow');
    });

    test('"once" schedule returns single event', () {
      final job = baseJob.copyWith(schedule: 'once');
      final events = CronExpansionService.expand(job);

      expect(events, hasLength(1));
    });

    test('"once" is case-insensitive', () {
      final job = baseJob.copyWith(schedule: 'Once');
      final events = CronExpansionService.expand(job);

      expect(events, hasLength(1));
    });

    test('daily cron expands to multiple events', () {
      final job = baseJob.copyWith(schedule: '0 2 * * *');
      final events = CronExpansionService.expand(
        job,
        from: DateTime.utc(2025, 1, 15),
        until: DateTime.utc(2025, 1, 20),
      );

      // Should have multiple events (one per day)
      expect(events.length, greaterThan(1));

      // All events should be at 02:00 UTC
      for (final event in events) {
        expect(event.startTime.toUtc().hour, 2);
        expect(event.startTime.toUtc().minute, 0);
      }
    });

    test('every-5-min cron respects maxOccurrences', () {
      final job = baseJob.copyWith(schedule: '*/5 * * * *');
      final events = CronExpansionService.expand(
        job,
        maxOccurrences: 10,
        from: DateTime.utc(2025, 1, 15),
        until: DateTime.utc(2025, 1, 16),
      );

      expect(events, hasLength(10));
    });

    test('event has correct metadata', () {
      final job = baseJob.copyWith(schedule: 'once');
      final events = CronExpansionService.expand(job);

      final event = events.first;
      expect(event.title, job.command);
      expect(event.subtitle, job.host);
      expect(event.groupKey, job.host);
      expect(event.categoryLabel, job.category);
      expect(event.metadata['user'], job.user);
      expect(event.metadata['schedule'], job.schedule);
    });

    test('event duration from job duration', () {
      final job = baseJob.copyWith(schedule: 'once', duration: 1800);
      final events = CronExpansionService.expand(job);

      final event = events.first;
      expect(event.endTime, isNotNull);
      expect(
        event.endTime!.difference(event.startTime),
        const Duration(seconds: 1800),
      );
    });

    test('event endTime from job endTime overrides duration', () {
      final job = baseJob.copyWith(
        schedule: 'once',
        duration: 100,
        endTime: DateTime.utc(2025, 1, 15, 2, 0),
      );
      final events = CronExpansionService.expand(job);

      final event = events.first;
      expect(event.endTime, isNotNull);
      // endTime - startTime = 2h, not 100s
      expect(
        event.endTime!.difference(event.startTime),
        const Duration(hours: 2),
      );
    });

    test('unparseable cron returns single event', () {
      final job = baseJob.copyWith(schedule: 'not-a-cron-expression');
      final events = CronExpansionService.expand(job);

      expect(events, hasLength(1));
      expect(events.first.startTime, job.startTime);
    });
  });
}
