import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';
import 'package:timeflow/presentation/widgets/simple_day_divider.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';

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

  testWidgets('day dividers stay behind a task that spans midnight (#35)', (
    tester,
  ) async {
    final container = await pumpApp(tester, const TimelineScreen());
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    await tester.runAsync(
      () => container
          .read(taskServiceProvider)
          .create(
            Task(
              id: 'x',
              title: 'Night shift',
              startTime: midnight.subtract(const Duration(hours: 1)),
              endTime: midnight.add(const Duration(minutes: 30)),
              createdAt: now,
              updatedAt: now,
            ),
          ),
    );
    await settle(tester);
    // Show the midnight boundary the task crosses.
    tester
        .state<TimelineViewState>(find.byType(TimelineView))
        .scrollToDate(midnight, animated: false);
    await settle(tester);

    final card = find.byType(TaskCard);
    expect(card, findsOneWidget);
    // In a Stack later children paint on top, so every divider must come
    // before the card in the element tree.
    final elements = tester.allElements.toList();
    final cardIndex = elements.indexOf(tester.element(card));
    for (final divider in tester.elementList(find.byType(SimpleDayDivider))) {
      expect(elements.indexOf(divider), lessThan(cardIndex));
    }
  });
}
