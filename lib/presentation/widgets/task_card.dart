import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';

/// A card widget representing a single task on the timeline.
///
/// Task cards are positioned vertically based on their start time,
/// with height proportional to duration. They support swipe gestures
/// for completion and tap for editing.
class TaskCard extends StatelessWidget {
  /// The task to display.
  final Task task;

  /// Callback when the task is tapped for editing.
  final VoidCallback? onTap;

  /// Callback when the task is swiped to complete.
  final VoidCallback? onComplete;

  /// Callback when the task is swiped to delete.
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine card color
    Color cardColor;
    if (task.color != null) {
      // Custom color from task
      cardColor = Color(int.parse(task.color!.replaceFirst('#', '0xFF')));
    } else if (task.isImportant) {
      cardColor = AppColors.accentCoral;
    } else if (task.isCompleted) {
      cardColor = AppColors.taskCompleted;
    } else if (task.isCurrent) {
      cardColor = AppColors.taskCurrent;
    } else {
      cardColor = AppColors.primaryBlue;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to complete
          onComplete?.call();
          return false; // We handle the update ourselves
        } else {
          // Swipe left to delete
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.taskCompleted,
        icon: Icons.check_circle,
        label: 'Complete',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        label: 'Delete',
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cardColor.withOpacity(task.isCompleted ? 0.3 : 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                // Color indicator bar
                Container(
                  width: 4,
                  color: cardColor.withOpacity(task.isCompleted ? 0.5 : 1.0),
                ),
                // Content - uses LayoutBuilder for responsive sizing
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      // Reduce padding for very short cards
                      final padding = availableHeight < 40 ? 4.0 : 8.0;
                      // Thresholds for showing optional content
                      final showTime = availableHeight >= 50;
                      final showDescription = availableHeight >= 80 &&
                          task.description != null &&
                          task.description!.isNotEmpty;
                      final showIndicators = availableHeight >= 100 &&
                          (task.reminderMinutes != null ||
                              task.recurringPattern != null);

                      return ClipRect(
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title row with indicators (always shown)
                              Row(
                                children: [
                                  if (task.isImportant)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.star,
                                        size: 16,
                                        color: AppColors.accentCoral,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: availableHeight < 40 ? 12 : 16,
                                        fontWeight: FontWeight.w600,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.isCompleted
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5)
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (task.isCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppColors.taskCompleted,
                                    ),
                                ],
                              ),

                              // Time row (shown if card is tall enough)
                              if (showTime) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],

                              // Description preview (shown if card is tall enough)
                              if (showDescription) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              // Indicator row for reminder/recurring (shown if card is tall enough)
                              if (showIndicators) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (task.reminderMinutes != null) ...[
                                      Icon(
                                        Icons.notifications_outlined,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (task.recurringPattern != null) ...[
                                      Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Background shown during swipe gestures.
class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
