import 'package:timeflow/domain/time/local_date.dart';

/// Holiday calendars offered in settings.
enum HolidayRegion {
  us('United States'),
  uk('United Kingdom'),
  ca('Canada'),
  au('Australia'),
  none('None');

  final String label;
  const HolidayRegion(this.label);

  static HolidayRegion fromCode(String? code) => HolidayRegion.values
      .firstWhere((r) => r.name == code, orElse: () => HolidayRegion.none);

  /// The calendar for a device's country code ('US', 'GB', ...).
  static HolidayRegion forCountry(String? countryCode) =>
      switch (countryCode?.toUpperCase()) {
        'US' => HolidayRegion.us,
        'GB' || 'UK' => HolidayRegion.uk,
        'CA' => HolidayRegion.ca,
        'AU' => HolidayRegion.au,
        _ => HolidayRegion.none,
      };
}

/// Public holidays and well-known observances, plus the calendar facts shown
/// on the day watermark. All arithmetic is on calendar dates, so it isn't
/// thrown off by DST.
class HolidaysService {
  const HolidaysService._();

  /// The holiday on [date] in [region], or null.
  static String? holidayName(DateTime date, HolidayRegion region) {
    final d = LocalDate.of(date);
    return switch (region) {
      HolidayRegion.us => _us(d),
      HolidayRegion.uk => _uk(d),
      HolidayRegion.ca => _ca(d),
      HolidayRegion.au => _au(d),
      HolidayRegion.none => null,
    };
  }

  static String? _us(LocalDate d) {
    final easter = easterSunday(d.year);
    return switch ((d.month, d.day)) {
      (1, 1) => "New Year's Day",
      (2, 14) => "Valentine's Day",
      (3, 17) => "St. Patrick's Day",
      (6, 19) => 'Juneteenth',
      (7, 4) => 'Independence Day',
      (10, 31) => 'Halloween',
      (11, 11) => 'Veterans Day',
      (12, 24) => 'Christmas Eve',
      (12, 25) => 'Christmas Day',
      (12, 31) => "New Year's Eve",
      _ when d == easter => 'Easter',
      _ when _nth(d, 1, DateTime.monday, 3) => 'MLK Day',
      _ when _nth(d, 2, DateTime.monday, 3) => "Presidents' Day",
      _ when _nth(d, 5, DateTime.sunday, 2) => "Mother's Day",
      _ when _last(d, 5, DateTime.monday) => 'Memorial Day',
      _ when _nth(d, 6, DateTime.sunday, 3) => "Father's Day",
      _ when _nth(d, 9, DateTime.monday, 1) => 'Labor Day',
      _ when _nth(d, 10, DateTime.monday, 2) => "Indigenous Peoples' Day",
      _ when _nth(d, 11, DateTime.thursday, 4) => 'Thanksgiving',
      _ => null,
    };
  }

  static String? _uk(LocalDate d) {
    final easter = easterSunday(d.year);
    return switch ((d.month, d.day)) {
      (1, 1) => "New Year's Day",
      (2, 14) => "Valentine's Day",
      (3, 17) => "St. Patrick's Day",
      (10, 31) => 'Halloween',
      (11, 5) => 'Bonfire Night',
      (12, 25) => 'Christmas Day',
      (12, 26) => 'Boxing Day',
      (12, 31) => "New Year's Eve",
      _ when d == easter.addDays(-21) => 'Mothering Sunday',
      _ when d == easter.addDays(-2) => 'Good Friday',
      _ when d == easter => 'Easter Sunday',
      _ when d == easter.addDays(1) => 'Easter Monday',
      _ when _nth(d, 5, DateTime.monday, 1) => 'Early May Bank Holiday',
      _ when _last(d, 5, DateTime.monday) => 'Spring Bank Holiday',
      _ when _nth(d, 6, DateTime.sunday, 3) => "Father's Day",
      _ when _last(d, 8, DateTime.monday) => 'Summer Bank Holiday',
      _ when _nth(d, 11, DateTime.sunday, 2) => 'Remembrance Sunday',
      _ => null,
    };
  }

  static String? _ca(LocalDate d) {
    final easter = easterSunday(d.year);
    // Victoria Day: the last Monday before May 25.
    final victoria = LocalDate(
      d.year,
      5,
      24,
    ).addDays(-((LocalDate(d.year, 5, 24).weekday - DateTime.monday) % 7));
    return switch ((d.month, d.day)) {
      (1, 1) => "New Year's Day",
      (2, 14) => "Valentine's Day",
      (7, 1) => 'Canada Day',
      (9, 30) => 'Truth and Reconciliation Day',
      (10, 31) => 'Halloween',
      (11, 11) => 'Remembrance Day',
      (12, 25) => 'Christmas Day',
      (12, 26) => 'Boxing Day',
      (12, 31) => "New Year's Eve",
      _ when d == easter.addDays(-2) => 'Good Friday',
      _ when d == easter => 'Easter Sunday',
      _ when _nth(d, 2, DateTime.monday, 3) => 'Family Day',
      _ when _nth(d, 5, DateTime.sunday, 2) => "Mother's Day",
      _ when d == victoria => 'Victoria Day',
      _ when _nth(d, 6, DateTime.sunday, 3) => "Father's Day",
      _ when _nth(d, 8, DateTime.monday, 1) => 'Civic Holiday',
      _ when _nth(d, 9, DateTime.monday, 1) => 'Labour Day',
      _ when _nth(d, 10, DateTime.monday, 2) => 'Thanksgiving',
      _ => null,
    };
  }

  static String? _au(LocalDate d) {
    final easter = easterSunday(d.year);
    return switch ((d.month, d.day)) {
      (1, 1) => "New Year's Day",
      (1, 26) => 'Australia Day',
      (4, 25) => 'Anzac Day',
      (12, 25) => 'Christmas Day',
      (12, 26) => 'Boxing Day',
      (12, 31) => "New Year's Eve",
      _ when d == easter.addDays(-2) => 'Good Friday',
      _ when d == easter => 'Easter Sunday',
      _ when d == easter.addDays(1) => 'Easter Monday',
      _ when _nth(d, 5, DateTime.sunday, 2) => "Mother's Day",
      _ when _nth(d, 6, DateTime.monday, 2) => "King's Birthday",
      _ when _nth(d, 9, DateTime.sunday, 1) => "Father's Day",
      _ => null,
    };
  }

  /// Whether [d] is the [n]th [weekday] of [month].
  static bool _nth(LocalDate d, int month, int weekday, int n) =>
      d.month == month && d.weekday == weekday && (d.day - 1) ~/ 7 == n - 1;

  /// Whether [d] is the last [weekday] of [month].
  static bool _last(LocalDate d, int month, int weekday) =>
      d.month == month && d.weekday == weekday && d.addDays(7).month != month;

  /// Easter Sunday (Gregorian), by the anonymous Gregorian algorithm.
  static LocalDate easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return LocalDate(year, month, day);
  }

  /// ISO 8601 week number (weeks start Monday; week 1 holds the first
  /// Thursday of the year).
  static int weekNumber(DateTime date) {
    final d = LocalDate.of(date);
    final thursday = d.addDays(DateTime.thursday - d.weekday);
    return LocalDate(thursday.year, 1, 1).daysUntil(thursday) ~/ 7 + 1;
  }

  /// Day of the year, 1-366.
  static int dayOfYear(DateTime date) {
    final d = LocalDate.of(date);
    return LocalDate(d.year, 1, 1).daysUntil(d) + 1;
  }

  static int quarter(DateTime date) => (date.month - 1) ~/ 3 + 1;

  /// Days left in the year after [date].
  static int daysRemainingInYear(DateTime date) {
    final d = LocalDate.of(date);
    return d.daysUntil(LocalDate(d.year, 12, 31));
  }

  /// Moon phase emoji for the evening of [date] (approximate; within a day).
  static String moonPhaseEmoji(DateTime date) {
    const synodicMonth = 29.530588853;
    // Reference new moon: 2000-01-06 18:14 UTC.
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    final evening = DateTime.utc(date.year, date.month, date.day, 20);
    final days = evening.difference(reference).inMinutes / (60 * 24);
    final phase = (days % synodicMonth) / synodicMonth;
    const emoji = ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'];
    return emoji[((phase * 8) + 0.5).floor() % 8];
  }
}
