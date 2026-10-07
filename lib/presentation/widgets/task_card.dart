import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/providers/category_provider.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/presentation/widgets/category_widgets.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/priority_column_card.dart';
import 'package:timeflow/presentation/widgets/reminder_shake_mixin.dart';

/// A card widget representing a single task on the timeline.
///
/// Task cards are positioned vertically based on their start time,
/// with height proportional to duration. They support swipe gestures
/// for completion and tap for editing.
class TaskCard extends ConsumerStatefulWidget {
  /// The task to display.
  final Task task;

  /// Current reminder state for this task.
  final ReminderState? reminderState;

  /// When the reminder will trigger (for countdown display).
  final DateTime? reminderTime;

  /// Callback when the task is tapped for editing.
  final VoidCallback? onTap;

  /// Callback when the task is swiped to complete.
  final VoidCallback? onComplete;

  /// Callback when the task is swiped to delete.
  final VoidCallback? onDelete;

  /// Callback when reminder is acknowledged.
  final VoidCallback? onReminderAcknowledged;

  /// Callback when acknowledged reminder is tapped to reschedule.
  final VoidCallback? onReminderRescheduled;

  /// Whether to use 24-hour time format.
  final bool use24HourFormat;

  const TaskCard({
    super.key,
    required this.task,
    this.reminderState,
    this.reminderTime,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.onReminderAcknowledged,
    this.onReminderRescheduled,
    this.use24HourFormat = false,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin, ReminderShakeMixin {
  Timer? _countdownTimer;
  TaskCategory _category = TaskCategory.none;

  @override
  void initState() {
    super.initState();
    initShake();
    setShakeActive(widget.reminderState == ReminderState.triggered);
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminderState != widget.reminderState) {
      setShakeActive(widget.reminderState == ReminderState.triggered);
    }
    if (oldWidget.reminderTime != widget.reminderTime ||
        oldWidget.reminderState != widget.reminderState) {
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    // Only run timer if we have a reminder time and it's not triggered/acknowledged
    if (widget.reminderTime == null ||
        widget.reminderState == ReminderState.triggered ||
        widget.reminderState == ReminderState.acknowledged ||
        widget.reminderState == null) {
      return;
    }

    final remaining = widget.reminderTime!.difference(DateTime.now());

    // Determine timer interval based on remaining time
    final interval = remaining.inMinutes < 1
        ? const Duration(seconds: 1)
        : const Duration(seconds: 10); // Update more frequently as we approach

    _countdownTimer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {});
        // Switch to second-based updates when under 1 minute
        final newRemaining = widget.reminderTime!.difference(DateTime.now());
        if (newRemaining.inMinutes < 1 && interval.inSeconds > 1) {
          _startCountdownTimer(); // Restart with faster interval
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    disposeShake();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _category = ref.watch(categoryLookupProvider)[widget.task.categoryId];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTriggered = widget.reminderState == ReminderState.triggered;

    // Determine card color - prioritize category color for visual consistency
    Color cardColor;
    if (widget.task.color != null) {
      cardColor = Color(
        int.parse(widget.task.color!.replaceFirst('#', '0xFF')),
      );
    } else if (!_category.isNone) {
      // Use category color as the primary indicator
      cardColor = _category.color;
    } else if (widget.task.isImportant) {
      cardColor = AppColors.accentCoral;
    } else if (widget.task.isCompleted) {
      cardColor = AppColors.taskCompleted;
    } else if (widget.task.isCurrent) {
      cardColor = AppColors.taskCurrent;
    } else {
      cardColor = AppColors.primaryBlue;
    }

    // Swipe right to complete, left to delete (the delete can be undone).
    // Without callbacks (read-only views) the card doesn't swipe.
    final direction = switch ((widget.onComplete, widget.onDelete)) {
      (null, null) => DismissDirection.none,
      (_, null) => DismissDirection.startToEnd,
      (null, _) => DismissDirection.endToStart,
      _ => DismissDirection.horizontal,
    };
    Widget card = Dismissible(
      key: Key(widget.task.id),
      direction: direction,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onComplete?.call();
        } else {
          widget.onDelete?.call();
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: widget.task.isCompleted
            ? AppColors.primaryBlue
            : AppColors.taskCompleted,
        icon: widget.task.isCompleted ? Icons.undo : Icons.check_circle,
        label: widget.task.isCompleted ? 'Not Done' : 'Complete',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        label: 'Delete',
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isTriggered
                ? AppColors.reminderLine.withValues(alpha: 0.1)
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTriggered
                  ? AppColors.reminderLine
                  : cardColor.withValues(
                      alpha: widget.task.isCompleted ? 0.3 : 0.5,
                    ),
              width: isTriggered ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isTriggered
                    ? AppColors.reminderLine.withValues(alpha: 0.3)
                    : cardColor.withValues(alpha: 0.1),
                blurRadius: isTriggered ? 12 : 8,
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
                  color: isTriggered
                      ? AppColors.reminderLine
                      : cardColor.withValues(
                          alpha: widget.task.isCompleted ? 0.5 : 1.0,
                        ),
                ),
                // Content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildContent(context, constraints, cardColor);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply shake animation when triggered
    if (isTriggered) {
      card = applyShakeTransform(card);
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: _semanticLabel(),
      onTap: widget.onTap,
      // Screen-reader alternatives to swiping.
      customSemanticsActions: {
        if (widget.onComplete != null)
          CustomSemanticsAction(
            label: widget.task.isCompleted ? 'Mark not done' : 'Mark done',
          ): widget.onComplete!,
        if (widget.onDelete != null)
          const CustomSemanticsAction(label: 'Delete'): widget.onDelete!,
      },
      excludeSemantics: true,
      child: card,
    );
  }

  String _semanticLabel() {
    final t = widget.task;
    final parts = <String>[
      t.title,
      '${_formatTime(t.startTime)} to ${_formatTime(t.endTime)}',
      if (t.isCompleted) 'done',
      if (t.isImportant) 'important',
      if (!_category.isNone) _category.label,
      if (t.isRecurring) 'repeats',
      if (t.attachmentPath != null) 'has a photo',
      if (widget.reminderState == ReminderState.triggered) 'reminder due',
      if (t.description != null) t.description!,
    ];
    return parts.join(', ');
  }

  Widget _buildContent(
    BuildContext context,
    BoxConstraints constraints,
    Color cardColor,
  ) {
    final availableHeight = constraints.maxHeight;
    final padding = availableHeight < 32
        ? 2.0
        : availableHeight < 40
        ? 4.0
        : 8.0;

    return PriorityColumnCard(
      padding: EdgeInsets.all(padding),
      children: [
        // Title row (highest priority)
        Row(
          children: [
            if (!_category.isNone)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _category.iconData,
                  size: 14,
                  color: _category.color,
                ),
              ),
            if (widget.task.isImportant)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 16, color: AppColors.accentCoral),
              ),
            Expanded(
              child: Text(
                widget.task.title,
                style: TextStyle(
                  fontSize: availableHeight < 40 ? 12 : 16,
                  fontWeight: FontWeight.w600,
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: widget.task.isCompleted
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Reminder badge or completion check
            if (widget.task.isCompleted)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.taskCompleted,
              )
            else if (widget.reminderState != null &&
                widget.task.reminderMinutes != null)
              _buildReminderBadge(),
          ],
        ),

        // Time row
        const SizedBox(height: 4),
        Text(
          '${_formatTime(widget.task.startTime)} - ${_formatTime(widget.task.endTime)}',
          style: TextStyle(
            fontSize: 12,
            decoration: TextDecoration.none,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),

        // Category badge and recurring indicator
        if (!_category.isNone ||
            widget.task.isRecurring ||
            widget.task.attachmentPath != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (!_category.isNone)
                CategoryBadge(category: _category, compact: true),
              if (widget.task.isRecurring) ...[
                if (!_category.isNone) const SizedBox(width: 6),
                Icon(
                  Icons.repeat,
                  size: 14,
                  semanticLabel: 'Repeats',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
              if (widget.task.attachmentPath != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.photo_outlined,
                  size: 14,
                  semanticLabel: 'Has a photo',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
        ],

        // Description preview (lowest priority)
        if (widget.task.description != null &&
            widget.task.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.task.description!,
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.none,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildReminderBadge() {
    final state = widget.reminderState!;
    final isTriggered = state == ReminderState.triggered;
    final isAcknowledged = state == ReminderState.acknowledged;

    Color badgeColor;
    IconData icon;
    String? timeText;

    if (isAcknowledged) {
      badgeColor = AppColors.taskCompleted;
      icon = Icons.notifications_active;
    } else if (isTriggered) {
      badgeColor = AppColors.reminderLine;
      icon = Icons.notifications_active;
    } else {
      badgeColor = AppColors.reminderLine.withValues(alpha: 0.7);
      icon = Icons.notifications_outlined;
      timeText = _formatCountdown();
    }

    return GestureDetector(
      onTap: isTriggered
          ? widget.onReminderAcknowledged
          : isAcknowledged
          ? widget.onReminderRescheduled
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: badgeColor),
            if (isAcknowledged) ...[
              const SizedBox(width: 2),
              Icon(Icons.check, size: 10, color: badgeColor),
            ] else if (timeText != null) ...[
              const SizedBox(width: 2),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCountdown() {
    if (widget.reminderTime == null) {
      return '${widget.task.reminderMinutes}m';
    }

    final remaining = widget.reminderTime!.difference(DateTime.now());

    if (remaining.isNegative) {
      return '0s';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes >= 1) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime time) =>
      TimeFormatter.formatTime(time, use24HourFormat: widget.use24HourFormat);
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
                fontSize: 14,
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
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
