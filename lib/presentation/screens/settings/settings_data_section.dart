import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/helpers/file_export.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// Data management settings: export, import, delete all tasks.
class SettingsDataSection extends ConsumerWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'Data'),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Export Tasks'),
          subtitle: const Text('Save tasks to a JSON file'),
          onTap: () => _exportTasks(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import Tasks'),
          subtitle: const Text('Load tasks from a JSON file'),
          onTap: () => _importTasks(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete All Tasks'),
          subtitle: const Text('Permanently remove all tasks'),
          onTap: () => _showDeleteAllTasksDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showDeleteAllTasksDialog(
      BuildContext context, WidgetRef ref) async {
    final taskCount = await ref.read(taskRepositoryProvider).count();
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tasks?'),
        content: Text(
          'This will permanently delete all $taskCount task(s). '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(taskRepositoryProvider).clear();
      ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tasks deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportTasks(BuildContext context, WidgetRef ref) async {
    final jsonString = await ref.read(taskRepositoryProvider).exportToJson();
    final fileName =
        'timeflow_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';

    final result = await exportJsonFile(jsonString, fileName);

    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.filePath != null
              ? 'Exported to ${result.filePath}'
              : 'Export complete'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${result.error}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importTasks(BuildContext context, WidgetRef ref) async {
    final fileResult = await pickAndReadJsonFile();

    if (!fileResult.success || fileResult.content == null) {
      if (fileResult.error != 'No file selected' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: ${fileResult.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tasks?'),
        content: const Text(
          'This will add all tasks from the backup file. '
          'Existing tasks with the same ID will be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final count = await ref
          .read(taskRepositoryProvider)
          .importFromJson(fileResult.content!);
      ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count task(s)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
