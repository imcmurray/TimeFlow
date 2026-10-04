import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/services/sun_times_service.dart';

/// Compares in UTC so the tests hold in any time zone. Reference times come
/// from NOAA's full spreadsheet algorithm, rounded to the minute.
void expectNear(DateTime? actual, DateTime expectedUtc, {int minutes = 3}) {
  expect(actual, isNotNull);
  final diff = actual!.toUtc().difference(expectedUtc).inMinutes.abs();
  expect(
    diff,
    lessThanOrEqualTo(minutes),
    reason: 'got ${actual.toUtc()}, expected about $expectedUtc',
  );
}

void main() {
  test('Salt Lake City in October', () {
    final sun = SunTimesService.calculate(
      date: DateTime(2026, 10, 4),
      latitude: 40.7608,
      longitude: -111.891,
    );
    expectNear(sun.sunrise, DateTime.utc(2026, 10, 4, 13, 27));
    expectNear(sun.sunset, DateTime.utc(2026, 10, 5, 1, 5));
  });

  test('Denver at the summer solstice', () {
    final sun = SunTimesService.calculate(
      date: DateTime(2026, 6, 21),
      latitude: 39.7392,
      longitude: -104.9903,
    );
    expectNear(sun.sunrise, DateTime.utc(2026, 6, 21, 11, 32));
    expectNear(sun.sunset, DateTime.utc(2026, 6, 22, 2, 31));
  });

  test('London at the winter solstice (longitude near zero)', () {
    final sun = SunTimesService.calculate(
      date: DateTime(2026, 12, 21),
      latitude: 51.5074,
      longitude: -0.1278,
    );
    expectNear(sun.sunrise, DateTime.utc(2026, 12, 21, 8, 4));
    expectNear(sun.sunset, DateTime.utc(2026, 12, 21, 15, 53));
  });

  test('Sydney in January (southern hemisphere)', () {
    final sun = SunTimesService.calculate(
      date: DateTime(2026, 1, 15),
      latitude: -33.8688,
      longitude: 151.2093,
    );
    expectNear(sun.sunrise, DateTime.utc(2026, 1, 14, 18, 59));
    expectNear(sun.sunset, DateTime.utc(2026, 1, 15, 9, 10));
  });

  test('polar day and night in Tromsø', () {
    final summer = SunTimesService.calculate(
      date: DateTime(2026, 6, 21),
      latitude: 69.65,
      longitude: 18.96,
    );
    expect(summer.isPolarDay, isTrue);
    expect(summer.sunrise, isNull);
    final winter = SunTimesService.calculate(
      date: DateTime(2026, 12, 21),
      latitude: 69.65,
      longitude: 18.96,
    );
    expect(winter.isPolarNight, isTrue);
  });
}
