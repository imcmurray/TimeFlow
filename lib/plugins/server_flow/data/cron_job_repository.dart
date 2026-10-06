import 'package:timeflow/core/plugins/plugin_storage.dart';
import 'package:timeflow/plugins/server_flow/data/cron_job_model.dart';

/// Storage for imported cron jobs.
abstract class CronJobRepository {
  Future<void> saveAll(List<CronJob> jobs);
  Future<List<CronJob>> getAll();

  /// All jobs, re-emitted whenever they change.
  Stream<List<CronJob>> watchAll();
  Future<List<CronJob>> getByBatchId(String batchId);
  Future<void> deleteByBatchId(String batchId);
  Future<void> clear();
  Future<List<String>> getDistinctHosts();
  Future<List<String>> getDistinctCategories();
  Future<List<String>> getDistinctUsers();
}

/// Keeps the job list as one JSON value in ServerFlow's plugin storage, so
/// it works the same on every platform, including the web.
class PluginStorageCronJobRepository implements CronJobRepository {
  PluginStorageCronJobRepository(this._storage);

  final PluginStorage _storage;
  static const _key = 'jobs';

  static List<CronJob> _decode(Object? value) => [
    for (final j in (value as List?) ?? const [])
      CronJob.fromJson(j as Map<String, dynamic>),
  ];

  Future<void> _save(Iterable<CronJob> jobs) =>
      _storage.write(_key, [for (final j in jobs) j.toJson()]);

  @override
  Future<List<CronJob>> getAll() async => _decode(await _storage.read(_key));

  @override
  Stream<List<CronJob>> watchAll() => _storage.watch(_key).map(_decode);

  @override
  Future<void> saveAll(List<CronJob> jobs) async {
    final byId = {for (final j in await getAll()) j.id: j};
    for (final j in jobs) {
      byId[j.id] = j;
    }
    await _save(byId.values);
  }

  @override
  Future<List<CronJob>> getByBatchId(String batchId) async =>
      (await getAll()).where((j) => j.importBatchId == batchId).toList();

  @override
  Future<void> deleteByBatchId(String batchId) async =>
      _save((await getAll()).where((j) => j.importBatchId != batchId));

  @override
  Future<void> clear() => _storage.delete(_key);

  Future<List<String>> _distinct(String Function(CronJob) field) async =>
      (await getAll()).map(field).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctHosts() => _distinct((j) => j.host);

  @override
  Future<List<String>> getDistinctCategories() => _distinct((j) => j.category);

  @override
  Future<List<String>> getDistinctUsers() => _distinct((j) => j.user);
}
