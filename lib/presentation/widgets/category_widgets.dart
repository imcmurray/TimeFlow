import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/repositories/category_repository.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/providers/category_provider.dart';
import 'package:timeflow/presentation/screens/categories_screen.dart';

/// Widget displaying a category chip/badge.
class CategoryBadge extends StatelessWidget {
  final TaskCategory category;
  final bool compact;
  final VoidCallback? onTap;

  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (category.isNone) return const SizedBox.shrink();

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: category.lightColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.iconData,
            size: compact ? 12 : 16,
            color: category.color,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                category.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: category.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }

    return badge;
  }
}

/// The category's icon in its colour (grey for None).
class CategoryIcon extends StatelessWidget {
  final TaskCategory category;
  final double size;

  const CategoryIcon(this.category, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) => Icon(
    category.iconData,
    size: size,
    color: category.isNone
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : category.color,
  );
}

/// The task editor's category field. Tapping opens [showCategoryPicker].
class CategoryPickerField extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CategoryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryLookupProvider)[value];
    return InkWell(
      key: const Key('category-field'),
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showCategoryPicker(context, selected: value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Row(
          children: [
            CategoryIcon(category, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(category.label, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user pick a category and returns its id, or null if dismissed.
///
/// Long-pressing a category renames it; "New category" adds one and picks
/// it.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CategoryPickerSheet(selected: selected),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  final String selected;

  const _CategoryPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryLookupProvider).all;
    final theme = Theme.of(context);

    Widget tile(TaskCategory c) => ListTile(
      key: Key('pick-${c.id}'),
      leading: CategoryIcon(c),
      title: Text(c.label),
      trailing: c.id == selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, c.id),
      onLongPress: c.isNone ? null : () => renameCategory(context, ref, c),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Category', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Manage categories',
                  icon: const Icon(Icons.tune),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                ),
                TextButton.icon(
                  key: const Key('new-category'),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                  onPressed: () async {
                    final draft = await showCategoryEditor(context, ref);
                    if (draft == null) return;
                    final created = await ref
                        .read(categoryRepositoryProvider)
                        .add(draft);
                    if (context.mounted) Navigator.pop(context, created.id);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Long-press a category to rename it',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          tile(TaskCategory.none),
          for (final c in categories) tile(c),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Validates a category name: not empty and not used by another category.
String? validateCategoryName(
  String name,
  List<TaskCategory> all, {
  String? exceptId,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Give the category a name';
  if (trimmed.toLowerCase() == TaskCategory.none.name.toLowerCase()) {
    return '"None" is reserved';
  }
  final taken = all.any(
    (c) => c.id != exceptId && c.name.toLowerCase() == trimmed.toLowerCase(),
  );
  return taken ? 'There is already a category called "$trimmed"' : null;
}

/// Edits a category's name, colour and icon (or makes a new one when
/// [initial] is null). Returns the edited category, not yet saved, or null
/// if cancelled.
Future<TaskCategory?> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  TaskCategory? initial,
}) {
  return showModalBottomSheet<TaskCategory>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CategoryEditor(
      initial: initial,
      others: ref.read(categoryLookupProvider).all,
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  final TaskCategory? initial;
  final List<TaskCategory> others;

  const _CategoryEditor({required this.initial, required this.others});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late int _color = widget.initial?.colorValue ?? categoryColors.first;
  late String _icon = widget.initial?.icon ?? 'star';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TaskCategory get _draft =>
      (widget.initial ??
              const TaskCategory(id: '', name: '', icon: 'star', colorValue: 0))
          .copyWith(name: _name.text.trim(), icon: _icon, colorValue: _color);

  void _save() {
    final error = validateCategoryName(
      _name.text,
      widget.others,
      exceptId: widget.initial?.id,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'New category' : 'Edit category',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('category-name'),
                controller: _name,
                autofocus: widget.initial == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  prefixIcon: Icon(categoryIcons[_icon], color: Color(_color)),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              Text('Colour', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in categoryColors)
                    Semantics(
                      button: true,
                      selected: c == _color,
                      label: 'Colour',
                      child: GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c == _color
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: c == _color
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Icon', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final MapEntry(key: name, value: icon)
                      in categoryIcons.entries)
                    IconButton(
                      tooltip: name.replaceAll('_', ' '),
                      isSelected: name == _icon,
                      style: IconButton.styleFrom(
                        backgroundColor: name == _icon
                            ? Color(_color).withValues(alpha: 0.18)
                            : null,
                      ),
                      icon: Icon(
                        icon,
                        color: name == _icon ? Color(_color) : null,
                      ),
                      onPressed: () => setState(() => _icon = name),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('category-save'),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Long-press rename: asks for a new name, then saves it like any edit.
Future<TaskCategory?> renameCategory(
  BuildContext context,
  WidgetRef ref,
  TaskCategory category,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(
      category: category,
      others: ref.read(categoryLookupProvider).all,
    ),
  );
  if (name == null || name == category.name || !context.mounted) return null;
  return applyCategoryEdit(
    context,
    ref,
    category,
    category.copyWith(name: name),
  );
}

class _RenameDialog extends StatefulWidget {
  final TaskCategory category;
  final List<TaskCategory> others;

  const _RenameDialog({required this.category, required this.others});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.category.name);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = validateCategoryName(
      _controller.text,
      widget.others,
      exceptId: widget.category.id,
    );
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename "${widget.category.name}"'),
      content: TextField(
        key: const Key('rename-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: 'Name', errorText: _error),
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Rename')),
      ],
    );
  }
}

enum _EditChoice { updateAll, saveAsNew }

/// Saves [edited] over [original]. When events use the category, asks
/// whether to change it everywhere or keep the events on the old one and
/// save the changes as a new category.
///
/// Returns the category the changes ended up in, or null if cancelled.
Future<TaskCategory?> applyCategoryEdit(
  BuildContext context,
  WidgetRef ref,
  TaskCategory original,
  TaskCategory edited,
) async {
  if (edited.looksLike(original)) return original;
  final repo = ref.read(categoryRepositoryProvider);
  final usage = (await repo.usage(DateTime.now()))[original.id];
  if (usage == null || !usage.inUse) {
    await repo.update(edited);
    return edited;
  }
  if (!context.mounted) return null;
  final sameName = edited.name.toLowerCase() == original.name.toLowerCase();
  final choice = await showDialog<_EditChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('"${original.name}" is in use'),
      content: Text('It is used by ${describeUsage(usage)}.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('save-as-new'),
          onPressed: sameName
              ? null
              : () => Navigator.pop(context, _EditChoice.saveAsNew),
          child: Text(
            sameName ? 'New category needs a new name' : 'Save as new category',
          ),
        ),
        FilledButton(
          key: const Key('update-all'),
          onPressed: () => Navigator.pop(context, _EditChoice.updateAll),
          child: const Text('Update all events'),
        ),
      ],
    ),
  );
  switch (choice) {
    case _EditChoice.updateAll:
      await repo.update(edited);
      return edited;
    case _EditChoice.saveAsNew:
      return repo.add(
        edited.copyWith(id: CategoryRepository.newId()),
        after: original.id,
      );
    case null:
      return null;
  }
}

/// e.g. "12 past events, 3 upcoming events and 1 repeating task".
String describeUsage(CategoryUsage u) {
  String n(int count, String what) => '$count $what${count == 1 ? '' : 's'}';
  final parts = [
    if (u.past > 0) n(u.past, 'past event'),
    if (u.upcoming > 0) n(u.upcoming, 'upcoming event'),
    if (u.repeating > 0) n(u.repeating, 'repeating task'),
  ];
  if (parts.length < 2) return parts.join();
  return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
}

/// Removes a category after confirming. If events use it, asks which
/// category they move to. Returns whether it was removed.
Future<bool> confirmRemoveCategory(
  BuildContext context,
  WidgetRef ref,
  TaskCategory category,
) async {
  final repo = ref.read(categoryRepositoryProvider);
  final usage = (await repo.usage(DateTime.now()))[category.id];
  if (!context.mounted) return false;
  final others = [
    TaskCategory.none,
    for (final c in ref.read(categoryLookupProvider).all)
      if (c.id != category.id) c,
  ];
  var moveTo = TaskCategory.noneId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Remove "${category.name}"?'),
        content: usage == null || !usage.inUse
            ? const Text('No events use it.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'It is used by ${describeUsage(usage)}. '
                    'Move them to:',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('move-to'),
                    initialValue: moveTo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in others)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              CategoryIcon(c, size: 20),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  c.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => moveTo = v ?? TaskCategory.noneId),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-remove'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return false;
  await repo.remove(category.id, moveTo: moveTo);
  return true;
}
