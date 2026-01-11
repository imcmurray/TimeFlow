import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';

/// A card widget representing a single task on the timeline.
///
/// Task cards are positioned vertically based on their start time,
/// with height proportional to duration. They support swipe gestures
/// for completion and tap for editing.
class TaskCard extends StatefulWidget {
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
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _updateAnimation();
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminderState != widget.reminderState) {
      _updateAnimation();
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

  void _updateAnimation() {
    if (widget.reminderState == ReminderState.triggered) {
      _shakeController.repeat(reverse: true);
    } else {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTriggered = widget.reminderState == ReminderState.triggered;

    // Determine card color
    Color cardColor;
    if (widget.task.color != null) {
      cardColor = Color(int.parse(widget.task.color!.replaceFirst('#', '0xFF')));
    } else if (widget.task.isImportant) {
      cardColor = AppColors.accentCoral;
    } else if (widget.task.isCompleted) {
      cardColor = AppColors.taskCompleted;
    } else if (widget.task.isCurrent) {
      cardColor = AppColors.taskCurrent;
    } else {
      cardColor = AppColors.primaryBlue;
    }

    Widget card = Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onComplete?.call();
          return false;
        } else {
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete?.call();
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
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isTriggered
                ? AppColors.reminderLine.withValues(alpha: 0.1)
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTriggered
                  ? AppColors.reminderLine
                  : cardColor.withOpacity(widget.task.isCompleted ? 0.3 : 0.5),
              width: isTriggered ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isTriggered
                    ? AppColors.reminderLine.withValues(alpha: 0.3)
                    : cardColor.withOpacity(0.1),
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
                      : cardColor.withOpacity(widget.task.isCompleted ? 0.5 : 1.0),
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
      card = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints, Color cardColor) {
    final availableHeight = constraints.maxHeight;
    final padding = availableHeight < 40 ? 4.0 : 8.0;
    final contentHeight = availableHeight - (padding * 2);
    final showTime = contentHeight >= 45;
    final showDescription = contentHeight >= 85 &&
        widget.task.description != null &&
        widget.task.description!.isNotEmpty;
    final showIndicators = contentHeight >= 55;

    return ClipRect(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Row(
              children: [
                if (widget.task.isImportant)
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
                    widget.task.title,
                    style: TextStyle(
                      fontSize: availableHeight < 40 ? 12 : 16,
                      fontWeight: FontWeight.w600,
                      decoration: widget.task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: widget.task.isCompleted
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
                // Reminder badge or completion check
                if (widget.task.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.taskCompleted,
                  )
                else if (widget.reminderState != null && widget.task.reminderMinutes != null)
                  _buildReminderBadge(),
              ],
            ),

            // Time row
            if (showTime) ...[
              const SizedBox(height: 4),
              Text(
                '${_formatTime(widget.task.startTime)} - ${_formatTime(widget.task.endTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
            ],

            // Description preview
            if (showDescription) ...[
              const SizedBox(height: 4),
              Text(
                widget.task.description!,
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

            // Recurring indicator (only if no reminder badge shown in title)
            if (showIndicators && widget.task.recurringPattern != null) ...[
              const SizedBox(height: 4),
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
      ),
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
            Icon(
              icon,
              size: 14,
              color: badgeColor,
            ),
            if (isAcknowledged) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.check,
                size: 10,
                color: badgeColor,
              ),
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

  String _formatTime(DateTime time) {
    if (widget.use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
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
            content: Text('Delete "${widget.task.title}"?'),
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
