import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// Central registry for all loaded [TimeFlowPlugin] instances.
///
/// Plugins register themselves here at app startup. The registry provides
/// aggregated provider overrides and UI extension lookups.
class PluginRegistry {
  final List<TimeFlowPlugin> _plugins = [];

  /// All currently registered plugins.
  List<TimeFlowPlugin> get plugins => List.unmodifiable(_plugins);

  /// Register a plugin. Throws if a plugin with the same [id] already exists.
  void register(TimeFlowPlugin plugin) {
    if (_plugins.any((p) => p.id == plugin.id)) {
      throw StateError('Plugin with id "${plugin.id}" is already registered');
    }
    _plugins.add(plugin);
  }

  /// Unregister a plugin by its [pluginId].
  void unregister(String pluginId) {
    _plugins.removeWhere((p) => p.id == pluginId);
  }

  /// Look up a plugin by its [id], or null if not found.
  TimeFlowPlugin? getById(String id) {
    for (final plugin in _plugins) {
      if (plugin.id == id) return plugin;
    }
    return null;
  }

  /// Aggregates [providerOverrides] from all registered plugins.
  List<Object> get allProviderOverrides {
    return _plugins.expand((p) => p.providerOverrides).toList();
  }

  /// Returns all [UIExtensionDescriptor]s matching the given [extensionPoint].
  List<UIExtensionDescriptor> getExtensions(UIExtensionPoint extensionPoint) {
    return _plugins
        .expand((p) => p.uiExtensions)
        .where((ext) => ext.extensionPoint == extensionPoint)
        .toList();
  }
}
