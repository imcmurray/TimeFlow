import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/plugin_providers.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';

/// A per-plugin on/off map persisted in shared preferences.
abstract class _PluginFlagsNotifier extends Notifier<Map<String, bool>> {
  String get keyPrefix;
  bool get defaultValue;

  late SharedPreferences _prefs;

  @override
  Map<String, bool> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final plugin in ref.watch(pluginRegistryProvider).plugins)
        plugin.id: _prefs.getBool('$keyPrefix${plugin.id}') ?? defaultValue,
    };
  }

  bool isEnabled(String pluginId) => state[pluginId] ?? defaultValue;

  void setEnabled(String pluginId, bool enabled) {
    state = {...state, pluginId: enabled};
    _prefs.setBool('$keyPrefix$pluginId', enabled);
  }
}

/// Which plugins are switched on. Plugins are opt-in: all start off.
class PluginStateNotifier extends _PluginFlagsNotifier {
  @override
  String get keyPrefix => 'plugin_enabled_';

  @override
  bool get defaultValue => false;
}

final pluginStateProvider =
    NotifierProvider<PluginStateNotifier, Map<String, bool>>(
      PluginStateNotifier.new,
    );

/// The plugins that are switched on.
final enabledPluginsProvider = Provider<List<TimeFlowPlugin>>((ref) {
  final states = ref.watch(pluginStateProvider);
  return [
    for (final plugin in ref.watch(pluginRegistryProvider).plugins)
      if (states[plugin.id] ?? false) plugin,
  ];
});

/// Whether each plugin alerts when its events reach the NOW line.
class PluginCrossingAlertNotifier extends _PluginFlagsNotifier {
  @override
  String get keyPrefix => 'plugin_crossing_alert_';

  @override
  bool get defaultValue => true;
}

final pluginCrossingAlertStateProvider =
    NotifierProvider<PluginCrossingAlertNotifier, Map<String, bool>>(
      PluginCrossingAlertNotifier.new,
    );
