import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';
import 'package:cron_timeflow/presentation/screens/timeline_share_screen.dart';

/// Detail screen for a single plugin showing metadata and configuration.
class PluginDetailScreen extends ConsumerWidget {
  final String pluginId;

  const PluginDetailScreen({super.key, required this.pluginId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(pluginRegistryProvider);
    final plugin = registry.getById(pluginId);

    if (plugin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plugin')),
        body: const Center(child: Text('Plugin not found')),
      );
    }

    final meta = plugin.metadata;
    final isEnabled = ref.watch(pluginStateProvider)[pluginId] ?? true;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = meta.accentColor ?? colorScheme.primary;

    // Check if this plugin can produce timeline events (use today as a probe).
    final now = DateTime.now();
    final todayRange = DateRange(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    final hasEvents = plugin.eventsProviderFor(todayRange) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(plugin.name),
        actions: [
          if (hasEvents)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share timeline',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        TimelineShareScreen(initialPluginId: plugin.id),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero: large icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                meta.icon,
                color: accentColor,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name and version
          Center(
            child: Text(
              plugin.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v${meta.version} by ${meta.author}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 20),

          // Enable/disable toggle
          SwitchListTile(
            title: const Text('Enabled'),
            subtitle:
                Text(isEnabled ? 'Plugin is active' : 'Plugin is disabled'),
            value: isEnabled,
            onChanged: (value) {
              ref
                  .read(pluginStateProvider.notifier)
                  .setEnabled(pluginId, value);
            },
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Full description
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            meta.fullDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Data sources
          if (plugin.dataSources.isNotEmpty) ...[
            Text(
              'Data Sources',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...plugin.dataSources.map((ds) => ListTile(
                  leading:
                      Icon(Icons.storage, color: colorScheme.onSurfaceVariant),
                  title: Text(ds.label),
                  subtitle: Text(ds.description),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 12),
          ],

          // Inline configuration section
          if (meta.configSectionBuilder != null) ...[
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: isEnabled ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !isEnabled,
                child: meta.configSectionBuilder!(context, ref),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Tags
          if (meta.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: meta.tags.map((tag) {
                return Chip(label: Text(tag));
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
