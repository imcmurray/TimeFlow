import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/services/holidays_service.dart';

void main() {
  String? us(int y, int m, int d) =>
      HolidaysService.holidayName(DateTime(y, m, d), HolidayRegion.us);

  test('ISO week numbers, including across DST and year ends', () {
    expect(HolidaysService.weekNumber(DateTime(2026, 10, 4)), 40);
    expect(HolidaysService.weekNumber(DateTime(2026, 3, 9)), 11);
    expect(HolidaysService.weekNumber(DateTime(2027, 1, 1)), 53);
    expect(HolidaysService.weekNumber(DateTime(2026, 1, 1)), 1);
    expect(HolidaysService.weekNumber(DateTime(2024, 12, 30)), 1);
  });

  test('day of year and days remaining ignore DST', () {
    expect(HolidaysService.dayOfYear(DateTime(2026, 10, 4)), 277);
    expect(HolidaysService.daysRemainingInYear(DateTime(2026, 12, 30)), 1);
  });

  test('US holidays', () {
    expect(us(2026, 11, 26), 'Thanksgiving');
    expect(us(2026, 5, 25), 'Memorial Day');
    expect(us(2026, 1, 19), 'MLK Day');
    expect(us(2026, 4, 5), 'Easter');
    expect(us(2026, 7, 4), 'Independence Day');
    expect(us(2026, 7, 5), isNull);
  });

  test('other regions', () {
    String? h(HolidayRegion r, int y, int m, int d) =>
        HolidaysService.holidayName(DateTime(y, m, d), r);
    expect(h(HolidayRegion.uk, 2026, 4, 6), 'Easter Monday');
    expect(h(HolidayRegion.uk, 2026, 8, 31), 'Summer Bank Holiday');
    expect(h(HolidayRegion.ca, 2026, 5, 18), 'Victoria Day');
    expect(h(HolidayRegion.ca, 2026, 10, 12), 'Thanksgiving');
    expect(h(HolidayRegion.au, 2026, 4, 25), 'Anzac Day');
    expect(h(HolidayRegion.none, 2026, 12, 25), isNull);
  });

  test('Easter dates', () {
    expect(HolidaysService.easterSunday(2026), LocalDate(2026, 4, 5));
    expect(HolidaysService.easterSunday(2027), LocalDate(2027, 3, 28));
  });

  test('moon phase on a known full moon', () {
    expect(HolidaysService.moonPhaseEmoji(DateTime(2026, 10, 26)), '🌕');
  });
}
