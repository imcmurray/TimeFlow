import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/filter_provider.dart';

void main() {
  group('ServerFlowFilter', () {
    test('default filter is not active', () {
      const filter = ServerFlowFilter();
      expect(filter.isActive, isFalse);
    });

    test('filter with selected hosts is active', () {
      const filter = ServerFlowFilter(selectedHosts: {'web-01'});
      expect(filter.isActive, isTrue);
    });

    test('filter with selected categories is active', () {
      const filter = ServerFlowFilter(selectedCategories: {'backup'});
      expect(filter.isActive, isTrue);
    });

    test('filter with selected users is active', () {
      const filter = ServerFlowFilter(selectedUsers: {'root'});
      expect(filter.isActive, isTrue);
    });

    test('filter with time range is active', () {
      const filter = ServerFlowFilter(timeRangeStartHour: 9.0);
      expect(filter.isActive, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      const filter = ServerFlowFilter(
        selectedHosts: {'web-01'},
        selectedCategories: {'backup'},
      );
      final updated = filter.copyWith(selectedUsers: {'root'});
      expect(updated.selectedHosts, {'web-01'});
      expect(updated.selectedCategories, {'backup'});
      expect(updated.selectedUsers, {'root'});
    });

    test('copyWith can clear time range with null factory', () {
      const filter = ServerFlowFilter(
        timeRangeStartHour: 9.0,
        timeRangeEndHour: 17.0,
      );
      final updated = filter.copyWith(
        timeRangeStartHour: () => null,
        timeRangeEndHour: () => null,
      );
      expect(updated.timeRangeStartHour, isNull);
      expect(updated.timeRangeEndHour, isNull);
      expect(updated.isActive, isFalse);
    });
  });

  group('ServerFlowFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty filter', () {
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.isActive, isFalse);
      expect(filter.selectedHosts, isEmpty);
      expect(filter.selectedCategories, isEmpty);
      expect(filter.selectedUsers, isEmpty);
      expect(filter.timeRangeStartHour, isNull);
      expect(filter.timeRangeEndHour, isNull);
    });

    test('toggleHost adds host when not present', () {
      container.read(serverFlowFilterProvider.notifier).toggleHost('web-01');
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.selectedHosts, contains('web-01'));
      expect(filter.isActive, isTrue);
    });

    test('toggleHost removes host when already present', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.toggleHost('web-01');
      notifier.toggleHost('web-01');
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.selectedHosts, isEmpty);
      expect(filter.isActive, isFalse);
    });

    test('toggleCategory adds and removes', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.toggleCategory('backup');
      expect(
        container.read(serverFlowFilterProvider).selectedCategories,
        contains('backup'),
      );
      notifier.toggleCategory('backup');
      expect(
        container.read(serverFlowFilterProvider).selectedCategories,
        isEmpty,
      );
    });

    test('toggleUser adds and removes', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.toggleUser('root');
      expect(
        container.read(serverFlowFilterProvider).selectedUsers,
        contains('root'),
      );
      notifier.toggleUser('root');
      expect(container.read(serverFlowFilterProvider).selectedUsers, isEmpty);
    });

    test('setTimeRange sets start and end hours', () {
      container.read(serverFlowFilterProvider.notifier).setTimeRange(9.0, 17.0);
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.timeRangeStartHour, 9.0);
      expect(filter.timeRangeEndHour, 17.0);
      expect(filter.isActive, isTrue);
    });

    test('clearTimeRange removes time range', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.setTimeRange(9.0, 17.0);
      notifier.clearTimeRange();
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.timeRangeStartHour, isNull);
      expect(filter.timeRangeEndHour, isNull);
    });

    test('reset clears all filters', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.toggleHost('web-01');
      notifier.toggleCategory('backup');
      notifier.toggleUser('root');
      notifier.setTimeRange(9.0, 17.0);
      expect(container.read(serverFlowFilterProvider).isActive, isTrue);

      notifier.reset();
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.isActive, isFalse);
      expect(filter.selectedHosts, isEmpty);
      expect(filter.selectedCategories, isEmpty);
      expect(filter.selectedUsers, isEmpty);
      expect(filter.timeRangeStartHour, isNull);
      expect(filter.timeRangeEndHour, isNull);
    });

    test('multiple hosts can be selected', () {
      final notifier = container.read(serverFlowFilterProvider.notifier);
      notifier.toggleHost('web-01');
      notifier.toggleHost('db-01');
      notifier.toggleHost('cache-01');
      final filter = container.read(serverFlowFilterProvider);
      expect(filter.selectedHosts, {'web-01', 'db-01', 'cache-01'});
    });
  });
}
