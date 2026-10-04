import 'dart:math' as math;

/// Sunrise and sunset times, from NOAA's solar position equations.
///
/// Accurate to a couple of minutes away from the poles. Times are computed
/// in UTC and converted to the device's local time, so DST and the time
/// zone are handled by the platform.
class SunTimesService {
  const SunTimesService._();

  /// Sunrise and sunset on [date] (its calendar day) at the given location.
  static SunTimes calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final dayStartUtc = DateTime.utc(date.year, date.month, date.day);
    final dayOfYear = dayStartUtc.difference(DateTime.utc(date.year)).inDays;
    final daysInYear = DateTime.utc(
      date.year + 1,
    ).difference(DateTime.utc(date.year)).inDays;

    // Evaluate at local solar noon, where the day's values matter most.
    final solarNoonUtcHours = 12 - longitude / 15;
    final gamma =
        2 * math.pi / daysInYear * (dayOfYear + (solarNoonUtcHours - 12) / 24);

    final eqTimeMinutes =
        229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));
    final declination =
        0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.00148 * math.sin(3 * gamma);

    final lat = latitude * math.pi / 180;
    // 90.833°: the sun's centre at the horizon plus refraction and the
    // sun's apparent radius.
    final zenith = 90.833 * math.pi / 180;
    final cosHourAngle =
        math.cos(zenith) / (math.cos(lat) * math.cos(declination)) -
        math.tan(lat) * math.tan(declination);

    if (cosHourAngle < -1) return const SunTimes(isPolarDay: true);
    if (cosHourAngle > 1) return const SunTimes(isPolarNight: true);

    final hourAngleDeg = math.acos(cosHourAngle) * 180 / math.pi;
    DateTime local(double utcMinutes) =>
        dayStartUtc.add(Duration(seconds: (utcMinutes * 60).round())).toLocal();

    return SunTimes(
      sunrise: local(720 - 4 * (longitude + hourAngleDeg) - eqTimeMinutes),
      sunset: local(720 - 4 * (longitude - hourAngleDeg) - eqTimeMinutes),
    );
  }
}

/// Sunrise and sunset for one day.
class SunTimes {
  /// Local sunrise, or null during polar day or night.
  final DateTime? sunrise;

  /// Local sunset, or null during polar day or night.
  final DateTime? sunset;

  /// The sun doesn't set.
  final bool isPolarDay;

  /// The sun doesn't rise.
  final bool isPolarNight;

  const SunTimes({
    this.sunrise,
    this.sunset,
    this.isPolarDay = false,
    this.isPolarNight = false,
  });

  @override
  String toString() {
    if (isPolarDay) return 'SunTimes(polar day)';
    if (isPolarNight) return 'SunTimes(polar night)';
    return 'SunTimes(sunrise: $sunrise, sunset: $sunset)';
  }
}
