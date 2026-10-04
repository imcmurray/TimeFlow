import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/plugins/server_flow/domain/display_mode_transform.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';

TimelineEvent _event({
  required String id,
  required DateTime startTime,
  DateTime? endTime,
  String host = 'web-01',
  String command = '/usr/bin/backup.sh',
  String user = 'root',
  Color? color,
}) {
  return TimelineEvent(
    id: id,
    pluginId: 'server_flow',
    title: command,
    subtitle: host,
    startTime: startTime,
    endTime: endTime,
    groupKey: host,
    categoryLabel: 'backup',
    color: color ?? Colors.blue,
    metadata: {
      'host': host,
      'command': command,
      'user': user,
    },
  );
}

void main() {
  group('DisplayModeTransform', () {
    group('individualDots', () {
      test('passes events through unchanged', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 9, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.individualDots,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, same(events));
      });

      test('empty list returns empty', () {
        final result = DisplayModeTransform.apply(
          events: [],
          mode: DisplayMode.individualDots,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, isEmpty);
      });
    });

    group('hostSummary', () {
      test('single host all within 2h merges into one bar', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 30)),
          _event(id: '3', startTime: DateTime(2025, 1, 15, 9, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(1));
        expect(result.first.metadata['_mergedCount'], 3);
        expect(result.first.startTime, DateTime(2025, 1, 15, 8, 0));
        expect(result.first.title, 'web-01');
        expect(result.first.subtitle, '3 jobs');
      });

      test('gap > 2h creates two bars', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 30)),
          _event(id: '3', startTime: DateTime(2025, 1, 15, 14, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(2));
        expect(result[0].metadata['_mergedCount'], 2);
        expect(result[1].metadata['_mergedCount'], 1);
      });

      test('multiple hosts produce separate bars', () {
        final events = [
          _event(
              id: '1', startTime: DateTime(2025, 1, 15, 8, 0), host: 'web-01'),
          _event(
              id: '2', startTime: DateTime(2025, 1, 15, 8, 0), host: 'web-02'),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(2));
        final hosts = result.map((e) => e.groupKey).toSet();
        expect(hosts, containsAll(['web-01', 'web-02']));
      });

      test('single event passes through with mergedCount 1', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(1));
        expect(result.first.metadata['_mergedCount'], 1);
        expect(result.first.subtitle, '1 job');
      });

      test('empty list returns empty', () {
        final result = DisplayModeTransform.apply(
          events: [],
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, isEmpty);
      });

      test('merged bar has correct startTime/endTime span', () {
        final events = [
          _event(
            id: '1',
            startTime: DateTime(2025, 1, 15, 8, 0),
            endTime: DateTime(2025, 1, 15, 8, 30),
          ),
          _event(
            id: '2',
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 10, 0),
          ),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(1));
        expect(result.first.startTime, DateTime(2025, 1, 15, 8, 0));
        expect(result.first.endTime, DateTime(2025, 1, 15, 10, 0));
      });

      test('metadata contains original events', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 30)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.hostSummary,
          clusterWindow: ClusterWindow.oneHour,
        );

        final merged = result.first.metadata['_mergedEvents'] as List;
        expect(merged, hasLength(2));
        expect((merged[0] as TimelineEvent).id, '1');
        expect((merged[1] as TimelineEvent).id, '2');
      });
    });

    group('timeClusters', () {
      test('events within window merge into one cluster', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 10)),
          _event(id: '3', startTime: DateTime(2025, 1, 15, 8, 20)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.thirtyMin,
        );

        expect(result, hasLength(1));
        expect(result.first.metadata['_mergedCount'], 3);
        expect(result.first.title, '3 events');
      });

      test('events across window boundary create two clusters', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 10)),
          _event(id: '3', startTime: DateTime(2025, 1, 15, 10, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.thirtyMin,
        );

        expect(result, hasLength(2));
        expect(result[0].metadata['_mergedCount'], 2);
        expect(result[1].metadata['_mergedCount'], 1);
      });

      test('midpoint is correct for multi-event cluster', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 20)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.thirtyMin,
        );

        // Midpoint of 8:00 and 8:20 = 8:10
        expect(result.first.startTime, DateTime(2025, 1, 15, 8, 10));
      });

      test('dominant color is most frequent', () {
        final events = [
          _event(
              id: '1',
              startTime: DateTime(2025, 1, 15, 8, 0),
              color: Colors.red),
          _event(
              id: '2',
              startTime: DateTime(2025, 1, 15, 8, 5),
              color: Colors.blue),
          _event(
              id: '3',
              startTime: DateTime(2025, 1, 15, 8, 10),
              color: Colors.blue),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.thirtyMin,
        );

        expect(result.first.color, Colors.blue);
      });

      test('different window sizes produce different clustering', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 20)),
          _event(id: '3', startTime: DateTime(2025, 1, 15, 8, 40)),
        ];

        final result15 = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.fifteenMin,
        );

        final result60 = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.oneHour,
        );

        // 15min window: first event alone, then second, then third (each >15min apart)
        expect(result15.length, greaterThan(result60.length));
        // 1hr window: all within 1hr → one cluster
        expect(result60, hasLength(1));
      });

      test('single event passes through with mergedCount 1', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, hasLength(1));
        expect(result.first.metadata['_mergedCount'], 1);
        expect(result.first.id, '1');
      });

      test('empty list returns empty', () {
        final result = DisplayModeTransform.apply(
          events: [],
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result, isEmpty);
      });

      test('cluster endTime is null (renders as dot)', () {
        final events = [
          _event(id: '1', startTime: DateTime(2025, 1, 15, 8, 0)),
          _event(id: '2', startTime: DateTime(2025, 1, 15, 8, 10)),
        ];

        final result = DisplayModeTransform.apply(
          events: events,
          mode: DisplayMode.timeClusters,
          clusterWindow: ClusterWindow.oneHour,
        );

        expect(result.first.endTime, isNull);
      });
    });
  });
}
