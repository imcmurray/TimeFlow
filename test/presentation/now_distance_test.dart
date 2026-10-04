import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';

void main() {
  final now = DateTime(2026, 10, 5, 10, 0);
  test('describes how far the view is from now', () {
    expect(
      describeDistanceFromNow(now, DateTime(2026, 10, 5, 10, 40)),
      '40 min ahead',
    );
    expect(
      describeDistanceFromNow(now, DateTime(2026, 10, 5, 7, 10)),
      '3 h back',
    );
    expect(
      describeDistanceFromNow(now, DateTime(2026, 10, 6, 15, 0)),
      '1 day ahead',
    );
    expect(
      describeDistanceFromNow(now, DateTime(2026, 10, 1, 9, 0)),
      '4 days back',
    );
    expect(describeDistanceFromNow(now, now), '1 min ahead');
  });
}
