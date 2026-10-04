import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';

/// Base class for notifiers that manage a per-plugin boolean state map
/// persisted via SharedPreferences.
abstract class _PluginBoolMapNotifier extends Notifier<Map<String, bool>> {
  String get keyPrefix;
  bool get defaultValue;

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
      final key = '$keyPrefix${plugin.id}';
      loaded[plugin.id] = _prefs!.getBool(key) ?? defaultValue;
    }
    state = loaded;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns the boolean value for the given plugin. Falls back to [defaultValue].
  bool isEnabled(String pluginId) => state[pluginId] ?? defaultValue;

  /// Set the boolean value for a plugin and persist it.
  Future<void> setEnabled(String pluginId, bool enabled) async {
    state = {...state, pluginId: enabled};
    await _ensurePrefs();
    await _prefs!.setBool('$keyPrefix$pluginId', enabled);
  }
}

/// Manages enabled/disabled state for each plugin, persisted via SharedPreferences.
class PluginStateNotifier extends _PluginBoolMapNotifier {
  @override
  String get keyPrefix => 'plugin_enabled_';

  @override
  bool get defaultValue => true;
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
class PluginCrossingAlertNotifier extends _PluginBoolMapNotifier {
  @override
  String get keyPrefix => 'plugin_crossing_alert_';

  @override
  bool get defaultValue => true;
}

/// Provides the crossing alert enabled/disabled state map for all plugins.
final pluginCrossingAlertStateProvider =
    NotifierProvider<PluginCrossingAlertNotifier, Map<String, bool>>(
  PluginCrossingAlertNotifier.new,
);
