import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/core/plugins/plugin_providers.dart';
import 'package:timeflow/core/plugins/plugin_registry.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';

import 'mock_plugin.dart';

void main() {
  late PluginRegistry registry;

  Future<ProviderContainer> container([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        pluginRegistryProvider.overrideWithValue(registry),
        sharedPreferencesProvider.overrideWithValue(p),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    registry = PluginRegistry()
      ..register(MockPlugin(id: 'alpha', name: 'Alpha'))
      ..register(MockPlugin(id: 'beta', name: 'Beta'));
  });

  test('plugins are opt-in: all start off', () async {
    final c = await container();
    expect(c.read(pluginStateProvider), {'alpha': false, 'beta': false});
    expect(c.read(enabledPluginsProvider), isEmpty);
  });

  test('enabling a plugin persists it', () async {
    final c = await container();
    c.read(pluginStateProvider.notifier).setEnabled('alpha', true);
    expect(c.read(enabledPluginsProvider).map((p) => p.id), ['alpha']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('plugin_enabled_alpha'), isTrue);
  });

  test('reads saved choices', () async {
    final c = await container({'plugin_enabled_beta': true});
    expect(c.read(enabledPluginsProvider).map((p) => p.id), ['beta']);
  });

  test('unknown plugins are off', () async {
    final c = await container();
    expect(c.read(pluginStateProvider.notifier).isEnabled('nope'), isFalse);
  });

  test('crossing alerts default on per plugin', () async {
    final c = await container();
    expect(c.read(pluginCrossingAlertStateProvider)['alpha'], isTrue);
  });
}
