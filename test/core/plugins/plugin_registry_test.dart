import 'package:flutter_test/flutter_test.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_registry.dart';
import 'package:cron_timeflow/presentation/providers/task_provider.dart'
    show DateRange;

import 'mock_plugin.dart';

void main() {
  late PluginRegistry registry;

  setUp(() {
    registry = PluginRegistry();
  });

  group('PluginRegistry', () {
    test('starts empty', () {
      expect(registry.plugins, isEmpty);
    });

    test('register adds a plugin', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      expect(registry.plugins, hasLength(1));
      expect(registry.plugins.first.id, 'test');
    });

    test('register throws on duplicate id', () {
      final plugin1 = MockPlugin(id: 'test', name: 'Test 1');
      final plugin2 = MockPlugin(id: 'test', name: 'Test 2');

      registry.register(plugin1);
      expect(() => registry.register(plugin2), throwsStateError);
    });

    test('unregister removes a plugin', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);
      registry.unregister('test');

      expect(registry.plugins, isEmpty);
    });

    test('unregister is no-op for unknown id', () {
      registry.unregister('nonexistent');
      expect(registry.plugins, isEmpty);
    });

    test('getById returns plugin when found', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      expect(registry.getById('test'), same(plugin));
    });

    test('getById returns null when not found', () {
      expect(registry.getById('nonexistent'), isNull);
    });

    test('plugins list is unmodifiable', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      expect(
        () => registry.plugins.add(MockPlugin(id: 'hack', name: 'Hack')),
        throwsUnsupportedError,
      );
    });

    test('allProviderOverrides aggregates from all plugins', () {
      final plugin1 = MockPlugin(id: 'p1', name: 'Plugin 1');
      final plugin2 = MockPlugin(id: 'p2', name: 'Plugin 2');
      registry.register(plugin1);
      registry.register(plugin2);

      // MockPlugins have empty overrides, so aggregate should be empty
      expect(registry.allProviderOverrides, isEmpty);
    });

    test('getExtensions filters by extension point', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      // MockPlugin has no UI extensions
      expect(
        registry.getExtensions(UIExtensionPoint.timelineLayer),
        isEmpty,
      );
    });

    test('register after unregister allows re-registration', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);
      registry.unregister('test');

      final plugin2 = MockPlugin(id: 'test', name: 'Test Plugin v2');
      registry.register(plugin2);

      expect(registry.plugins, hasLength(1));
      expect(registry.plugins.first.name, 'Test Plugin v2');
    });
  });

  group('Plugin metadata', () {
    test('metadata is accessible via registry', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      final fetched = registry.getById('test')!;
      expect(fetched.metadata.shortDescription, isNotEmpty);
      expect(fetched.metadata.author, 'Test');
      expect(fetched.metadata.version, '0.0.1');
      expect(fetched.metadata.tags, contains('test'));
    });

    test('eventsProviderFor returns null by default', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      registry.register(plugin);

      final range = DateRange(DateTime(2025, 1, 1), DateTime(2025, 1, 2));
      expect(plugin.eventsProviderFor(range), isNull);
    });

    test('onEventTap returns null by default', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      expect(plugin.onEventTap, isNull);
    });
  });

  group('MockPlugin lifecycle', () {
    test('initialize sets initialized flag', () async {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      expect(plugin.initialized, isFalse);

      await plugin.initialize();
      expect(plugin.initialized, isTrue);
    });

    test('dispose sets disposed flag', () async {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      expect(plugin.disposed, isFalse);

      await plugin.dispose();
      expect(plugin.disposed, isTrue);
    });

    test('eventMapper produces TimelineEvent', () {
      final plugin = MockPlugin(id: 'test', name: 'Test Plugin');
      final event = plugin.eventMapper('hello');

      expect(event.pluginId, 'test');
      expect(event.title, 'hello');
    });
  });

  group('TimelineEvent', () {
    test('duration is zero when no endTime', () {
      final event = TimelineEvent(
        id: 'e1',
        pluginId: 'p1',
        title: 'Test',
        startTime: DateTime(2025, 1, 1, 10, 0),
      );
      expect(event.duration, Duration.zero);
    });

    test('duration calculated from startTime to endTime', () {
      final event = TimelineEvent(
        id: 'e1',
        pluginId: 'p1',
        title: 'Test',
        startTime: DateTime(2025, 1, 1, 10, 0),
        endTime: DateTime(2025, 1, 1, 11, 30),
      );
      expect(event.duration, const Duration(hours: 1, minutes: 30));
    });

    test('copyWith creates a modified copy', () {
      final event = TimelineEvent(
        id: 'e1',
        pluginId: 'p1',
        title: 'Original',
        startTime: DateTime(2025, 1, 1, 10, 0),
      );
      final copy = event.copyWith(title: 'Modified');

      expect(copy.id, 'e1');
      expect(copy.title, 'Modified');
      expect(event.title, 'Original');
    });
  });
}
