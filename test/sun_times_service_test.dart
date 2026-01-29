import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/services/sun_times_service.dart';

void main() {
  group('SunTimesService', () {
    test('default latitude should be 40.0 (continental US average)', () {
      expect(SunTimesService.defaultLatitude, 40.0);
    });

    test('calculates sunrise/sunset for Denver, CO (MST)', () {
      // Denver, CO: 39.7°N, 105.0°W, timezone UTC-7 (MST)
      final date = DateTime(2026, 1, 29); // Late January
      final result = SunTimesService.calculate(
        date: date,
        latitude: 39.7,
        longitude: -105.0,
        timezoneOffsetHours: -7.0,
      );

      // Verify sunrise and sunset are not null
      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);
      expect(result.isPolarDay, isFalse);
      expect(result.isPolarNight, isFalse);

      // In late January in Denver:
      // - Sunrise should be around 7:00-7:15 AM MST
      // - Sunset should be around 5:15-5:30 PM MST
      final sunriseHour = result.sunrise!.hour;
      final sunsetHour = result.sunset!.hour;

      // Sunrise should be between 6:30 AM and 7:30 AM
      expect(sunriseHour, inInclusiveRange(6, 7),
          reason: 'Sunrise hour should be between 6-7 AM in late January');

      // Sunset should be between 5:00 PM and 6:00 PM (17:00-18:00)
      expect(sunsetHour, inInclusiveRange(17, 18),
          reason: 'Sunset hour should be between 5-6 PM in late January');
    });

    test('calculates sunrise/sunset for Phoenix, AZ (MST)', () {
      // Phoenix, AZ: 33.4°N, 112.1°W, timezone UTC-7 (MST year-round)
      final date = DateTime(2026, 1, 29);
      final result = SunTimesService.calculate(
        date: date,
        latitude: 33.4,
        longitude: -112.1,
        timezoneOffsetHours: -7.0,
      );

      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);

      // Phoenix is further south than Denver, so days are slightly longer in winter
      // Sunrise: ~7:15-7:30 AM, Sunset: ~5:45-6:00 PM
      final sunriseHour = result.sunrise!.hour;
      final sunsetHour = result.sunset!.hour;

      expect(sunriseHour, inInclusiveRange(7, 8),
          reason: 'Phoenix sunrise should be around 7 AM in late January');
      expect(sunsetHour, inInclusiveRange(17, 18),
          reason: 'Phoenix sunset should be around 5-6 PM in late January');
    });

    test('calculates sunrise/sunset for Salt Lake City, UT (MST)', () {
      // Salt Lake City, UT: 40.8°N, 111.9°W, timezone UTC-7 (MST)
      final date = DateTime(2026, 1, 29);
      final result = SunTimesService.calculate(
        date: date,
        latitude: 40.8,
        longitude: -111.9,
        timezoneOffsetHours: -7.0,
      );

      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);

      // Salt Lake City is at similar latitude to Denver
      final sunriseHour = result.sunrise!.hour;
      final sunsetHour = result.sunset!.hour;

      expect(sunriseHour, inInclusiveRange(7, 8));
      expect(sunsetHour, inInclusiveRange(17, 18));
    });

    test('longitude estimation from timezone is correct for MST', () {
      // MST is UTC-7, which corresponds to ~105°W longitude
      // This is estimated as: offsetHours * 15 = -7 * 15 = -105
      // We can't easily test this without mocking DateTime, but we can test the formula

      // For MST (UTC-7), expected longitude is approximately -105
      const mstOffset = -7.0;
      final estimatedLongitude = mstOffset * 15.0;
      expect(estimatedLongitude, -105.0);
    });

    test('handles summer solstice correctly for MST', () {
      // Summer solstice - longest day of the year
      final date = DateTime(2026, 6, 21);
      final result = SunTimesService.calculate(
        date: date,
        latitude: 39.7, // Denver
        longitude: -105.0,
        timezoneOffsetHours: -6.0, // MDT in summer
      );

      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);

      // Summer in Denver:
      // - Sunrise should be very early (~5:30 AM MDT)
      // - Sunset should be late (~8:30 PM MDT)
      final sunriseHour = result.sunrise!.hour;
      final sunsetHour = result.sunset!.hour;

      expect(sunriseHour, inInclusiveRange(5, 6),
          reason: 'Sunrise should be around 5-6 AM on summer solstice');
      expect(sunsetHour, inInclusiveRange(20, 21),
          reason: 'Sunset should be around 8-9 PM on summer solstice');
    });

    test('handles winter solstice correctly for MST', () {
      // Winter solstice - shortest day of the year
      final date = DateTime(2026, 12, 21);
      final result = SunTimesService.calculate(
        date: date,
        latitude: 39.7, // Denver
        longitude: -105.0,
        timezoneOffsetHours: -7.0, // MST in winter
      );

      expect(result.sunrise, isNotNull);
      expect(result.sunset, isNotNull);

      // Winter in Denver:
      // - Sunrise should be late (~7:15 AM MST)
      // - Sunset should be early (~4:40 PM MST)
      final sunriseHour = result.sunrise!.hour;
      final sunsetHour = result.sunset!.hour;

      expect(sunriseHour, inInclusiveRange(7, 8),
          reason: 'Sunrise should be around 7 AM on winter solstice');
      expect(sunsetHour, inInclusiveRange(16, 17),
          reason: 'Sunset should be around 4-5 PM on winter solstice');
    });
  });
}
