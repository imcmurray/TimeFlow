import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_providers.dart';
import 'package:timeflow/presentation/widgets/plugin_card.dart';

/// Screen for discovering and managing plugins.
class PluginMarketplaceScreen extends ConsumerStatefulWidget {
  const PluginMarketplaceScreen({super.key});

  @override
  ConsumerState<PluginMarketplaceScreen> createState() =>
      _PluginMarketplaceScreenState();
}

class _PluginMarketplaceScreenState
    extends ConsumerState<PluginMarketplaceScreen> {
  String _searchQuery = '';
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(pluginRegistryProvider);
    final allPlugins = registry.plugins;

    // Extract all unique tags
    final allTags = <String>{};
    for (final plugin in allPlugins) {
      allTags.addAll(plugin.metadata.tags);
    }
    final sortedTags = allTags.toList()..sort();

    // Filter plugins
    var filtered = allPlugins.where((plugin) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = plugin.name.toLowerCase().contains(q);
        final matchesDesc = plugin.metadata.shortDescription
            .toLowerCase()
            .contains(q);
        if (!matchesName && !matchesDesc) return false;
      }
      if (_selectedTag != null) {
        if (!plugin.metadata.tags.contains(_selectedTag)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search plugins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Tag chip bar
          if (sortedTags.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedTag == null,
                      onSelected: (_) {
                        setState(() => _selectedTag = null);
                      },
                    ),
                  ),
                  ...sortedTags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTag = selected ? tag : null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Plugin list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.extension_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No plugins found',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return PluginCard(plugin: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
