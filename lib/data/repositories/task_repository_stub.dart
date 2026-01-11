import 'package:timeflow/data/repositories/task_repository.dart';

/// Stub implementation - should never be used at runtime.
/// Conditional imports will select the correct platform implementation.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl() {
    throw UnsupportedError(
      'Cannot create TaskRepository without a platform implementation',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
