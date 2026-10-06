import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/plugins/server_flow/data/cron_job_model.dart';

void main() {
  final sampleJob = CronJob(
    id: 'test-1',
    host: 'web-prod-01',
    command: '/usr/bin/backup.sh',
    startTime: DateTime.utc(2025, 1, 15, 2, 30),
    user: 'root',
    category: 'backup',
    duration: 3600,
    schedule: '0 2 * * *',
    os: 'linux',
    importBatchId: 'batch-1',
    importedAt: DateTime.utc(2025, 1, 15, 0, 0),
  );

  group('CronJob', () {
    test('toJson and fromJson round-trip', () {
      final json = sampleJob.toJson();
      final restored = CronJob.fromJson(json);

      expect(restored.id, sampleJob.id);
      expect(restored.host, sampleJob.host);
      expect(restored.command, sampleJob.command);
      expect(restored.startTime, sampleJob.startTime);
      expect(restored.user, sampleJob.user);
      expect(restored.category, sampleJob.category);
      expect(restored.duration, sampleJob.duration);
      expect(restored.schedule, sampleJob.schedule);
      expect(restored.os, sampleJob.os);
      expect(restored.importBatchId, sampleJob.importBatchId);
      expect(restored.importedAt, sampleJob.importedAt);
    });

    test('effectiveEndTime returns endTime when set', () {
      final job = sampleJob.copyWith(endTime: DateTime.utc(2025, 1, 15, 4, 0));
      expect(job.effectiveEndTime, DateTime.utc(2025, 1, 15, 4, 0));
    });

    test('effectiveEndTime uses duration when no endTime', () {
      expect(
        sampleJob.effectiveEndTime,
        DateTime.utc(2025, 1, 15, 3, 30), // 2:30 + 3600s = 3:30
      );
    });

    test(
      'effectiveEndTime returns startTime when no endTime and zero duration',
      () {
        final job = sampleJob.copyWith(duration: 0, endTime: null);
        expect(job.effectiveEndTime, job.startTime);
      },
    );

    test('equality based on id', () {
      final job1 = sampleJob;
      final job2 = sampleJob.copyWith(host: 'different');
      expect(job1, equals(job2));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-2',
        'host': 'server',
        'command': 'cmd',
        'startTime': '2025-01-15T02:30:00.000Z',
        'user': 'admin',
        'importBatchId': 'batch-1',
        'importedAt': '2025-01-15T00:00:00.000Z',
      };
      final job = CronJob.fromJson(json);
      expect(job.category, 'uncategorized');
      expect(job.duration, 0);
      expect(job.schedule, isNull);
      expect(job.os, 'linux');
      expect(job.endTime, isNull);
    });
  });
}
