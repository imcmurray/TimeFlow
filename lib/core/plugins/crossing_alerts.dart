import 'package:timeflow/core/plugins/plugin_interface.dart';

/// Events whose start time passed the NOW line between [previous] and [now]
/// (start in `(previous, now]`) and haven't alerted yet.
List<TimelineEvent> detectCrossingEvents({
  required DateTime previous,
  required DateTime now,
  required Iterable<TimelineEvent> events,
  required Set<String> alreadyAlerted,
}) {
  if (!now.isAfter(previous)) return const []; // clock went backwards
  return [
    for (final event in events)
      if (!alreadyAlerted.contains(event.id) &&
          event.startTime.isAfter(previous) &&
          !event.startTime.isAfter(now))
        event,
  ];
}
