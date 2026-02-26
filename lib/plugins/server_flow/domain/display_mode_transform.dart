import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';

/// Pure transform that applies the selected display mode to a list of
/// [TimelineEvent]s, merging or clustering them as appropriate.
class DisplayModeTransform {
  DisplayModeTransform._();

  /// Applies the given [mode] to [events].
  ///
  /// - [DisplayMode.individualDots]: pass-through.
  /// - [DisplayMode.hostSummary]: merge consecutive events per host within 2h.
  /// - [DisplayMode.timeClusters]: group nearby events by [clusterWindow].
  static List<TimelineEvent> apply({
    required List<TimelineEvent> events,
    required DisplayMode mode,
    required ClusterWindow clusterWindow,
  }) {
    return switch (mode) {
      DisplayMode.individualDots => events,
      DisplayMode.hostSummary => _mergeByHost(events),
      DisplayMode.timeClusters => _clusterByTime(events, clusterWindow),
    };
  }

  static List<TimelineEvent> _mergeByHost(List<TimelineEvent> events) {
    if (events.isEmpty) return events;

    // Group events by host (groupKey)
    final groups = <String, List<TimelineEvent>>{};
    for (final event in events) {
      final key = event.groupKey ?? 'unknown';
      (groups[key] ??= []).add(event);
    }

    final result = <TimelineEvent>[];

    for (final entry in groups.entries) {
      final host = entry.key;
      final hostEvents = entry.value..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Walk sorted events: merge consecutive events whose gap <= 2 hours
      var barStart = hostEvents.first.startTime;
      var barEnd = _effectiveEnd(hostEvents.first);
      var barEvents = <TimelineEvent>[hostEvents.first];

      for (var i = 1; i < hostEvents.length; i++) {
        final event = hostEvents[i];
        final gap = event.startTime.difference(barEnd);

        if (gap <= const Duration(hours: 2)) {
          // Merge into current bar
          final eventEnd = _effectiveEnd(event);
          if (eventEnd.isAfter(barEnd)) barEnd = eventEnd;
          barEvents.add(event);
        } else {
          // Flush current bar and start a new one
          result.add(_createMergedBar(host, barStart, barEnd, barEvents));
          barStart = event.startTime;
          barEnd = _effectiveEnd(event);
          barEvents = [event];
        }
      }
      // Flush the last bar
      result.add(_createMergedBar(host, barStart, barEnd, barEvents));
    }

    // Sort result by startTime for consistent timeline ordering
    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  static DateTime _effectiveEnd(TimelineEvent event) {
    return event.endTime ?? event.startTime;
  }

  static TimelineEvent _createMergedBar(
    String host,
    DateTime start,
    DateTime end,
    List<TimelineEvent> events,
  ) {
    final count = events.length;
    return TimelineEvent(
      id: 'host_merge_${host}_${start.millisecondsSinceEpoch}',
      pluginId: 'server_flow',
      title: host,
      subtitle: '$count job${count == 1 ? '' : 's'}',
      startTime: start,
      endTime: end == start ? null : end,
      groupKey: host,
      categoryLabel: events.first.categoryLabel,
      color: events.first.color,
      metadata: {
        ...events.first.metadata,
        '_mergedEvents': events,
        '_mergedCount': count,
      },
    );
  }

  static List<TimelineEvent> _clusterByTime(
    List<TimelineEvent> events,
    ClusterWindow window,
  ) {
    if (events.isEmpty) return events;

    final sorted = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final result = <TimelineEvent>[];
    var clusterStart = sorted.first.startTime;
    var clusterEvents = <TimelineEvent>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final event = sorted[i];
      if (event.startTime.difference(clusterStart) <= window.duration) {
        clusterEvents.add(event);
      } else {
        result.add(_createCluster(clusterEvents, window));
        clusterStart = event.startTime;
        clusterEvents = [event];
      }
    }
    // Flush last cluster
    result.add(_createCluster(clusterEvents, window));

    return result;
  }

  static TimelineEvent _createCluster(
    List<TimelineEvent> events,
    ClusterWindow window,
  ) {
    if (events.length == 1) {
      final e = events.first;
      return e.copyWith(
        metadata: {
          ...e.metadata,
          '_mergedEvents': events,
          '_mergedCount': 1,
        },
      );
    }

    final count = events.length;
    // Midpoint of cluster
    final earliest = events.first.startTime;
    final latest = events.last.startTime;
    final midMs =
        earliest.millisecondsSinceEpoch +
        (latest.millisecondsSinceEpoch - earliest.millisecondsSinceEpoch) ~/ 2;
    final midpoint = DateTime.fromMillisecondsSinceEpoch(midMs);

    // Most frequent color
    final colorCounts = <int, int>{};
    for (final e in events) {
      if (e.color != null) {
        final key = e.color!.toARGB32();
        colorCounts[key] = (colorCounts[key] ?? 0) + 1;
      }
    }
    final dominantColor = colorCounts.isNotEmpty
        ? events
            .firstWhere(
              (e) =>
                  e.color != null &&
                  e.color!.toARGB32() ==
                      (colorCounts.entries.reduce(
                        (a, b) => a.value >= b.value ? a : b,
                      )).key,
            )
            .color
        : events.first.color;

    final timeRange = '${_formatTime(earliest)} – ${_formatTime(latest)}';

    return TimelineEvent(
      id: 'cluster_${earliest.millisecondsSinceEpoch}',
      pluginId: 'server_flow',
      title: '$count events',
      subtitle: timeRange,
      startTime: midpoint,
      endTime: null,
      groupKey: null,
      categoryLabel: null,
      color: dominantColor,
      metadata: {
        '_mergedEvents': events,
        '_mergedCount': count,
      },
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
