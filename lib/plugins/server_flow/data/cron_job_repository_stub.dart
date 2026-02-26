import 'package:cron_timeflow/plugins/server_flow/data/cron_job_repository.dart';

/// Stub implementation — should never be used at runtime.
class CronJobRepositoryImpl implements CronJobRepository {
  CronJobRepositoryImpl() {
    throw UnsupportedError(
      'Cannot create CronJobRepository without a platform implementation',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
