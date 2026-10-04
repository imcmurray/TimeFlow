import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';

import 'cron_job_repository_stub.dart'
    if (dart.library.io) 'cron_job_repository_native.dart'
    if (dart.library.html) 'cron_job_repository_web.dart' as impl;

/// Abstract repository for cron job storage.
///
/// Platform-specific implementations selected at compile time:
/// - Native: Drift/SQLite
/// - Web: SharedPreferences + JSON
abstract class CronJobRepository {
  factory CronJobRepository() = impl.CronJobRepositoryImpl;

  Future<void> saveAll(List<CronJob> jobs);
  Future<List<CronJob>> getAll();
  Future<List<CronJob>> getForRange(DateTime start, DateTime end);
  Future<List<CronJob>> getByBatchId(String batchId);
  Future<void> deleteByBatchId(String batchId);
  Future<void> clear();
  Future<List<String>> getDistinctHosts();
  Future<List<String>> getDistinctCategories();
  Future<List<String>> getDistinctUsers();
}
