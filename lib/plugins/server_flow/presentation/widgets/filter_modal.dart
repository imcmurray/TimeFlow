import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/filter_provider.dart';

/// Shows the ServerFlow filter modal as a bottom sheet.
void showFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) =>
          FilterModalContent(scrollController: scrollController),
    ),
  );
}

/// Content of the filter modal bottom sheet.
class FilterModalContent extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const FilterModalContent({super.key, required this.scrollController});

  @override
  ConsumerState<FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<FilterModalContent> {
  String _userSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(serverFlowFilterProvider);
    final hostsAsync = ref.watch(availableHostsProvider);
    final categoriesAsync = ref.watch(availableCategoriesProvider);
    final usersAsync = ref.watch(availableUsersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withAlpha(100),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Text(
                'Filter Events',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (filter.isActive)
                TextButton(
                  onPressed: () {
                    ref.read(serverFlowFilterProvider.notifier).reset();
                  },
                  child: const Text('Reset'),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(),
        // Scrollable content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Hosts section
              _SectionHeader(title: 'Hosts'),
              hostsAsync.when(
                data: (hosts) => _ChipGroup(
                  labels: hosts,
                  selected: filter.selectedHosts,
                  onToggle: (host) {
                    ref
                        .read(serverFlowFilterProvider.notifier)
                        .toggleHost(host);
                  },
                ),
                loading: () => const _LoadingChips(),
                error: (_, _) => const Text('Failed to load hosts'),
              ),
              const SizedBox(height: 16),

              // Categories section
              _SectionHeader(title: 'Categories'),
              categoriesAsync.when(
                data: (categories) => _ChipGroup(
                  labels: categories,
                  selected: filter.selectedCategories,
                  onToggle: (category) {
                    ref
                        .read(serverFlowFilterProvider.notifier)
                        .toggleCategory(category);
                  },
                ),
                loading: () => const _LoadingChips(),
                error: (_, _) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: 16),

              // Users section (with search)
              _SectionHeader(title: 'Users'),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _userSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              usersAsync.when(
                data: (users) {
                  final filtered = _userSearchQuery.isEmpty
                      ? users
                      : users
                            .where(
                              (u) => u.toLowerCase().contains(_userSearchQuery),
                            )
                            .toList();
                  return _ChipGroup(
                    labels: filtered,
                    selected: filter.selectedUsers,
                    onToggle: (user) {
                      ref
                          .read(serverFlowFilterProvider.notifier)
                          .toggleUser(user);
                    },
                  );
                },
                loading: () => const _LoadingChips(),
                error: (_, _) => const Text('Failed to load users'),
              ),
              const SizedBox(height: 16),

              // Time range section
              _SectionHeader(title: 'Time Range'),
              _TimeRangeSlider(
                startHour: filter.timeRangeStartHour,
                endHour: filter.timeRangeEndHour,
                onChanged: (start, end) {
                  ref
                      .read(serverFlowFilterProvider.notifier)
                      .setTimeRange(start, end);
                },
                onClear: () {
                  ref.read(serverFlowFilterProvider.notifier).clearTimeRange();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> labels;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ChipGroup({
    required this.labels,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Text(
        'No data available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: labels.map((label) {
        final isSelected = selected.contains(label);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onToggle(label),
        );
      }).toList(),
    );
  }
}

class _LoadingChips extends StatelessWidget {
  const _LoadingChips();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _TimeRangeSlider extends StatelessWidget {
  final double? startHour;
  final double? endHour;
  final void Function(double start, double end) onChanged;
  final VoidCallback onClear;

  const _TimeRangeSlider({
    required this.startHour,
    required this.endHour,
    required this.onChanged,
    required this.onClear,
  });

  static String _formatHour(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = startHour ?? 0.0;
    final end = endHour ?? 24.0;
    final isActive = startHour != null || endHour != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_formatHour(start)} - ${_formatHour(end)}'),
            const Spacer(),
            if (isActive)
              TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
        RangeSlider(
          values: RangeValues(start, end),
          min: 0,
          max: 24,
          divisions: 96,
          labels: RangeLabels(_formatHour(start), _formatHour(end)),
          onChanged: (values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}
