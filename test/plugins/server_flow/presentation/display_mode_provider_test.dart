import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';

void main() {
  group('DisplayModeState', () {
    test('default state is individualDots + oneHour', () {
      const state = DisplayModeState();
      expect(state.mode, DisplayMode.individualDots);
      expect(state.clusterWindow, ClusterWindow.oneHour);
    });

    test('copyWith changes mode', () {
      const state = DisplayModeState();
      final updated = state.copyWith(mode: DisplayMode.hostSummary);
      expect(updated.mode, DisplayMode.hostSummary);
      expect(updated.clusterWindow, ClusterWindow.oneHour);
    });

    test('copyWith changes clusterWindow', () {
      const state = DisplayModeState();
      final updated = state.copyWith(clusterWindow: ClusterWindow.fifteenMin);
      expect(updated.mode, DisplayMode.individualDots);
      expect(updated.clusterWindow, ClusterWindow.fifteenMin);
    });

    test('copyWith preserves unmodified fields', () {
      const state = DisplayModeState(
        mode: DisplayMode.timeClusters,
        clusterWindow: ClusterWindow.thirtyMin,
      );

      final updatedMode = state.copyWith(mode: DisplayMode.hostSummary);
      expect(updatedMode.clusterWindow, ClusterWindow.thirtyMin);

      final updatedWindow = state.copyWith(
        clusterWindow: ClusterWindow.oneHour,
      );
      expect(updatedWindow.mode, DisplayMode.timeClusters);
    });
  });

  group('ClusterWindow', () {
    test('fifteenMin has correct duration and label', () {
      expect(ClusterWindow.fifteenMin.duration, const Duration(minutes: 15));
      expect(ClusterWindow.fifteenMin.label, '15 min');
    });

    test('thirtyMin has correct duration and label', () {
      expect(ClusterWindow.thirtyMin.duration, const Duration(minutes: 30));
      expect(ClusterWindow.thirtyMin.label, '30 min');
    });

    test('oneHour has correct duration and label', () {
      expect(ClusterWindow.oneHour.duration, const Duration(hours: 1));
      expect(ClusterWindow.oneHour.label, '1 hour');
    });
  });

  group('DisplayMode', () {
    test('has three values', () {
      expect(DisplayMode.values, hasLength(3));
    });

    test('enum values match expected names', () {
      expect(DisplayMode.values.map((m) => m.name), [
        'individualDots',
        'hostSummary',
        'timeClusters',
      ]);
    });
  });
}
