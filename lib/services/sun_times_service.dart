import 'dart:math' as math;

/// Service for calculating sunrise and sunset times.
///
/// Uses a simplified solar position algorithm that provides reasonably
/// accurate times for most locations. Accuracy is typically within a few minutes.
class SunTimesService {
  /// Default latitude (approximately mid-latitude).
  static const double defaultLatitude = 45.0;

  /// Default longitude - will be estimated from timezone if not set.
  static const double defaultLongitude = 0.0;

  /// Estimates longitude from the device's timezone offset.
  /// Timezones are roughly based on 15 degrees of longitude per hour.
  static double estimateLongitudeFromTimezone() {
    final now = DateTime.now();
    final offsetHours = now.timeZoneOffset.inMinutes / 60.0;
    // Each hour of timezone offset ≈ 15 degrees of longitude
    return offsetHours * 15.0;
  }

  /// Gets the timezone offset in hours for the current device.
  static double getTimezoneOffsetHours() {
    return DateTime.now().timeZoneOffset.inMinutes / 60.0;
  }

  /// Calculates sunrise and sunset times for a given date and location.
  ///
  /// Returns a [SunTimes] record with sunrise and sunset as DateTime objects.
  /// If the sun doesn't rise or set on this day (polar regions), returns null
  /// for those values.
  ///
  /// The [timezoneOffsetHours] parameter should be the device's timezone offset
  /// (e.g., -5 for EST, +1 for CET). If not provided, it will be auto-detected.
  static SunTimes calculate({
    required DateTime date,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
    double? timezoneOffsetHours,
  }) {
    // Use provided timezone offset or detect from device
    final tzOffset = timezoneOffsetHours ?? getTimezoneOffsetHours();

    // If longitude is 0 (default/unset), estimate from timezone
    final effectiveLongitude = (longitude == 0.0)
        ? estimateLongitudeFromTimezone()
        : longitude;

    // Day of year (1-366)
    final dayOfYear = _dayOfYear(date);

    // Solar declination angle (radians)
    final declination = _solarDeclination(dayOfYear);

    // Latitude in radians
    final latRad = latitude * math.pi / 180;

    // Hour angle at sunrise/sunset
    final cosHourAngle = -math.tan(latRad) * math.tan(declination);

    // Check for polar day/night
    if (cosHourAngle < -1) {
      // Sun never sets (midnight sun)
      return SunTimes(
        sunrise: DateTime(date.year, date.month, date.day, 0, 0),
        sunset: DateTime(date.year, date.month, date.day, 23, 59),
        isPolarDay: true,
        isPolarNight: false,
      );
    }
    if (cosHourAngle > 1) {
      // Sun never rises (polar night)
      return SunTimes(
        sunrise: null,
        sunset: null,
        isPolarDay: false,
        isPolarNight: true,
      );
    }

    final hourAngle = math.acos(cosHourAngle);

    // Convert hour angle to hours
    final hourAngleHours = hourAngle * 180 / math.pi / 15;

    // Equation of time correction (simplified)
    final eot = _equationOfTime(dayOfYear);

    // Calculate solar noon in UTC, then convert to local time
    // Solar noon at longitude 0 is 12:00 UTC
    // Each 15 degrees of longitude shifts solar noon by 1 hour
    final solarNoonUTC = 12.0 - effectiveLongitude / 15 - eot / 60;

    // Convert to local time by adding timezone offset
    final solarNoonLocal = solarNoonUTC + tzOffset;

    // Sunrise and sunset times in local time
    final sunriseHour = solarNoonLocal - hourAngleHours;
    final sunsetHour = solarNoonLocal + hourAngleHours;

    return SunTimes(
      sunrise: _hoursToDateTime(date, sunriseHour),
      sunset: _hoursToDateTime(date, sunsetHour),
      isPolarDay: false,
      isPolarNight: false,
    );
  }

  /// Gets the day of year (1-366) for a given date.
  static int _dayOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    return date.difference(firstDayOfYear).inDays + 1;
  }

  /// Calculates solar declination angle in radians.
  static double _solarDeclination(int dayOfYear) {
    // Simplified formula
    return 0.409 * math.sin(2 * math.pi / 365 * (dayOfYear - 81));
  }

  /// Simplified equation of time (returns minutes).
  static double _equationOfTime(int dayOfYear) {
    final b = 2 * math.pi * (dayOfYear - 81) / 365;
    return 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  }

  /// Converts decimal hours to a DateTime.
  static DateTime _hoursToDateTime(DateTime date, double hours) {
    // Clamp to valid range
    hours = hours.clamp(0, 24);

    final hour = hours.floor();
    final minuteDecimal = (hours - hour) * 60;
    final minute = minuteDecimal.round().clamp(0, 59);

    return DateTime(date.year, date.month, date.day, hour.clamp(0, 23), minute);
  }
}

/// Represents sunrise and sunset times for a day.
class SunTimes {
  /// Time of sunrise, or null if sun doesn't rise.
  final DateTime? sunrise;

  /// Time of sunset, or null if sun doesn't set.
  final DateTime? sunset;

  /// True if this is a polar day (midnight sun).
  final bool isPolarDay;

  /// True if this is a polar night (no sunrise).
  final bool isPolarNight;

  const SunTimes({
    this.sunrise,
    this.sunset,
    this.isPolarDay = false,
    this.isPolarNight = false,
  });

  /// Gets the hour of sunrise (0-23), or null if no sunrise.
  int? get sunriseHour => sunrise?.hour;

  /// Gets the hour of sunset (0-23), or null if no sunset.
  int? get sunsetHour => sunset?.hour;

  @override
  String toString() {
    if (isPolarDay) return 'SunTimes(Polar Day)';
    if (isPolarNight) return 'SunTimes(Polar Night)';
    return 'SunTimes(sunrise: $sunrise, sunset: $sunset)';
  }
}
