import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';

import '../helpers/pump_app.dart';

ScrollPosition _timelinePosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  testWidgets(
    'scrolling away with a mouse wheel stays put instead of snapping back '
    'to NOW',
    (tester) async {
      await pumpApp(tester, const TimelineScreen());
      await settle(tester);
      final start = _timelinePosition(tester).pixels;

      // A mouse-wheel scroll carries no drag details, which is how the old
      // code missed it and kept following NOW.
      final center = tester.getCenter(find.byType(Scrollable).first);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(center);
      for (var i = 0; i < 10; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, -400)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      final scrolled = _timelinePosition(tester).pixels;
      expect((scrolled - start).abs(), greaterThan(1000));

      // Past several follow-NOW ticks (every 5 s).
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 6));
      expect(_timelinePosition(tester).pixels, closeTo(scrolled, 1));
    },
  );
}
