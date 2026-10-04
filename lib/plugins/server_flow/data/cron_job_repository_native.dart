import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_model.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';
import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository_base.dart';

/// Native implementation using JSON file in app documents directory.
class CronJobRepositoryImpl
    with CronJobRepositoryBase
    implements CronJobRepository {
  static const _fileName = 'server_flow_cron_jobs.json';
  File? _file;

  Future<File> get _storageFile async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, _fileName));
    return _file!;
  }

  @override
  Future<Map<String, CronJob>> loadJobs() async {
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

  @override
  Future<void> saveJobs(Map<String, CronJob> jobs) async {
    final file = await _storageFile;
    final jsonList = jobs.values.map((j) => j.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  @override
  Future<void> clear() async {
    final file = await _storageFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
