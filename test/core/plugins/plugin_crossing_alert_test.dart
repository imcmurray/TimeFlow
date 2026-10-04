import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// Pure-function extraction of the crossing detection logic from
/// TimelineViewState._checkEventCrossings for unit-testability.
///
/// Returns the IDs of events that should trigger a crossing alert.
List<String> detectCrossingEvents({
  required DateTime previous,
  required DateTime now,
  required List<TimelineEvent> events,
  required Set<String> alreadyAlerted,
}) {
  final triggered = <String>[];
  for (final event in events) {
    if (alreadyAlerted.contains(event.id)) continue;

    // Event crosses NOW if startTime is in (previous, now]
    if (event.startTime.isAfter(previous) && !event.startTime.isAfter(now)) {
      triggered.add(event.id);
    }
  }
  return triggered;
}

void main() {
  group('Now-line crossing detection', () {
    TimelineEvent _makeEvent(String id, DateTime startTime) {
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 500));

      final triggered = detectCrossingEvents(
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 1));

      final triggered = detectCrossingEvents(
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0));

      final triggered = detectCrossingEvents(
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 9, 59, 59));

      final triggered = detectCrossingEvents(
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 2));

      final triggered = detectCrossingEvents(
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
      final event = _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 500));

      final triggered = detectCrossingEvents(
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
        _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 200)),
        _makeEvent('e2', DateTime(2026, 2, 26, 10, 0, 0, 800)),
        _makeEvent('e3', DateTime(2026, 2, 26, 10, 0, 2)), // after now
      ];

      final triggered = detectCrossingEvents(
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
        _makeEvent('e1', DateTime(2026, 2, 26, 10, 0, 0, 200)),
        _makeEvent('e2', DateTime(2026, 2, 26, 10, 0, 0, 800)),
      ];

      final triggered = detectCrossingEvents(
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

      final triggered = detectCrossingEvents(
        previous: previous,
        now: now,
        events: [],
        alreadyAlerted: {},
      );

      expect(triggered, isEmpty);
    });
  });
}
