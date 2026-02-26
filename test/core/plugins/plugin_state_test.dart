import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/core/plugins/plugin_registry.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';

import 'mock_plugin.dart';

void main() {
  late PluginRegistry registry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registry = PluginRegistry();
    registry.register(MockPlugin(id: 'alpha', name: 'Alpha'));
    registry.register(MockPlugin(id: 'beta', name: 'Beta'));
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        pluginRegistryProvider.overrideWithValue(registry),
      ],
    );
  }

  group('PluginStateNotifier', () {
    test('defaults all plugins to enabled', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Read the provider to trigger build
      container.read(pluginStateProvider);
      // Initial synchronous build returns empty; wait for async load
      await Future<void>.delayed(Duration.zero);

      final loaded = container.read(pluginStateProvider);
      expect(loaded['alpha'], isTrue);
      expect(loaded['beta'], isTrue);
    });

    test('setEnabled persists and updates state', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      container.read(pluginStateProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(pluginStateProvider.notifier)
          .setEnabled('alpha', false);
      expect(container.read(pluginStateProvider)['alpha'], isFalse);
      expect(container.read(pluginStateProvider)['beta'], isTrue);
    });

    test('isEnabled returns true for unknown plugin', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(pluginStateProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(pluginStateProvider.notifier).isEnabled('unknown'),
        isTrue,
      );
    });
  });

  group('enabledPluginsProvider', () {
    test('returns all plugins when all enabled', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(pluginStateProvider);
      await Future<void>.delayed(Duration.zero);

      final enabled = container.read(enabledPluginsProvider);
      expect(enabled, hasLength(2));
    });

    test('filters out disabled plugins', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(pluginStateProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(pluginStateProvider.notifier)
          .setEnabled('alpha', false);

      final enabled = container.read(enabledPluginsProvider);
      expect(enabled, hasLength(1));
      expect(enabled.first.id, 'beta');
    });
  });
}
