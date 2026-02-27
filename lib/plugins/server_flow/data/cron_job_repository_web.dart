import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository_base.dart';

/// Web implementation using SharedPreferences with JSON storage.
class CronJobRepositoryImpl
    with CronJobRepositoryBase
    implements CronJobRepository {
  static const _storageKey = 'server_flow_cron_jobs';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<Map<String, CronJob>> loadJobs() async {
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

  @override
  Future<void> saveJobs(Map<String, CronJob> jobs) async {
    final prefs = await _preferences;
    final jsonList = jobs.values.map((j) => j.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_storageKey);
  }
}
