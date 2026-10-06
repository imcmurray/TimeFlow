import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/grouping_provider.dart';

/// Dropdown to switch the grouping mode (host / category / user).
class GroupingDropdown extends ConsumerWidget {
  const GroupingDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouping = ref.watch(groupingProvider);

    return DropdownButton<GroupingMode>(
      value: grouping.mode,
      underline: const SizedBox.shrink(),
      isDense: true,
      items: const [
        DropdownMenuItem(value: GroupingMode.host, child: Text('By Host')),
        DropdownMenuItem(
          value: GroupingMode.category,
          child: Text('By Category'),
        ),
        DropdownMenuItem(value: GroupingMode.user, child: Text('By User')),
      ],
      onChanged: (mode) {
        if (mode != null) {
          ref.read(groupingProvider.notifier).setMode(mode);
        }
      },
    );
  }
}
