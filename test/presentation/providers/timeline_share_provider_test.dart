import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/presentation/providers/timeline_share_provider.dart';

void main() {
  group('TimelineShareState', () {
    test('default hours are 0–24', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
      );
      expect(state.startHour, 0);
      expect(state.endHour, 24);
      expect(state.hideDetails, false);
      expect(state.selectedPluginIds, isEmpty);
    });

    test('copyWith changes startDate', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
      );
      final tomorrow = today.add(const Duration(days: 1));
      final updated = state.copyWith(startDate: tomorrow);
      expect(updated.startDate, tomorrow);
      expect(updated.endDate, today);
    });

    test('copyWith changes selectedPluginIds', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
        selectedPluginIds: {'a', 'b'},
      );
      final updated = state.copyWith(selectedPluginIds: {'a'});
      expect(updated.selectedPluginIds, {'a'});
    });

    test('copyWith changes hideDetails', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
      );
      final updated = state.copyWith(hideDetails: true);
      expect(updated.hideDetails, true);
    });

    test('copyWith changes time range', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
      );
      final updated = state.copyWith(startHour: 8, endHour: 18);
      expect(updated.startHour, 8);
      expect(updated.endHour, 18);
    });

    test('copyWith preserves unmodified fields', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final state = TimelineShareState(
        startDate: today,
        endDate: today,
        startHour: 6,
        endHour: 20,
        selectedPluginIds: {'server_flow'},
        hideDetails: true,
      );
      final updated = state.copyWith(startHour: 9);
      expect(updated.endHour, 20);
      expect(updated.selectedPluginIds, {'server_flow'});
      expect(updated.hideDetails, true);
      expect(updated.startDate, today);
    });
  });
}
