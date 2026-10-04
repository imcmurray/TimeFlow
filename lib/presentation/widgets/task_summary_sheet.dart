import 'package:flutter/material.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// Shows a task's details without editing controls (shared schedules).
Future<void> showTaskSummarySheet(
  BuildContext context,
  Task task, {
  required bool use24Hour,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      String time(DateTime t) =>
          TimeFormatter.formatTime(t, use24HourFormat: use24Hour);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (task.isImportant)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.star,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${TimeFormatter.formatDateFull(task.startTime)} · '
                '${time(task.startTime)} – ${time(task.endTime)}',
                style: theme.textTheme.bodyLarge,
              ),
              if (task.category != TaskCategory.none) ...[
                const SizedBox(height: 12),
                CategoryBadge(category: task.category),
              ],
              if (task.description != null) ...[
                const SizedBox(height: 16),
                Text(task.description!, style: theme.textTheme.bodyMedium),
              ],
              if (task.notes != null) ...[
                const SizedBox(height: 16),
                Text('Notes', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(task.notes!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      );
    },
  );
}
