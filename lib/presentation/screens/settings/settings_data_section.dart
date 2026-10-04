import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/data/backup/backup_codec.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/helpers/file_export.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// Backup, restore, and deleting everything.
class SettingsDataSection extends ConsumerWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'Data'),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Back up tasks'),
          subtitle: const Text('Save all tasks to a file'),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Restore from backup'),
          subtitle: const Text('Add tasks from a backup file'),
          onTap: () => _import(context, ref),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever,
              color: Theme.of(context).colorScheme.error),
          title: const Text('Delete all tasks'),
          subtitle: const Text('Permanently remove every task'),
          onTap: () => _deleteAll(context, ref),
        ),
      ],
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(taskRepositoryProvider).exportToJson();
      final saved = await saveBackupFile(
          json, 'timeflow-backup-${LocalDate.today().toIso()}.json');
      if (saved && context.mounted) _snack(context, 'Backup saved');
    } catch (e) {
      if (context.mounted) _snack(context, 'Could not save the backup: $e');
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final String? json;
    try {
      json = await pickBackupFile();
    } catch (e) {
      if (context.mounted) _snack(context, 'Could not read the file: $e');
      return;
    }
    if (json == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text(
          'Tasks from the backup are added to your timeline. Tasks that are '
          'in both are replaced by the backup version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final count = await ref.read(taskRepositoryProvider).importFromJson(json);
      if (context.mounted) {
        _snack(
            context, count == 1 ? 'Restored 1 task' : 'Restored $count tasks');
      }
    } on BackupFormatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(taskRepositoryProvider).count();
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all tasks?'),
        content: Text(
          count == 1
              ? 'Your 1 task will be deleted. This can\'t be undone.'
              : 'All $count tasks (including every repeating series) will be '
                  'deleted. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(taskRepositoryProvider).clear();
    messenger.showSnackBar(const SnackBar(
      content: Text('All tasks deleted'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
