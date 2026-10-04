import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/priority_column_card.dart';
import 'package:timeflow/presentation/widgets/reminder_shake_mixin.dart';
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
    with SingleTickerProviderStateMixin, ReminderShakeMixin {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    initShake();
    setShakeActive(
      widget.reminderStates.values.any(
        (state) => state == ReminderState.triggered,
      ),
    );
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(MergedTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    setShakeActive(
      widget.reminderStates.values.any(
        (state) => state == ReminderState.triggered,
      ),
    );
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    // Find the earliest upcoming reminder
    final upcomingReminders = widget.reminderTimes.entries
        .where(
          (e) =>
              widget.reminderStates[e.key] != ReminderState.triggered &&
              widget.reminderStates[e.key] != ReminderState.acknowledged,
        )
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    disposeShake();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTriggeredReminder = widget.reminderStates.values.any(
      (state) => state == ReminderState.triggered,
    );
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
      card = applyShakeTransform(card);
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

        return PriorityColumnCard(
          padding: EdgeInsets.all(padding),
          children: [
            // Title list with reminder badge (highest priority)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTitleList(context)),
                _buildReminderSummary(),
              ],
            ),

            // Time range
            const SizedBox(height: 4),
            _buildTimeRange(context),

            // Color dots (lowest priority)
            const SizedBox(height: 4),
            _buildColorDots(),
          ],
        );
      },
    );
  }

  Widget _buildTitleList(BuildContext context) {
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
                right: index < displayTasks.length - 1 ? 8 : 0,
              ),
              child: _buildTitlePill(task),
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

  Widget _buildTitlePill(Task task) {
    final color = _getTaskColor(task);

    return GestureDetector(
      onTap: widget.onTapTask != null ? () => widget.onTapTask!(task) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
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
                  fontSize: 11,
                  fontWeight: task.isImportant
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: color,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.isCompleted)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 12,
                  color: color.withValues(alpha: 0.7),
                ),
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
        Icon(Icons.schedule, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          '$startStr - $endStr',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
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
      earliest = pendingReminders.values.reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
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
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTriggered
                ? Icons.notifications_active
                : Icons.notifications_outlined,
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
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 2),
                ],
              ),
            ),
          );
        }),
        const Spacer(),
        const Icon(Icons.touch_app, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        const Text(
          'Tap to expand',
          style: TextStyle(fontSize: 10, color: Colors.white54),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) =>
      TimeFormatter.formatTime(time, use24HourFormat: widget.use24HourFormat);

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
