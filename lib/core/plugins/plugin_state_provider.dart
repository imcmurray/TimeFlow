import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';

/// Manages enabled/disabled state for each plugin, persisted via SharedPreferences.
class PluginStateNotifier extends Notifier<Map<String, bool>> {
  static const _keyPrefix = 'plugin_enabled_';

  SharedPreferences? _prefs;

  @override
  Map<String, bool> build() {
    _loadState();
    return {};
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    final registry = ref.read(pluginRegistryProvider);
    final loaded = <String, bool>{};
    for (final plugin in registry.plugins) {
      final key = '$_keyPrefix${plugin.id}';
      // Default to enabled on first encounter
      loaded[plugin.id] = _prefs!.getBool(key) ?? true;
    }
    state = loaded;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns whether the given plugin is enabled. Defaults to true.
  bool isEnabled(String pluginId) => state[pluginId] ?? true;

  /// Toggle a plugin's enabled state.
  Future<void> setEnabled(String pluginId, bool enabled) async {
    state = {...state, pluginId: enabled};
    await _ensurePrefs();
    await _prefs!.setBool('$_keyPrefix$pluginId', enabled);
  }
}

/// Provides the enabled/disabled state map for all plugins.
final pluginStateProvider =
    NotifierProvider<PluginStateNotifier, Map<String, bool>>(
  PluginStateNotifier.new,
);

/// Derived provider that returns only the currently-enabled plugin instances.
final enabledPluginsProvider = Provider<List<TimeFlowPlugin>>((ref) {
  final registry = ref.watch(pluginRegistryProvider);
  final pluginStates = ref.watch(pluginStateProvider);
  return registry.plugins.where((plugin) {
    return pluginStates[plugin.id] ?? true;
  }).toList();
});

/// Manages per-plugin crossing alert enabled/disabled state, persisted via SharedPreferences.
class PluginCrossingAlertNotifier extends Notifier<Map<String, bool>> {
  static const _keyPrefix = 'plugin_crossing_alert_';

  SharedPreferences? _prefs;

  @override
  Map<String, bool> build() {
    _loadState();
    return {};
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    final registry = ref.read(pluginRegistryProvider);
    final loaded = <String, bool>{};
    for (final plugin in registry.plugins) {
      final key = '$_keyPrefix${plugin.id}';
      loaded[plugin.id] = _prefs!.getBool(key) ?? true;
    }
    state = loaded;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns whether crossing alerts are enabled for the given plugin. Defaults to true.
  bool isEnabled(String pluginId) => state[pluginId] ?? true;

  /// Toggle a plugin's crossing alert state.
  Future<void> setEnabled(String pluginId, bool enabled) async {
    state = {...state, pluginId: enabled};
    await _ensurePrefs();
    await _prefs!.setBool('$_keyPrefix$pluginId', enabled);
  }
}

/// Provides the crossing alert enabled/disabled state map for all plugins.
final pluginCrossingAlertStateProvider =
    NotifierProvider<PluginCrossingAlertNotifier, Map<String, bool>>(
  PluginCrossingAlertNotifier.new,
);
