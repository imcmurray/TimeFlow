import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/services/background_breadcrumb.dart';
import 'package:timeflow/services/reminder_coordinator.dart';

/// WAL keeps a reader in the app's main isolate out of the way of this write.
/// A writer there is still refused at once, whatever busy_timeout says, so the
/// handler tries again rather than lose the tap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const quick = [
    Duration(milliseconds: 1),
    Duration(milliseconds: 1),
    Duration(milliseconds: 1),
  ];
  final locked = Exception(
    'SqliteException(5): while executing, database is locked, '
    'database is locked (code 5)',
  );

  setUp(BackgroundBreadcrumb.clear);
  tearDown(BackgroundBreadcrumb.clear);

  test('a write refused twice still lands', () async {
    var tries = 0;
    await writeWithRetries(() async {
      tries++;
      if (tries < 3) throw locked;
    }, waits: quick);
    expect(tries, 3);
  });

  test('each wait is in the breadcrumb, so a lost tap says why', () async {
    var tries = 0;
    await writeWithRetries(() async {
      tries++;
      if (tries < 2) throw locked;
    }, waits: quick);
    expect(
      await BackgroundBreadcrumb.read(),
      contains(BackgroundBreadcrumb.locked),
    );
  });

  test('a lock that never clears is thrown, not swallowed', () async {
    var tries = 0;
    await expectLater(
      writeWithRetries(() async {
        tries++;
        throw locked;
      }, waits: quick),
      throwsA(isA<Exception>()),
    );
    // One attempt per wait, and the first one.
    expect(tries, quick.length + 1);
  });

  test('a failure that is not the lock is thrown at once', () async {
    var tries = 0;
    await expectLater(
      writeWithRetries(() async {
        tries++;
        throw StateError('column disappeared');
      }, waits: quick),
      throwsA(isA<StateError>()),
    );
    expect(tries, 1, reason: 'retrying it would only delay the breadcrumb');
  });

  test('the real waits are short enough for a background launch', () {
    final total = backgroundWriteWaits.fold(Duration.zero, (sum, w) => sum + w);
    expect(total.inMilliseconds, lessThanOrEqualTo(2000));
  });
}
