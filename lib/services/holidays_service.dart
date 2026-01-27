/// Service for calculating US federal holidays and other notable dates.
///
/// Provides methods to check if a date is a holiday and get holiday names.
class HolidaysService {
  /// Returns the holiday name for a given date, or null if not a holiday.
  static String? getHolidayName(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // Fixed-date holidays
    if (month == 1 && day == 1) return "New Year's Day";
    if (month == 6 && day == 19) return "Juneteenth";
    if (month == 7 && day == 4) return "Independence Day";
    if (month == 11 && day == 11) return "Veterans Day";
    if (month == 12 && day == 25) return "Christmas Day";

    // Floating holidays (calculated)

    // MLK Day: 3rd Monday of January
    if (month == 1 && _isNthWeekdayOfMonth(date, DateTime.monday, 3)) {
      return "MLK Day";
    }

    // Presidents' Day: 3rd Monday of February
    if (month == 2 && _isNthWeekdayOfMonth(date, DateTime.monday, 3)) {
      return "Presidents' Day";
    }

    // Memorial Day: Last Monday of May
    if (month == 5 && _isLastWeekdayOfMonth(date, DateTime.monday)) {
      return "Memorial Day";
    }

    // Labor Day: 1st Monday of September
    if (month == 9 && _isNthWeekdayOfMonth(date, DateTime.monday, 1)) {
      return "Labor Day";
    }

    // Columbus Day: 2nd Monday of October
    if (month == 10 && _isNthWeekdayOfMonth(date, DateTime.monday, 2)) {
      return "Columbus Day";
    }

    // Thanksgiving: 4th Thursday of November
    if (month == 11 && _isNthWeekdayOfMonth(date, DateTime.thursday, 4)) {
      return "Thanksgiving";
    }

    // Easter Sunday (calculated)
    final easter = _calculateEaster(year);
    if (month == easter.month && day == easter.day) {
      return "Easter Sunday";
    }

    // Mother's Day: 2nd Sunday of May
    if (month == 5 && _isNthWeekdayOfMonth(date, DateTime.sunday, 2)) {
      return "Mother's Day";
    }

    // Father's Day: 3rd Sunday of June
    if (month == 6 && _isNthWeekdayOfMonth(date, DateTime.sunday, 3)) {
      return "Father's Day";
    }

    // Halloween
    if (month == 10 && day == 31) return "Halloween";

    // Valentine's Day
    if (month == 2 && day == 14) return "Valentine's Day";

    // St. Patrick's Day
    if (month == 3 && day == 17) return "St. Patrick's Day";

    // Cinco de Mayo
    if (month == 5 && day == 5) return "Cinco de Mayo";

    // New Year's Eve
    if (month == 12 && day == 31) return "New Year's Eve";

    return null;
  }

  /// Returns true if the date is a US federal holiday.
  static bool isFederalHoliday(DateTime date) {
    final name = getHolidayName(date);
    if (name == null) return false;

    // Only these are federal holidays
    const federalHolidays = {
      "New Year's Day",
      "MLK Day",
      "Presidents' Day",
      "Memorial Day",
      "Juneteenth",
      "Independence Day",
      "Labor Day",
      "Columbus Day",
      "Veterans Day",
      "Thanksgiving",
      "Christmas Day",
    };

    return federalHolidays.contains(name);
  }

  /// Returns a short version of the holiday name for display.
  static String? getShortHolidayName(DateTime date) {
    final name = getHolidayName(date);
    if (name == null) return null;

    // Shorten some names for watermark display
    switch (name) {
      case "Independence Day":
        return "July 4th";
      case "Presidents' Day":
        return "Presidents Day";
      case "New Year's Day":
        return "New Year";
      case "New Year's Eve":
        return "NYE";
      case "St. Patrick's Day":
        return "St. Patrick's";
      default:
        return name;
    }
  }

  /// Check if date is the nth occurrence of a weekday in the month.
  static bool _isNthWeekdayOfMonth(DateTime date, int weekday, int n) {
    if (date.weekday != weekday) return false;

    // Count how many times this weekday has occurred
    int count = 0;
    for (int d = 1; d <= date.day; d++) {
      final checkDate = DateTime(date.year, date.month, d);
      if (checkDate.weekday == weekday) count++;
    }

    return count == n;
  }

  /// Check if date is the last occurrence of a weekday in the month.
  static bool _isLastWeekdayOfMonth(DateTime date, int weekday) {
    if (date.weekday != weekday) return false;

    // Check if there's another occurrence of this weekday later in the month
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    for (int d = date.day + 1; d <= daysInMonth; d++) {
      final checkDate = DateTime(date.year, date.month, d);
      if (checkDate.weekday == weekday) return false;
    }

    return true;
  }

  /// Calculate Easter Sunday using the Anonymous Gregorian algorithm.
  static DateTime _calculateEaster(int year) {
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

    return DateTime(year, month, day);
  }

  /// Get the week number of the year (ISO 8601).
  static int getWeekNumber(DateTime date) {
    // Find the Thursday of this week
    final dayOfYear = _getDayOfYear(date);
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday

    // ISO week date: week 1 is the week containing the first Thursday
    final thursdayOffset = DateTime.thursday - weekday;
    final thursdayDate = date.add(Duration(days: thursdayOffset));
    final thursdayDayOfYear = _getDayOfYear(thursdayDate);

    // Week number is (day of year of Thursday + 6) / 7
    return ((thursdayDayOfYear + 6) ~/ 7);
  }

  static int _getDayOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    return date.difference(firstDay).inDays + 1;
  }

  /// Get the day of year (1-366).
  static int getDayOfYear(DateTime date) => _getDayOfYear(date);

  /// Get the quarter (1-4).
  static int getQuarter(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  /// Get days remaining in the year.
  static int getDaysRemainingInYear(DateTime date) {
    final lastDay = DateTime(date.year, 12, 31);
    return lastDay.difference(date).inDays;
  }

  /// Get a simple moon phase indicator (approximate).
  /// Returns: 'new', 'waxing', 'full', 'waning'
  static String getMoonPhase(DateTime date) {
    // Approximate lunar cycle calculation
    // Based on a known new moon date (January 6, 2000)
    final knownNewMoon = DateTime(2000, 1, 6, 18, 14);
    final lunarCycle = 29.53058867; // days

    final daysSinceKnown = date.difference(knownNewMoon).inHours / 24.0;
    final phase = (daysSinceKnown % lunarCycle) / lunarCycle;

    if (phase < 0.03 || phase >= 0.97) return 'new';
    if (phase < 0.22) return 'waxing_crescent';
    if (phase < 0.28) return 'first_quarter';
    if (phase < 0.47) return 'waxing_gibbous';
    if (phase < 0.53) return 'full';
    if (phase < 0.72) return 'waning_gibbous';
    if (phase < 0.78) return 'last_quarter';
    return 'waning_crescent';
  }

  /// Get moon phase emoji.
  static String getMoonPhaseEmoji(DateTime date) {
    switch (getMoonPhase(date)) {
      case 'new':
        return '🌑';
      case 'waxing_crescent':
        return '🌒';
      case 'first_quarter':
        return '🌓';
      case 'waxing_gibbous':
        return '🌔';
      case 'full':
        return '🌕';
      case 'waning_gibbous':
        return '🌖';
      case 'last_quarter':
        return '🌗';
      case 'waning_crescent':
        return '🌘';
      default:
        return '🌑';
    }
  }

  /// Get a readable moon phase name.
  static String getMoonPhaseName(DateTime date) {
    switch (getMoonPhase(date)) {
      case 'new':
        return 'New Moon';
      case 'waxing_crescent':
        return 'Waxing Crescent';
      case 'first_quarter':
        return 'First Quarter';
      case 'waxing_gibbous':
        return 'Waxing Gibbous';
      case 'full':
        return 'Full Moon';
      case 'waning_gibbous':
        return 'Waning Gibbous';
      case 'last_quarter':
        return 'Last Quarter';
      case 'waning_crescent':
        return 'Waning Crescent';
      default:
        return '';
    }
  }
}
