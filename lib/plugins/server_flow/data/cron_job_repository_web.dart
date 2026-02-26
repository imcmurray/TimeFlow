import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';

/// Web implementation using SharedPreferences with JSON storage.
class CronJobRepositoryImpl implements CronJobRepository {
  static const _storageKey = 'server_flow_cron_jobs';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Map<String, CronJob>> _loadJobs() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return {};

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final jobs = <String, CronJob>{};
    for (final json in jsonList) {
      final job = CronJob.fromJson(json as Map<String, dynamic>);
      jobs[job.id] = job;
    }
    return jobs;
  }

  Future<void> _saveJobs(Map<String, CronJob> jobs) async {
    final prefs = await _preferences;
    final jsonList = jobs.values.map((j) => j.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
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
    final prefs = await _preferences;
    await prefs.remove(_storageKey);
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
