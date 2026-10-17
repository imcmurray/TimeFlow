import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/services/background_breadcrumb.dart';

void main() {
  setUp(BackgroundBreadcrumb.clear);
  tearDown(BackgroundBreadcrumb.clear);

  test('says nothing before the background isolate has ever run', () async {
    expect(await BackgroundBreadcrumb.read(), isNull);
  });

  test('keeps the steps in the order they happened, with times', () async {
    final at = DateTime(2026, 10, 17, 11, 49, 3);
    await BackgroundBreadcrumb.note(
      '${BackgroundBreadcrumb.received} completed',
      at: at,
    );
    await BackgroundBreadcrumb.note(BackgroundBreadcrumb.database, at: at);
    await BackgroundBreadcrumb.note(BackgroundBreadcrumb.written, at: at);

    final lines = (await BackgroundBreadcrumb.read())!.split('\n');
    expect(lines, hasLength(3));
    expect(lines.first, contains('received completed'));
    expect(lines.last, contains('written'));
    // The time matters as much as the step: a breadcrumb from yesterday's tap
    // would otherwise read like today's.
    expect(lines.first, contains('11:49'));
  });

  test('carries the exception in its own words', () async {
    await BackgroundBreadcrumb.failed(StateError('database is locked'));
    expect(await BackgroundBreadcrumb.read(), contains('database is locked'));
  });

  test('keeps the last dozen lines, not a log', () async {
    for (var i = 1; i <= 20; i++) {
      await BackgroundBreadcrumb.note('step $i');
    }
    final lines = (await BackgroundBreadcrumb.read())!.split('\n');
    expect(lines, hasLength(12));
    expect(lines.last, contains('step 20'));
    expect(lines.first, contains('step 9'));
  });

  test('Clear empties it, so the next tap stands alone', () async {
    await BackgroundBreadcrumb.note('step');
    await BackgroundBreadcrumb.clear();
    expect(await BackgroundBreadcrumb.read(), isNull);
  });
}
