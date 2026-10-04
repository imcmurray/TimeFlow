import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';

import '../helpers/dst.dart';

void main() {
  final first = LocalDate(2026, 3, 1);

  TimelineGeometry geometry({bool futureAtTop = false}) => TimelineGeometry(
    firstDay: first,
    dayCount: 30,
    hourHeight: 60,
    futureAtTop: futureAtTop,
  );

  test('positions follow the wall clock', () {
    final g = geometry();
    expect(g.yOf(DateTime(2026, 3, 1)), 0);
    expect(g.yOf(DateTime(2026, 3, 1, 1, 30)), 90);
    expect(g.yOf(DateTime(2026, 3, 2)), 24 * 60);
    expect(g.totalHeight, 30 * 24 * 60);
  });

  test('future at top flips the axis', () {
    final g = geometry(futureAtTop: true);
    expect(g.yOf(DateTime(2026, 3, 1)), g.totalHeight);
    expect(g.yOf(DateTime(2026, 3, 31)), 0);
    final span = g.spanOf(DateTime(2026, 3, 2, 9), DateTime(2026, 3, 2, 10));
    expect(span.height, 60);
    expect(span.top, g.yOf(DateTime(2026, 3, 2, 10)));
  });

  test('timeAt inverts yOf', () {
    for (final futureAtTop in [false, true]) {
      final g = geometry(futureAtTop: futureAtTop);
      for (final t in [
        DateTime(2026, 3, 1, 0, 0),
        DateTime(2026, 3, 4, 13, 45),
        DateTime(2026, 3, 30, 23, 59),
      ]) {
        expect(g.timeAt(g.yOf(t)), t, reason: '$t futureAtTop=$futureAtTop');
      }
    }
  });

  test('daysIn returns the days a band touches', () {
    final g = geometry();
    final r = g.daysIn(
      g.yOf(DateTime(2026, 3, 3, 20)),
      g.yOf(DateTime(2026, 3, 5, 2)),
    );
    expect(r.first, LocalDate(2026, 3, 3));
    expect(r.last, LocalDate(2026, 3, 5));
    final flipped = geometry(futureAtTop: true);
    final r2 = flipped.daysIn(
      flipped.yOf(DateTime(2026, 3, 5, 2)),
      flipped.yOf(DateTime(2026, 3, 3, 20)),
    );
    expect(r2.first, LocalDate(2026, 3, 3));
    expect(r2.last, LocalDate(2026, 3, 5));
  });

  test('task blocks and hour labels agree on a DST-change day', () {
    final g = geometry();
    // Spring forward is March 8: a 9:00 task must sit on the 9:00 label.
    final day = LocalDate(2026, 3, 9);
    expect(g.yOf(DateTime(2026, 3, 9, 9)), g.yOfDayHour(day, 9));
    final span = g.spanOf(DateTime(2026, 3, 8, 1), DateTime(2026, 3, 8, 4));
    expect(span.height, 3 * 60, reason: 'height follows the wall clock');
  }, skip: skipWithoutDst);
}
