import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/repositories/category_repository.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/providers/category_provider.dart';
import 'package:timeflow/presentation/widgets/category_widgets.dart';

/// Settings → Categories: every category with how many events use it.
/// Tap to edit, long-press to rename, drag the handle to reorder.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final draft = await showCategoryEditor(context, ref);
    if (draft != null) await ref.read(categoryRepositoryProvider).add(draft);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    TaskCategory category,
  ) async {
    final edited = await showCategoryEditor(context, ref, initial: category);
    if (edited != null && context.mounted) {
      await applyCategoryEdit(context, ref, category, edited);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    final usage = ref.watch(categoryUsageProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            key: const Key('add-category'),
            tooltip: 'New category',
            icon: const Icon(Icons.add),
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: categories == null
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? Center(
              child: TextButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add a category'),
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: categories.length,
              onReorderItem: (from, to) {
                final ids = [for (final c in categories) c.id];
                ids.insert(to, ids.removeAt(from));
                ref.read(categoryRepositoryProvider).reorder(ids);
              },
              itemBuilder: (context, i) {
                final c = categories[i];
                final u = usage[c.id] ?? CategoryUsage.unused;
                return ListTile(
                  key: ValueKey(c.id),
                  leading: CategoryIcon(c),
                  title: Text(c.label),
                  subtitle: Text(u.describe()),
                  onTap: () => _edit(context, ref, c),
                  onLongPress: () => renameCategory(context, ref, c),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('remove-${c.id}'),
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => confirmRemoveCategory(context, ref, c),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
