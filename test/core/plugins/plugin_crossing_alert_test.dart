import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/core/plugins/crossing_alerts.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';

List<String> crossingIds({
  required DateTime previous,
  required DateTime now,
  required List<TimelineEvent> events,
  required Set<String> alreadyAlerted,
}) => detectCrossingEvents(
  previous: previous,
  now: now,
  events: events,
  alreadyAlerted: alreadyAlerted,
).map((e) => e.id).toList();

void main() {
  group('Now-line crossing detection', () {
    TimelineEvent makeEvent(String id, DateTime startTime) {
      return TimelineEvent(
        id: id,
        pluginId: 'test-plugin',
        title: 'Event $id',
        startTime: startTime,
      );
    }

    test('event with startTime in (previous, now] triggers alert', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 500));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {},
      );

      expect(triggered, ['e1']);
    });

    test('event with startTime exactly at now triggers alert', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 1));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {},
      );

      expect(triggered, ['e1']);
    });

    test('event with startTime exactly at previous does NOT trigger', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {},
      );

      expect(triggered, isEmpty);
    });

    test('event with startTime before previous does NOT trigger', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 9, 59, 59));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {},
      );

      expect(triggered, isEmpty);
    });

    test('event with startTime after now does NOT trigger', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 2));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {},
      );

      expect(triggered, isEmpty);
    });

    test('already-alerted event ID is not re-alerted', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final event = makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 500));

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [event],
        alreadyAlerted: {'e1'},
      );

      expect(triggered, isEmpty);
    });

    test('multiple events in range all trigger', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final events = [
        makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 200)),
        makeEvent('e2', DateTime(2026, 2, 26, 10, 0, 0, 800)),
        makeEvent('e3', DateTime(2026, 2, 26, 10, 0, 2)), // after now
      ];

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: events,
        alreadyAlerted: {},
      );

      expect(triggered, ['e1', 'e2']);
    });

    test('mix of alerted and new events filters correctly', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);
      final events = [
        makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 200)),
        makeEvent('e2', DateTime(2026, 2, 26, 10, 0, 0, 800)),
      ];

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: events,
        alreadyAlerted: {'e1'},
      );

      expect(triggered, ['e2']);
    });

    test('empty events list returns no triggers', () {
      final previous = DateTime(2026, 2, 26, 10, 0, 0);
      final now = DateTime(2026, 2, 26, 10, 0, 1);

      final triggered = crossingIds(
        previous: previous,
        now: now,
        events: [],
        alreadyAlerted: {},
      );

      expect(triggered, isEmpty);
    });
  });
}
