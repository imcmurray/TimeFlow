import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';

/// Shared implementation of [CronJobRepository] methods that operate on an
/// in-memory Map<String, CronJob>.
///
/// Subclasses only need to implement [loadJobs], [saveJobs], and [clear].
mixin CronJobRepositoryBase implements CronJobRepository {
  Future<Map<String, CronJob>> loadJobs();
  Future<void> saveJobs(Map<String, CronJob> jobs);

  @override
  Future<void> saveAll(List<CronJob> jobs) async {
    final existing = await loadJobs();
    for (final job in jobs) {
      existing[job.id] = job;
    }
    await saveJobs(existing);
  }

  @override
  Future<List<CronJob>> getAll() async {
    final jobs = await loadJobs();
    return jobs.values.toList();
  }

  @override
  Future<List<CronJob>> getForRange(DateTime start, DateTime end) async {
    final jobs = await loadJobs();
    return jobs.values.where((job) {
      final effectiveEnd = job.effectiveEndTime;
      return job.startTime.isBefore(end) && effectiveEnd.isAfter(start);
    }).toList();
  }

  @override
  Future<List<CronJob>> getByBatchId(String batchId) async {
    final jobs = await loadJobs();
    return jobs.values.where((j) => j.importBatchId == batchId).toList();
  }

  @override
  Future<void> deleteByBatchId(String batchId) async {
    final jobs = await loadJobs();
    jobs.removeWhere((_, j) => j.importBatchId == batchId);
    await saveJobs(jobs);
  }

  @override
  Future<List<String>> getDistinctHosts() async {
    final jobs = await loadJobs();
    return jobs.values.map((j) => j.host).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctCategories() async {
    final jobs = await loadJobs();
    return jobs.values.map((j) => j.category).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctUsers() async {
    final jobs = await loadJobs();
    return jobs.values.map((j) => j.user).toSet().toList()..sort();
  }
}
