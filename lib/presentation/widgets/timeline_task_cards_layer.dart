import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/widgets/confluence_modal.dart';
import 'package:timeflow/presentation/widgets/merged_task_card.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';
import 'package:timeflow/presentation/widgets/timeline_task_creation_preview.dart';
import 'package:timeflow/presentation/widgets/timeline_long_press_hint_tooltip.dart';
import 'package:timeflow/presentation/utils/timeline_offset.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:window_to_front/window_to_front.dart';

/// Layer containing positioned task cards for multiple days.
class TaskCardsLayerMultiDay extends ConsumerStatefulWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final DateRange loadedRange;

  const TaskCardsLayerMultiDay({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    required this.loadedRange,
  });

  @override
  ConsumerState<TaskCardsLayerMultiDay> createState() =>
      _TaskCardsLayerMultiDayState();
}

class _TaskCardsLayerMultiDayState
    extends ConsumerState<TaskCardsLayerMultiDay> {
  final Set<String> _acknowledgedReminders = {};
  final Map<String, int> _adjustedReminderMinutes = {};
  final Set<String> _windowRaisedForTasks = {};
  Timer? _reminderCheckTimer;

  static const _reminderOptions = [60, 30, 15, 10, 5, 0];

  // Drag state for long-press task repositioning
  Task? _draggingTask;
  double _dragOffsetY = 0.0;
  double _dragStartTop = 0.0;

  // State for long-press task creation (using manual timer for web compatibility)
  bool _isCreatingTask = false;
  bool _isWaitingForLongPress = false; // True while waiting for timer
  Timer? _longPressTimer;
  bool _tooltipDismissed = false; // Local dismissal state for tooltip animation
  double? _createTaskStartY; // Initial tap Y position (in timeline coordinates)
  double? _createTaskCurrentY; // Current drag Y position
  double? _createTaskStartX; // Track X for cancel gesture
  DateTime? _createTaskStartTime; // Snapped start time
  int _lastSnappedMinutes = -1; // Track for haptic feedback on snap
  static const _longPressDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _startReminderCheckTimer();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startReminderCheckTimer() {
    _reminderCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  int? _getEffectiveReminderMinutes(Task task) {
    return _adjustedReminderMinutes[task.id] ?? task.reminderMinutes;
  }

  int? _getNextReminderOption(int current, int original) {
    final currentIndex = _reminderOptions.indexOf(current);
    if (currentIndex == -1 || currentIndex >= _reminderOptions.length - 1) {
      return original;
    }
    return _reminderOptions[currentIndex + 1];
  }

  double _getOffsetForDateTime(DateTime dateTime) {
    return TimelineOffset.forDateTime(
      dateTime: dateTime,
      referenceDate: widget.referenceDate,
      hourHeight: widget.hourHeight,
      daysLoadedBefore: widget.daysLoadedBefore,
      daysLoadedAfter: widget.daysLoadedAfter,
      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
    );
  }

  DateTime _getDateTimeAtOffset(double offset) {
    return TimelineOffset.atOffset(
      offset: offset,
      referenceDate: widget.referenceDate,
      hourHeight: widget.hourHeight,
      daysLoadedBefore: widget.daysLoadedBefore,
      daysLoadedAfter: widget.daysLoadedAfter,
      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
    );
  }

  void _onDragStart(Task task, double currentTop) {
    setState(() {
      _draggingTask = task;
      _dragStartTop = currentTop;
      _dragOffsetY = 0.0;
    });
    HapticFeedback.mediumImpact();
  }

  void _onDragUpdate(double deltaY) {
    if (_draggingTask == null) return;
    setState(() {
      _dragOffsetY += deltaY;
    });
  }

  Future<bool?> _showMoveRecurringDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Recurring Task'),
        content: const Text(
          'Do you want to move only this instance or all future instances?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('This instance'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('All future'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDragEnd() async {
    if (_draggingTask == null) return;

    final task = _draggingTask!;
    final newTop = _dragStartTop + _dragOffsetY;

    // Account for timeline direction when getting time from offset
    final rawDateTime = widget.upcomingTasksAboveNow
        ? _getDateTimeAtOffset(newTop + _calculateHeight(task.duration))
        : _getDateTimeAtOffset(newTop);

    // Snap to 5-minute intervals
    final snappedMinutes = (rawDateTime.minute / 5).round() * 5;
    final snappedStart = DateTime(
      rawDateTime.year,
      rawDateTime.month,
      rawDateTime.day,
      rawDateTime.hour + (snappedMinutes >= 60 ? 1 : 0),
      snappedMinutes % 60,
    );
    final newEndTime = snappedStart.add(task.duration);

    // Clear drag state first so UI updates
    setState(() {
      _draggingTask = null;
      _dragOffsetY = 0.0;
      _dragStartTop = 0.0;
    });

    // Check if this is a recurring task
    if (task.recurringTemplateId != null) {
      final editAll = await _showMoveRecurringDialog(context);
      if (editAll == null) return; // Cancelled

      if (editAll) {
        // Calculate time delta and apply to all future instances
        final timeDelta = snappedStart.difference(task.startTime);

        await ref.read(taskRepositoryProvider).updateFutureByTemplateId(
              task.recurringTemplateId!,
              task.startTime,
              (existingTask) => existingTask.copyWith(
                startTime: existingTask.startTime.add(timeDelta),
                endTime: existingTask.endTime.add(timeDelta),
                updatedAt: DateTime.now(),
              ),
            );
        ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
        HapticFeedback.lightImpact();
        return;
      }
    }

    // Update single instance
    final updated = task.copyWith(
      startTime: snappedStart,
      endTime: newEndTime,
      updatedAt: DateTime.now(),
    );
    await ref.read(taskRepositoryProvider).save(updated);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
    HapticFeedback.lightImpact();
  }

  void _onDragCancel() {
    setState(() {
      _draggingTask = null;
      _dragOffsetY = 0.0;
      _dragStartTop = 0.0;
    });
  }

  DateTime? _getDragPreviewTime() {
    if (_draggingTask == null) return null;

    final newTop = _dragStartTop + _dragOffsetY;
    final rawDateTime = widget.upcomingTasksAboveNow
        ? _getDateTimeAtOffset(
            newTop + _calculateHeight(_draggingTask!.duration))
        : _getDateTimeAtOffset(newTop);

    // Snap to 5-minute intervals
    final snappedMinutes = (rawDateTime.minute / 5).round() * 5;
    return DateTime(
      rawDateTime.year,
      rawDateTime.month,
      rawDateTime.day,
      rawDateTime.hour + (snappedMinutes >= 60 ? 1 : 0),
      snappedMinutes % 60,
    );
  }

  // ============ Long-press task creation methods ============
  // Using Listener + Timer for web compatibility (GestureDetector long-press
  // doesn't work well on web due to scroll view gesture conflicts)

  /// Snap a DateTime to configurable minute intervals
  DateTime _snapToInterval(DateTime time, int intervalMinutes) {
    final snappedMinutes =
        (time.minute / intervalMinutes).round() * intervalMinutes;
    int hour = time.hour;
    int minute = snappedMinutes;
    if (minute >= 60) {
      hour += 1;
      minute = 0;
    }
    return DateTime(time.year, time.month, time.day, hour, minute);
  }

  /// Called when pointer goes down - starts the long-press timer
  void _onPointerDown(PointerDownEvent event, double localY, double maxWidth) {
    _longPressTimer?.cancel();

    // Store initial position for later
    final startX = event.localPosition.dx;
    final startY = localY;

    setState(() {
      _isWaitingForLongPress = true;
      _createTaskStartX = startX;
      _createTaskStartY = startY;
      _createTaskCurrentY = startY;
    });

    // Start timer - if it completes without being cancelled, trigger long-press
    _longPressTimer = Timer(_longPressDuration, () {
      if (!_isWaitingForLongPress) return;

      // Long press triggered!
      final settings = ref.read(settingsProvider);
      final snapInterval = settings.longPressSnapIntervalMinutes;
      final rawDateTime = _getDateTimeAtOffset(startY);
      final snappedStart = _snapToInterval(rawDateTime, snapInterval);

      setState(() {
        _isWaitingForLongPress = false;
        _isCreatingTask = true;
        _createTaskStartTime = snappedStart;
        _lastSnappedMinutes = snappedStart.hour * 60 + snappedStart.minute;
      });

      HapticFeedback.mediumImpact();
    });
  }

  /// Called when pointer moves - update drag position or cancel if moved too much before long-press
  void _onPointerMove(PointerMoveEvent event, double localY, double maxWidth) {
    // If still waiting for long-press, check if we moved too much (cancel threshold)
    if (_isWaitingForLongPress) {
      final dx = event.localPosition.dx - (_createTaskStartX ?? 0);
      final dy = localY - (_createTaskStartY ?? 0);
      final distance = (dx * dx + dy * dy);

      // If moved more than 20 pixels, cancel the long-press wait
      if (distance > 400) {
        // 20^2 = 400
        _cancelLongPressWait();
        return;
      }
    }

    // If already creating task, update the drag position
    if (_isCreatingTask && _createTaskStartY != null) {
      // Check for cancel gesture (dragged too far left or right)
      final currentX = event.localPosition.dx;
      if (currentX < -50 || currentX > maxWidth + 50) {
        _onCreateTaskCancel();
        return;
      }

      setState(() {
        _createTaskCurrentY = localY;
      });

      // Check if we've snapped to a new 15-minute interval and provide haptic feedback
      final endTime = _getCreateTaskEndTime();
      if (endTime != null) {
        final endMinutes = endTime.hour * 60 + endTime.minute;
        if (endMinutes != _lastSnappedMinutes) {
          _lastSnappedMinutes = endMinutes;
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  /// Called when pointer is released
  void _onPointerUp(PointerUpEvent event) {
    // If still waiting for long-press, just cancel
    if (_isWaitingForLongPress) {
      _cancelLongPressWait();
      return;
    }

    // If creating task, finalize it
    if (_isCreatingTask && _createTaskStartTime != null) {
      final settings = ref.read(settingsProvider);
      final defaultDuration = settings.longPressDefaultDurationMinutes;
      final snapInterval = settings.longPressSnapIntervalMinutes;

      final startTime = _createTaskStartTime!;
      final endTime = _getCreateTaskEndTime() ??
          startTime.add(Duration(minutes: defaultDuration));

      // Ensure minimum duration equals snap interval
      final duration = endTime.difference(startTime);
      final finalEndTime = duration.inMinutes < snapInterval
          ? startTime.add(Duration(minutes: snapInterval))
          : endTime;

      // Reset state before navigation
      setState(() {
        _isCreatingTask = false;
        _createTaskStartY = null;
        _createTaskCurrentY = null;
        _createTaskStartX = null;
        _createTaskStartTime = null;
        _lastSnappedMinutes = -1;
      });

      HapticFeedback.lightImpact();

      // Navigate to task detail screen with pre-filled times
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(
            initialStartTime: startTime,
            initialEndTime: finalEndTime,
          ),
        ),
      );
    }
  }

  /// Called when pointer is cancelled (e.g., scroll took over)
  void _onPointerCancel(PointerCancelEvent event) {
    _cancelLongPressWait();
    if (_isCreatingTask) {
      _onCreateTaskCancel();
    }
  }

  /// Cancel the long-press wait (timer)
  void _cancelLongPressWait() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (_isWaitingForLongPress) {
      setState(() {
        _isWaitingForLongPress = false;
        _createTaskStartX = null;
        _createTaskStartY = null;
        _createTaskCurrentY = null;
      });
    }
  }

  void _onCreateTaskCancel() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    setState(() {
      _isWaitingForLongPress = false;
      _isCreatingTask = false;
      _createTaskStartY = null;
      _createTaskCurrentY = null;
      _createTaskStartX = null;
      _createTaskStartTime = null;
      _lastSnappedMinutes = -1;
    });
  }

  /// Dismisses the long-press hint tooltip and persists the setting.
  void _dismissLongPressHint() {
    setState(() {
      _tooltipDismissed = true;
    });
    ref.read(settingsProvider.notifier).setHasSeenLongPressHint(true);
  }

  /// Get the end time based on drag position, snapped to configurable interval
  DateTime? _getCreateTaskEndTime() {
    if (_createTaskStartTime == null ||
        _createTaskStartY == null ||
        _createTaskCurrentY == null) {
      return null;
    }

    final settings = ref.read(settingsProvider);
    final defaultDuration = settings.longPressDefaultDurationMinutes;
    final snapInterval = settings.longPressSnapIntervalMinutes;

    // Calculate duration based on drag distance
    final dragDelta = _createTaskCurrentY! - _createTaskStartY!;

    // Convert pixel delta to duration (accounting for timeline direction)
    double hoursDelta;
    if (widget.upcomingTasksAboveNow) {
      // Dragging down (positive delta) = extending into the past = negative time
      // Dragging up (negative delta) = extending into the future = positive time
      // But for task creation, we want drag DOWN to extend the END time (make it later)
      hoursDelta = -dragDelta / widget.hourHeight;
    } else {
      // Normal orientation: drag down = later time
      hoursDelta = dragDelta / widget.hourHeight;
    }

    // Default duration (from settings) + any drag extension
    final totalMinutes = defaultDuration + (hoursDelta * 60).round();

    // Ensure minimum equals snap interval
    final clampedMinutes =
        totalMinutes < snapInterval ? snapInterval : totalMinutes;

    final rawEndTime =
        _createTaskStartTime!.add(Duration(minutes: clampedMinutes));
    return _snapToInterval(rawEndTime, snapInterval);
  }

  /// Calculate the visual bounds for the task creation preview
  ({double top, double height, Duration duration})
      _getCreateTaskPreviewBounds() {
    if (_createTaskStartTime == null) {
      return (top: 0, height: 0, duration: Duration.zero);
    }

    final settings = ref.read(settingsProvider);
    final defaultDuration = settings.longPressDefaultDurationMinutes;
    final endTime = _getCreateTaskEndTime() ??
        _createTaskStartTime!.add(Duration(minutes: defaultDuration));
    final duration = endTime.difference(_createTaskStartTime!);

    // Calculate positions
    final startOffset = _getOffsetForDateTime(_createTaskStartTime!);
    final endOffset = _getOffsetForDateTime(endTime);

    // Handle timeline direction
    final top = widget.upcomingTasksAboveNow
        ? endOffset // When future is above, end is visually higher (smaller Y)
        : startOffset;
    final height = (startOffset - endOffset).abs();

    return (top: top, height: height, duration: duration);
  }

  /// Check if the new task time range overlaps with any existing tasks
  bool _checkForConflicts(
      DateTime startTime, DateTime endTime, List<Task> existingTasks) {
    for (final task in existingTasks) {
      // Two time ranges overlap if one starts before the other ends
      if (startTime.isBefore(task.endTime) && endTime.isAfter(task.startTime)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForRangeProvider(widget.loadedRange));

    return tasksAsync.when(
      loading: () => _buildTasksLayout(context, []),
      error: (error, stack) => _buildTasksLayout(context, []),
      data: (tasks) => _buildTasksLayout(context, tasks),
    );
  }

  Widget _buildTasksLayout(BuildContext context, List<Task> tasks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final overlappingGroups = _groupOverlappingTasks(tasks);
        final positionedCards = <Widget>[];

        final settings = ref.watch(settingsProvider);
        final use24Hour = settings.use24HourFormat;

        // Minimum width for a readable task card title
        const minReadableWidth = 120.0;

        for (final group in overlappingGroups) {
          final columnWidth = availableWidth / group.length;
          final useColumns = columnWidth >= minReadableWidth;

          if (group.length == 1 || useColumns) {
            // Render individual TaskCards (side-by-side if multiple)
            for (int i = 0; i < group.length; i++) {
              final task = group[i];
              final reminderState = _getReminderState(task);
              final effectiveMinutes = _getEffectiveReminderMinutes(task);
              final reminderTime = effectiveMinutes != null
                  ? task.startTime.subtract(Duration(minutes: effectiveMinutes))
                  : null;

              final isDragging = _draggingTask?.id == task.id;
              final cardTop = isDragging
                  ? _dragStartTop + _dragOffsetY
                  : _calculateTop(task.startTime, task.duration);

              // Calculate horizontal position for side-by-side layout
              final left = i * columnWidth;
              final cardWidth = columnWidth - 4;

              // Show preview time while dragging
              Task displayTask = task;
              if (isDragging) {
                final previewTime = _getDragPreviewTime();
                if (previewTime != null) {
                  displayTask = task.copyWith(
                    startTime: previewTime,
                    endTime: previewTime.add(task.duration),
                  );
                }
              }

              positionedCards.add(
                Positioned(
                  top: cardTop,
                  left: left,
                  width: cardWidth,
                  height: _calculateHeight(task.duration),
                  child: GestureDetector(
                    onLongPressStart: (_) => _onDragStart(
                      task,
                      _calculateTop(task.startTime, task.duration),
                    ),
                    onLongPressMoveUpdate: (details) => _onDragUpdate(
                        details.localOffsetFromOrigin.dy - _dragOffsetY),
                    onLongPressEnd: (_) => _onDragEnd(),
                    onLongPressCancel: _onDragCancel,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: isDragging ? 0 : 200),
                      transform: isDragging
                          ? (Matrix4.identity()..scaleByDouble(1.03, 1.03, 1.0, 1.0))
                          : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      decoration: isDragging
                          ? BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            )
                          : null,
                      child: TaskCard(
                        task: displayTask,
                        reminderState: reminderState,
                        reminderTime: reminderTime,
                        onTap: isDragging
                            ? null
                            : () => _openTaskDetail(context, task),
                        onComplete: isDragging
                            ? null
                            : () => _toggleComplete(ref, task),
                        onDelete:
                            isDragging ? null : () => _deleteTask(ref, task),
                        onReminderAcknowledged:
                            reminderState == ReminderState.triggered
                                ? () => _acknowledgeReminder(task.id)
                                : null,
                        onReminderRescheduled:
                            reminderState == ReminderState.acknowledged
                                ? () => _rescheduleReminder(task)
                                : null,
                        use24HourFormat: use24Hour,
                      ),
                    ),
                  ),
                ),
              );
            }
          } else {
            // Multiple tasks too narrow - render MergedTaskCard (Confluent Merge)
            final earliestStart = group
                .map((t) => t.startTime)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            final latestEnd = group
                .map((t) => t.endTime)
                .reduce((a, b) => a.isAfter(b) ? a : b);
            final mergedDuration = latestEnd.difference(earliestStart);

            final cardTop = _calculateTop(earliestStart, mergedDuration);
            final cardHeight = _calculateHeight(mergedDuration);

            // Build reminder states and times maps
            final reminderStates = <String, ReminderState>{};
            final reminderTimes = <String, DateTime>{};
            for (final task in group) {
              final state = _getReminderState(task);
              if (state != null) {
                reminderStates[task.id] = state;
              }
              final effectiveMinutes = _getEffectiveReminderMinutes(task);
              if (effectiveMinutes != null) {
                reminderTimes[task.id] = task.startTime.subtract(
                  Duration(minutes: effectiveMinutes),
                );
              }
            }

            positionedCards.add(
              Positioned(
                top: cardTop,
                left: 0,
                width: availableWidth - 4,
                height: cardHeight,
                child: MergedTaskCard(
                  tasks: group,
                  use24HourFormat: use24Hour,
                  reminderStates: reminderStates,
                  reminderTimes: reminderTimes,
                  onTap: () => _showConfluenceModal(context, group, use24Hour),
                  onTapTask: (task) => _openTaskDetail(context, task),
                ),
              ),
            );
          }
        }

        final reminderDots = _buildReminderDots(tasks);

        return Stack(
          children: [
            // Background listener for long-press task creation
            // Uses Listener + Timer instead of GestureDetector for web compatibility
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final localY = event.localPosition.dy;
                  _onPointerDown(event, localY, availableWidth);
                },
                onPointerMove: (event) {
                  final localY = event.localPosition.dy;
                  _onPointerMove(event, localY, availableWidth);
                },
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: const SizedBox.expand(),
              ),
            ),
            ...reminderDots,
            ...positionedCards,
            // Task creation preview box
            if (_isCreatingTask && _createTaskStartTime != null)
              Builder(
                builder: (context) {
                  final bounds = _getCreateTaskPreviewBounds();
                  final endTime = _getCreateTaskEndTime() ??
                      _createTaskStartTime!.add(const Duration(hours: 1));
                  final hasConflict =
                      _checkForConflicts(_createTaskStartTime!, endTime, tasks);

                  return Positioned(
                    top: bounds.top,
                    left: 0,
                    right: 4,
                    height: bounds.height.clamp(40.0, double.infinity),
                    child: TaskCreationPreview(
                      startTime: _createTaskStartTime!,
                      endTime: endTime,
                      duration: bounds.duration,
                      use24HourFormat: use24Hour,
                      hasConflict: hasConflict,
                    ),
                  );
                },
              ),
            // Onboarding tooltip for long-press task creation
            if (!_tooltipDismissed &&
                !settings.hasSeenLongPressHint &&
                !_isCreatingTask)
              LongPressHintTooltip(
                onDismiss: () => _dismissLongPressHint(),
              ),
          ],
        );
      },
    );
  }

  void _acknowledgeReminder(String taskId) {
    setState(() {
      _acknowledgedReminders.add(taskId);
    });
  }

  void _rescheduleReminder(Task task) {
    setState(() {
      _acknowledgedReminders.remove(task.id);
      _windowRaisedForTasks.remove(task.id);
      final current =
          _getEffectiveReminderMinutes(task) ?? task.reminderMinutes!;
      final next = _getNextReminderOption(current, task.reminderMinutes!);
      if (next != null && next != task.reminderMinutes) {
        _adjustedReminderMinutes[task.id] = next;
      } else {
        _adjustedReminderMinutes.remove(task.id);
      }
    });
  }

  void _showConfluenceModal(
    BuildContext context,
    List<Task> tasks,
    bool use24Hour,
  ) {
    // Build reminder states and times for the modal
    final reminderStates = <String, ReminderState>{};
    final reminderTimes = <String, DateTime>{};
    for (final task in tasks) {
      final state = _getReminderState(task);
      if (state != null) {
        reminderStates[task.id] = state;
      }
      final effectiveMinutes = _getEffectiveReminderMinutes(task);
      if (effectiveMinutes != null) {
        reminderTimes[task.id] = task.startTime.subtract(
          Duration(minutes: effectiveMinutes),
        );
      }
    }

    showConfluenceModal(
      context: context,
      tasks: tasks,
      use24HourFormat: use24Hour,
      reminderStates: reminderStates,
      reminderTimes: reminderTimes,
      onTaskTap: (task) {
        Navigator.of(context).pop();
        _openTaskDetail(context, task);
      },
      onTaskComplete: (task) {
        _toggleComplete(ref, task);
      },
      onTaskDelete: (task) {
        _deleteTask(ref, task);
        Navigator.of(context).pop();
      },
      onReminderAcknowledged: (task) {
        _acknowledgeReminder(task.id);
      },
      onReminderRescheduled: (task) {
        _rescheduleReminder(task);
      },
    );
  }

  ReminderState? _getReminderState(Task task) {
    final effectiveMinutes = _getEffectiveReminderMinutes(task);
    if (effectiveMinutes == null || task.isCompleted) return null;

    final now = DateTime.now();
    final reminderTime = task.startTime.subtract(
      Duration(minutes: effectiveMinutes),
    );
    final secondsUntilReminder = reminderTime.difference(now).inSeconds;
    final secondsUntilTask = task.startTime.difference(now).inSeconds;
    final minutesUntilReminder = secondsUntilReminder ~/ 60;

    if (secondsUntilTask <= 0) {
      _acknowledgedReminders.remove(task.id);
      _adjustedReminderMinutes.remove(task.id);
      _windowRaisedForTasks.remove(task.id);
      return null;
    }

    if (_acknowledgedReminders.contains(task.id)) {
      return ReminderState.acknowledged;
    }

    if (secondsUntilReminder <= 0) {
      if (!_windowRaisedForTasks.contains(task.id)) {
        final settings = ref.read(settingsProvider);
        if (settings.bringWindowToFrontOnReminder) {
          WindowToFront.activate();
        }
        if (settings.reminderSoundEnabled) {
          ReminderSoundService.play(settings.reminderSound);
        }
        _windowRaisedForTasks.add(task.id);
      }
      return ReminderState.triggered;
    }

    if (minutesUntilReminder > 60) return null;

    if (minutesUntilReminder <= 5) {
      return ReminderState.imminent;
    } else if (minutesUntilReminder <= 15) {
      return ReminderState.approaching;
    }
    return ReminderState.distant;
  }

  List<Widget> _buildReminderDots(List<Task> tasks) {
    final dots = <Widget>[];

    for (final task in tasks) {
      final state = _getReminderState(task);
      if (state == null || state == ReminderState.acknowledged) continue;

      final effectiveMinutes = _getEffectiveReminderMinutes(task);
      if (effectiveMinutes == null) continue;

      final reminderTime = task.startTime.subtract(
        Duration(minutes: effectiveMinutes),
      );
      final reminderY = _getOffsetForDateTime(reminderTime);

      dots.add(
        Positioned(
          left: 4,
          top: reminderY - 5,
          child: ReminderDot(state: state),
        ),
      );
    }

    return dots;
  }

  double _calculateTop(DateTime startTime, Duration duration) {
    final topTime =
        widget.upcomingTasksAboveNow ? startTime.add(duration) : startTime;
    return _getOffsetForDateTime(topTime);
  }

  double _calculateHeight(Duration duration) {
    final durationMinutes = duration.inMinutes.toDouble();
    return (durationMinutes / 60) * widget.hourHeight;
  }

  bool _tasksOverlap(Task a, Task b) {
    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  List<List<Task>> _groupOverlappingTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final groups = <List<Task>>[];
    for (final task in sorted) {
      bool addedToGroup = false;
      for (final group in groups) {
        if (group.any((t) => _tasksOverlap(t, task))) {
          group.add(task);
          addedToGroup = true;
          break;
        }
      }
      if (!addedToGroup) {
        groups.add([task]);
      }
    }
    return groups;
  }

  void _openTaskDetail(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  Future<void> _toggleComplete(WidgetRef ref, Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await ref.read(taskRepositoryProvider).save(updated);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
  }

  Future<void> _deleteTask(WidgetRef ref, Task task) async {
    await ref.read(taskRepositoryProvider).delete(task.id);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
  }
}
