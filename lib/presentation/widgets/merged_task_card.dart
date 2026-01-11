import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/water_ripple_painter.dart';

/// A merged card representing multiple overlapping tasks.
///
/// When tasks overlap in time, they are displayed as a single unified
/// "confluence" card - evoking rivers converging into a stronger stream.
/// Tapping the card opens a modal showing individual tasks.
class MergedTaskCard extends StatefulWidget {
  /// The list of overlapping tasks to display.
  final List<Task> tasks;

  /// Whether to use 24-hour time format.
  final bool use24HourFormat;

  /// Reminder states for each task, keyed by task ID.
  final Map<String, ReminderState> reminderStates;

  /// Reminder times for each task, keyed by task ID.
  final Map<String, DateTime> reminderTimes;

  /// Callback when the card is tapped to expand.
  final VoidCallback? onTap;

  /// Callback when an individual task pill is tapped for editing.
  final void Function(Task task)? onTapTask;

  const MergedTaskCard({
    super.key,
    required this.tasks,
    this.use24HourFormat = false,
    this.reminderStates = const {},
    this.reminderTimes = const {},
    this.onTap,
    this.onTapTask,
  });

  @override
  State<MergedTaskCard> createState() => _MergedTaskCardState();
}

class _MergedTaskCardState extends State<MergedTaskCard>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(MergedTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    // Find the earliest upcoming reminder
    final upcomingReminders = widget.reminderTimes.entries
        .where((e) =>
            widget.reminderStates[e.key] != ReminderState.triggered &&
            widget.reminderStates[e.key] != ReminderState.acknowledged)
        .toList();

    if (upcomingReminders.isEmpty) return;

    final earliest = upcomingReminders
        .map((e) => e.value)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final remaining = earliest.difference(DateTime.now());
    final interval = remaining.inMinutes < 1
        ? const Duration(seconds: 1)
        : const Duration(seconds: 10);

    _countdownTimer = Timer.periodic(interval, (_) {
      if (mounted) setState(() {});
    });
  }

  void _updateAnimation() {
    // Shake if any task has a triggered reminder
    final hasTriggered = widget.reminderStates.values
        .any((state) => state == ReminderState.triggered);

    if (hasTriggered) {
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
    final hasTriggeredReminder = widget.reminderStates.values
        .any((state) => state == ReminderState.triggered);
    final gradient = _buildGradient();
    final dominantColor = _getDominantColor();

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasTriggeredReminder
                ? AppColors.reminderLine
                : dominantColor.withValues(alpha: 0.5),
            width: hasTriggeredReminder ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: hasTriggeredReminder
                  ? AppColors.reminderLine.withValues(alpha: 0.3)
                  : dominantColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: WaterRippleEffect(
            rippleColor: isDark ? Colors.white : dominantColor,
            isActive: !hasTriggeredReminder,
            child: _buildContent(context),
          ),
        ),
      ),
    );

    // Apply shake animation when any reminder is triggered
    if (hasTriggeredReminder) {
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

  LinearGradient _buildGradient() {
    // Sort by priority: important tasks first
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) {
        if (a.isImportant && !b.isImportant) return -1;
        if (!a.isImportant && b.isImportant) return 1;
        return a.startTime.compareTo(b.startTime);
      });

    final sortedColors = sortedTasks.map((t) => _getTaskColor(t)).toList();

    // Ensure we have at least 2 colors for gradient
    if (sortedColors.length == 1) {
      sortedColors.add(sortedColors.first.withValues(alpha: 0.7));
    }

    return LinearGradient(
      colors: sortedColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getDominantColor() {
    // Return color of most important or first task
    final important = widget.tasks.where((t) => t.isImportant).firstOrNull;
    return _getTaskColor(important ?? widget.tasks.first);
  }

  Color _getTaskColor(Task task) {
    if (task.color != null) {
      return Color(int.parse(task.color!.replaceFirst('#', '0xFF')));
    } else if (task.isImportant) {
      return AppColors.accentCoral;
    } else if (task.isCompleted) {
      return AppColors.taskCompleted;
    } else if (task.isCurrent) {
      return AppColors.taskCurrent;
    } else {
      return AppColors.primaryBlueDark;
    }
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final padding = availableHeight < 60 ? 8.0 : 16.0;
        final contentHeight = availableHeight - (padding * 2);

        // Progressive disclosure based on available space
        final showTimeRange = contentHeight >= 60;
        final showColorDots = contentHeight >= 100;

        // Calculate available height for titles (subtract space for other elements)
        var titleHeight = contentHeight;
        if (showTimeRange) titleHeight -= 24; // time range + spacing
        if (showColorDots) titleHeight -= 20; // color dots + spacing

        return ClipRect(
          child: SizedBox(
            height: availableHeight,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title list with reminder badge (always shown)
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTitleList(context, titleHeight)),
                        _buildReminderSummary(),
                      ],
                    ),
                  ),

                  // Time range (if space)
                  if (showTimeRange) ...[
                    const SizedBox(height: 4),
                    _buildTimeRange(context),
                  ],

                  // Color dots (if more space)
                  if (showColorDots) ...[
                    const SizedBox(height: 4),
                    _buildColorDots(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleList(BuildContext context, double availableHeight) {
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) {
        if (a.isImportant && !b.isImportant) return -1;
        if (!a.isImportant && b.isImportant) return 1;
        return a.startTime.compareTo(b.startTime);
      });

    final maxTitles = sortedTasks.length.clamp(1, 4);
    final displayTasks = sortedTasks.take(maxTitles).toList();
    final remainingCount = sortedTasks.length - maxTitles;

    return Row(
      children: [
        ...displayTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          return Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                  right: index < displayTasks.length - 1 ? 8 : 0),
              child: _buildTitlePill(task, availableHeight),
            ),
          );
        }),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '+$remainingCount more',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitlePill(Task task, double availableHeight) {
    final color = _getTaskColor(task);
    final isSmall = availableHeight < 50;

    return GestureDetector(
      onTap: widget.onTapTask != null ? () => widget.onTapTask!(task) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isSmall ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.isImportant)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 12, color: color),
              ),
            Flexible(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 12,
                  fontWeight: task.isImportant ? FontWeight.bold : FontWeight.w500,
                  color: color,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.isCompleted)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                    Icons.check_circle, size: 12, color: color.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRange(BuildContext context) {
    // Calculate the overall time span
    final earliestStart = widget.tasks
        .map((t) => t.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestEnd = widget.tasks
        .map((t) => t.endTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final startStr = _formatTime(earliestStart);
    final endStr = _formatTime(latestEnd);
    final count = widget.tasks.length;

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          '$startStr - $endStr',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count concurrent',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSummary() {
    // Count pending and triggered reminders
    final pendingReminders = <String, DateTime>{};
    int triggeredCount = 0;

    for (final task in widget.tasks) {
      if (task.reminderMinutes == null) continue;

      final state = widget.reminderStates[task.id];
      final time = widget.reminderTimes[task.id];

      if (state == ReminderState.triggered) {
        triggeredCount++;
      } else if (state != ReminderState.acknowledged && time != null) {
        pendingReminders[task.id] = time;
      }
    }

    if (pendingReminders.isEmpty && triggeredCount == 0) {
      return const SizedBox.shrink();
    }

    // Get earliest pending reminder
    DateTime? earliest;
    if (pendingReminders.isNotEmpty) {
      earliest = pendingReminders.values
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final isTriggered = triggeredCount > 0;
    final badgeColor = isTriggered
        ? AppColors.reminderLine
        : AppColors.reminderLine.withValues(alpha: 0.8);

    String text;
    if (isTriggered) {
      text = triggeredCount > 1 ? '$triggeredCount!' : '!';
    } else if (earliest != null) {
      text = _formatCountdown(earliest);
      if (pendingReminders.length > 1) {
        text = '$text +${pendingReminders.length - 1}';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTriggered ? Icons.notifications_active : Icons.notifications_outlined,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDots() {
    return Row(
      children: [
        ...widget.tasks.map((task) {
          final color = _getTaskColor(task);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          );
        }),
        const Spacer(),
        const Icon(
          Icons.touch_app,
          size: 14,
          color: Colors.white54,
        ),
        const SizedBox(width: 4),
        const Text(
          'Tap to expand',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
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

  String _formatCountdown(DateTime reminderTime) {
    final remaining = reminderTime.difference(DateTime.now());

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
}
