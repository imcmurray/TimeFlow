import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';

/// Native implementation using JSON file in app documents directory.
///
/// Avoids modifying the Drift schema — keeps plugin data isolated.
class CronJobRepositoryImpl implements CronJobRepository {
  static const _fileName = 'server_flow_cron_jobs.json';
  File? _file;

  Future<File> get _storageFile async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, _fileName));
    return _file!;
  }

  Future<Map<String, CronJob>> _loadJobs() async {
    final file = await _storageFile;
    if (!await file.exists()) return {};

    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) return {};

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final jobs = <String, CronJob>{};
    for (final json in jsonList) {
      final job = CronJob.fromJson(json as Map<String, dynamic>);
      jobs[job.id] = job;
    }
    return jobs;
  }

  Future<void> _saveJobs(Map<String, CronJob> jobs) async {
    final file = await _storageFile;
    final jsonList = jobs.values.map((j) => j.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  @override
  Future<void> saveAll(List<CronJob> jobs) async {
    final existing = await _loadJobs();
    for (final job in jobs) {
      existing[job.id] = job;
    }
    await _saveJobs(existing);
  }

  @override
  Future<List<CronJob>> getAll() async {
    final jobs = await _loadJobs();
    return jobs.values.toList();
  }

  @override
  Future<List<CronJob>> getForRange(DateTime start, DateTime end) async {
    final jobs = await _loadJobs();
    return jobs.values.where((job) {
      final effectiveEnd = job.effectiveEndTime;
      return job.startTime.isBefore(end) && effectiveEnd.isAfter(start);
    }).toList();
  }

  @override
  Future<List<CronJob>> getByBatchId(String batchId) async {
    final jobs = await _loadJobs();
    return jobs.values.where((j) => j.importBatchId == batchId).toList();
  }

  @override
  Future<void> deleteByBatchId(String batchId) async {
    final jobs = await _loadJobs();
    jobs.removeWhere((_, j) => j.importBatchId == batchId);
    await _saveJobs(jobs);
  }

  @override
  Future<void> clear() async {
    final file = await _storageFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<String>> getDistinctHosts() async {
    final jobs = await _loadJobs();
    return jobs.values.map((j) => j.host).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctCategories() async {
    final jobs = await _loadJobs();
    return jobs.values.map((j) => j.category).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctUsers() async {
    final jobs = await _loadJobs();
    return jobs.values.map((j) => j.user).toSet().toList()..sort();
  }
}
