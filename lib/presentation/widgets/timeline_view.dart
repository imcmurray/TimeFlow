import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/widgets/ambient_particles.dart';
import 'package:timeflow/presentation/widgets/breathing_room_indicator.dart';
import 'package:timeflow/presentation/widgets/confluence_modal.dart';
import 'package:timeflow/presentation/widgets/day_boundary_marker.dart';
import 'package:timeflow/presentation/widgets/merged_task_card.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';
import 'package:timeflow/presentation/widgets/time_of_day_background.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:window_to_front/window_to_front.dart';

/// The main scrollable timeline widget with continuous multi-day flow.
///
/// Displays a vertical timeline that spans multiple days seamlessly,
/// with day dividers at midnight boundaries. Auto-scrolls to keep
/// the NOW line fixed when viewing today.
class TimelineView extends ConsumerStatefulWidget {
  /// Whether upcoming tasks appear above the NOW line.
  final bool upcomingTasksAboveNow;

  /// Initial date to scroll to on first build. If null, scrolls to NOW.
  final DateTime? initialDate;

  /// Called when the visible date changes as the user scrolls.
  final ValueChanged<DateTime>? onVisibleDateChanged;

  /// Called when NOW line visibility changes.
  final ValueChanged<bool>? onNowLineVisibilityChanged;

  const TimelineView({
    super.key,
    this.upcomingTasksAboveNow = true,
    this.initialDate,
    this.onVisibleDateChanged,
    this.onNowLineVisibilityChanged,
  });

  @override
  ConsumerState<TimelineView> createState() => TimelineViewState();
}

class TimelineViewState extends ConsumerState<TimelineView> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  Timer? _timeUpdateTimer;
  bool _isUserScrolling = false;
  bool _wasNowLineVisible = true;
  DateTime? _lastReportedVisibleDate;
  DateTime _currentTime = DateTime.now();

  /// Height in pixels per hour of timeline.
  static const double _hourHeight = 80.0;

  /// Position of NOW line as fraction from top (0.75 = 75% down).
  static const double _nowLinePosition = 0.75;

  /// Number of days to load in each direction from today.
  int _daysLoadedBefore = 7;
  int _daysLoadedAfter = 7;

  /// Reference point: midnight of today (local time).
  late DateTime _referenceDate;

  /// Currently loaded date range.
  late DateRange _loadedRange;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Set reference to today's midnight
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);

    // Initialize loaded range
    _updateLoadedRange();

    // Wait for first frame then scroll to initial position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDate != null) {
        scrollToDate(widget.initialDate!, animated: false);
      } else {
        _scrollToNow(animated: false);
      }
      _startAutoScroll();
    });

    // Listen to scroll changes
    _scrollController.addListener(_onScroll);

    // Update current time every second for NOW line
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _updateLoadedRange() {
    _loadedRange = DateRange(
      _referenceDate.subtract(Duration(days: _daysLoadedBefore)),
      _referenceDate.add(Duration(days: _daysLoadedAfter)),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Total number of days in the loaded range.
  int get _totalDays => _daysLoadedBefore + _daysLoadedAfter + 1;

  /// Total timeline height in pixels.
  double get _totalHeight => _totalDays * 24 * _hourHeight;

  /// Calculate pixel offset for a given DateTime.
  double _getOffsetForDateTime(DateTime dateTime) {
    final hoursFromReference =
        dateTime.difference(_referenceDate).inMinutes / 60.0;

    if (widget.upcomingTasksAboveNow) {
      // When future is above, today is _daysLoadedAfter days from the top
      final referenceOffset = _daysLoadedAfter * 24 * _hourHeight;
      return referenceOffset - (hoursFromReference * _hourHeight);
    } else {
      // Past at top, future at bottom (natural order)
      final referenceOffset = _daysLoadedBefore * 24 * _hourHeight;
      return referenceOffset + (hoursFromReference * _hourHeight);
    }
  }

  /// Calculate DateTime for a given pixel offset.
  DateTime _getDateTimeAtOffset(double offset) {
    final referenceOffset = widget.upcomingTasksAboveNow
        ? _daysLoadedAfter * 24 * _hourHeight
        : _daysLoadedBefore * 24 * _hourHeight;

    double hoursFromReference;
    if (widget.upcomingTasksAboveNow) {
      hoursFromReference = (referenceOffset - offset) / _hourHeight;
    } else {
      hoursFromReference = (offset - referenceOffset) / _hourHeight;
    }

    return _referenceDate.add(Duration(minutes: (hoursFromReference * 60).round()));
  }

  /// Calculate scroll offset to position NOW line at 75% down viewport.
  double _calculateNowScrollOffset() {
    if (!_scrollController.hasClients) return 0;

    final now = DateTime.now();
    final nowOffset = _getOffsetForDateTime(now);
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = nowOffset - (viewportHeight * _nowLinePosition);

    return targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
  }

  void _scrollToNow({required bool animated}) {
    if (!_scrollController.hasClients) return;

    final targetOffset = _calculateNowScrollOffset();

    if (animated) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  /// Public method to jump to NOW, called from parent.
  void jumpToNow() {
    _scrollToNow(animated: true);
  }

  /// Public method to scroll to a specific date.
  void scrollToDate(DateTime date, {bool animated = true}) {
    final targetDay = DateTime(date.year, date.month, date.day);
    final daysDifference = targetDay.difference(_referenceDate).inDays;

    // Ensure the target date is within the loaded range
    bool rangeExpanded = false;
    if (daysDifference < -_daysLoadedBefore) {
      // Target is in the past, expand past range
      _daysLoadedBefore = -daysDifference + 7;
      rangeExpanded = true;
    } else if (daysDifference > _daysLoadedAfter) {
      // Target is in the future, expand future range
      _daysLoadedAfter = daysDifference + 7;
      rangeExpanded = true;
    }

    if (rangeExpanded) {
      _updateLoadedRange();
      // Rebuild and scroll after the frame
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performScrollToDate(date, animated: animated);
      });
    } else {
      _performScrollToDate(date, animated: animated);
    }
  }

  void _performScrollToDate(DateTime date, {bool animated = true}) {
    if (!_scrollController.hasClients) return;

    // Scroll to 8 AM on that date for a good viewing position
    final targetDateTime = DateTime(date.year, date.month, date.day, 8);
    final targetOffset = _getOffsetForDateTime(targetDateTime);
    final viewportHeight = _scrollController.position.viewportDimension;

    // Position the target time at 25% from top (similar to NOW line positioning)
    final adjustedOffset = targetOffset - (viewportHeight * 0.25);
    final clampedOffset = adjustedOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (animated) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    // Update every second for smooth auto-scroll
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isUserScrolling && _scrollController.hasClients) {
        final targetOffset = _calculateNowScrollOffset();
        final currentOffset = _scrollController.offset;

        // Only auto-scroll if we're close to where we should be
        if ((targetOffset - currentOffset).abs() < _hourHeight * 2) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;

    // Calculate the date at the center of the viewport
    final centerOffset = scrollOffset + (viewportHeight / 2);
    final centerDate = _getDateTimeAtOffset(centerOffset);
    final centerDay = DateTime(centerDate.year, centerDate.month, centerDate.day);

    // Report visible date changes
    if (_lastReportedVisibleDate == null ||
        _lastReportedVisibleDate!.day != centerDay.day ||
        _lastReportedVisibleDate!.month != centerDay.month ||
        _lastReportedVisibleDate!.year != centerDay.year) {
      _lastReportedVisibleDate = centerDay;
      widget.onVisibleDateChanged?.call(centerDay);
    }

    // Check if NOW line is visible
    final now = DateTime.now();
    final nowOffset = _getOffsetForDateTime(now);
    final nowLineScreenPosition = nowOffset - scrollOffset;
    final isNowVisible = nowLineScreenPosition >= 0 && nowLineScreenPosition <= viewportHeight;

    if (isNowVisible != _wasNowLineVisible) {
      _wasNowLineVisible = isNowVisible;
      widget.onNowLineVisibilityChanged?.call(isNowVisible);
    }

    // Check if we need to load more days
    _checkAndExpandRange();
  }

  void _checkAndExpandRange() {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Load more past days if scrolling near the start
    if (scrollOffset < viewportHeight * 2) {
      _loadMorePastDays();
    }

    // Load more future days if scrolling near the end
    if (scrollOffset > maxScroll - viewportHeight * 2) {
      _loadMoreFutureDays();
    }
  }

  void _loadMorePastDays() {
    final previousOffset = _scrollController.offset;
    final additionalDays = 7;
    final additionalHeight = additionalDays * 24 * _hourHeight;

    setState(() {
      _daysLoadedBefore += additionalDays;
      _updateLoadedRange();
    });

    // Maintain scroll position after adding content at the top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(previousOffset + additionalHeight);
      }
    });
  }

  void _loadMoreFutureDays() {
    setState(() {
      _daysLoadedAfter += 7;
      _updateLoadedRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final use24Hour = ref.watch(settingsProvider).use24HourFormat;
    final currentHour = _currentTime.hour;

    // Particle color based on time of day
    final particleColor = TimeOfDayBackground.getAccentColor(currentHour, isDark: isDark);

    return TimeOfDayBackground(
      hour: currentHour,
      isDark: isDark,
      child: Stack(
        children: [
          // Ambient particles layer (behind content)
          Positioned.fill(
            child: IgnorePointer(
              child: AmbientParticles(
                particleCount: 25,
                color: particleColor.withOpacity(0.4),
                driftDown: true,
                speed: 0.5,
              ),
            ),
          ),

          // Main timeline content
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  _isUserScrolling = true;
                }
              } else if (notification is ScrollEndNotification) {
                _isUserScrolling = false;
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: _totalHeight + MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    // Hour markers and day dividers
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 60,
                      child: _HourMarkersMultiDay(
                        hourHeight: _hourHeight,
                        upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                        referenceDate: _referenceDate,
                        daysLoadedBefore: _daysLoadedBefore,
                        daysLoadedAfter: _daysLoadedAfter,
                        use24HourFormat: use24Hour,
                      ),
                    ),

                    // Timeline line
                    Positioned(
                      left: 56,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(
                        color: isDark ? AppColors.timelineDark : AppColors.timelineLight,
                      ),
                    ),

                    // Day dividers (full width) - now with sunrise/sunset icons
                    _DayDividers(
                      hourHeight: _hourHeight,
                      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                      referenceDate: _referenceDate,
                      daysLoadedBefore: _daysLoadedBefore,
                      daysLoadedAfter: _daysLoadedAfter,
                    ),

                    // Task cards area with breathing room indicators
                    Positioned(
                      left: 70,
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: _TaskCardsLayerMultiDay(
                        hourHeight: _hourHeight,
                        upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                        referenceDate: _referenceDate,
                        daysLoadedBefore: _daysLoadedBefore,
                        daysLoadedAfter: _daysLoadedAfter,
                        loadedRange: _loadedRange,
                      ),
                    ),

                    // NOW line (scrolls with content)
                    _NowLineScrollable(
                      currentTime: _currentTime,
                      nowOffset: _getOffsetForDateTime(_currentTime),
                      use24HourFormat: use24Hour,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays hour markers for multiple days.
class _HourMarkersMultiDay extends StatelessWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final bool use24HourFormat;

  const _HourMarkersMultiDay({
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    this.use24HourFormat = false,
  });

  int get _totalDays => daysLoadedBefore + daysLoadedAfter + 1;

  double _getOffsetForHour(int dayOffset, int hour) {
    final hoursFromReference = (dayOffset * 24) + hour;
    final referenceOffset = upcomingTasksAboveNow
        ? daysLoadedAfter * 24 * hourHeight
        : daysLoadedBefore * 24 * hourHeight;

    if (upcomingTasksAboveNow) {
      return referenceOffset - (hoursFromReference * hourHeight);
    } else {
      return referenceOffset + (hoursFromReference * hourHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor = isDark ? AppColors.hourMarkerDark : AppColors.hourMarkerLight;

    final markers = <Widget>[];

    // Generate hour markers for each day
    for (int dayOffset = -daysLoadedBefore; dayOffset <= daysLoadedAfter; dayOffset++) {
      for (int hour = 0; hour < 24; hour++) {
        final offset = _getOffsetForHour(dayOffset, hour);
        markers.add(
          Positioned(
            top: offset - 8,
            left: 8,
            right: 8,
            child: Text(
              _formatHour(hour),
              style: TextStyle(
                fontSize: 12,
                color: markerColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        );
      }
    }

    return Stack(children: markers);
  }

  String _formatHour(int hour) {
    if (use24HourFormat) {
      return '${hour.toString().padLeft(2, '0')}:00';
    }
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

/// Displays day dividers at midnight boundaries.
class _DayDividers extends StatelessWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;

  const _DayDividers({
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
  });

  double _getOffsetForDayStart(int dayOffset) {
    final hoursFromReference = dayOffset * 24;
    final referenceOffset = upcomingTasksAboveNow
        ? daysLoadedAfter * 24 * hourHeight
        : daysLoadedBefore * 24 * hourHeight;

    if (upcomingTasksAboveNow) {
      return referenceOffset - (hoursFromReference * hourHeight);
    } else {
      return referenceOffset + (hoursFromReference * hourHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dividers = <Widget>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int dayOffset = -daysLoadedBefore; dayOffset <= daysLoadedAfter; dayOffset++) {
      final date = referenceDate.add(Duration(days: dayOffset));
      final offset = _getOffsetForDayStart(dayOffset);

      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      dividers.add(
        Positioned(
          top: offset - 16,
          left: 70,
          right: 16,
          child: SimpleDayDivider(
            date: date,
            isToday: isToday,
          ),
        ),
      );
    }

    return Stack(children: dividers);
  }
}

/// Layer containing positioned task cards for multiple days.
class _TaskCardsLayerMultiDay extends ConsumerStatefulWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final DateRange loadedRange;

  const _TaskCardsLayerMultiDay({
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    required this.loadedRange,
  });

  @override
  ConsumerState<_TaskCardsLayerMultiDay> createState() =>
      _TaskCardsLayerMultiDayState();
}

class _TaskCardsLayerMultiDayState
    extends ConsumerState<_TaskCardsLayerMultiDay> {
  final Set<String> _acknowledgedReminders = {};
  final Map<String, int> _adjustedReminderMinutes = {};
  final Set<String> _windowRaisedForTasks = {};
  Timer? _reminderCheckTimer;

  static const _reminderOptions = [60, 30, 15, 10, 5, 0];

  // Drag state for long-press task repositioning
  Task? _draggingTask;
  double _dragOffsetY = 0.0;
  double _dragStartTop = 0.0;

  @override
  void initState() {
    super.initState();
    _startReminderCheckTimer();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
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
    final hoursFromReference =
        dateTime.difference(widget.referenceDate).inMinutes / 60.0;
    final referenceOffset = widget.upcomingTasksAboveNow
        ? widget.daysLoadedAfter * 24 * widget.hourHeight
        : widget.daysLoadedBefore * 24 * widget.hourHeight;

    if (widget.upcomingTasksAboveNow) {
      return referenceOffset - (hoursFromReference * widget.hourHeight);
    } else {
      return referenceOffset + (hoursFromReference * widget.hourHeight);
    }
  }

  DateTime _getDateTimeAtOffset(double offset) {
    final referenceOffset = widget.upcomingTasksAboveNow
        ? widget.daysLoadedAfter * 24 * widget.hourHeight
        : widget.daysLoadedBefore * 24 * widget.hourHeight;

    double hoursFromReference;
    if (widget.upcomingTasksAboveNow) {
      hoursFromReference = (referenceOffset - offset) / widget.hourHeight;
    } else {
      hoursFromReference = (offset - referenceOffset) / widget.hourHeight;
    }

    return widget.referenceDate.add(Duration(minutes: (hoursFromReference * 60).round()));
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
        ? _getDateTimeAtOffset(newTop + _calculateHeight(_draggingTask!.duration))
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForRangeProvider(widget.loadedRange));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading tasks: $error')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildTasksLayout(context, tasks);
      },
    );
  }

  Widget _buildTasksLayout(BuildContext context, List<Task> tasks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final overlappingGroups = _groupOverlappingTasks(tasks);
        final positionedCards = <Widget>[];

        final use24Hour = ref.watch(settingsProvider).use24HourFormat;

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
                    onLongPressMoveUpdate: (details) => _onDragUpdate(details.localOffsetFromOrigin.dy - _dragOffsetY),
                    onLongPressEnd: (_) => _onDragEnd(),
                    onLongPressCancel: _onDragCancel,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: isDragging ? 0 : 200),
                      transform: isDragging
                          ? (Matrix4.identity()..scale(1.03))
                          : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      decoration: isDragging
                          ? BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
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
                        onTap: isDragging ? null : () => _openTaskDetail(context, task),
                        onComplete: isDragging ? null : () => _toggleComplete(ref, task),
                        onDelete: isDragging ? null : () => _deleteTask(ref, task),
                        onReminderAcknowledged: reminderState == ReminderState.triggered
                            ? () => _acknowledgeReminder(task.id)
                            : null,
                        onReminderRescheduled: reminderState == ReminderState.acknowledged
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
            ...reminderDots,
            ...positionedCards,
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
      final current = _getEffectiveReminderMinutes(task) ?? task.reminderMinutes!;
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

/// NOW line that scrolls with the timeline content.
class _NowLineScrollable extends StatelessWidget {
  final DateTime currentTime;
  final double nowOffset;
  final bool use24HourFormat;

  const _NowLineScrollable({
    required this.currentTime,
    required this.nowOffset,
    this.use24HourFormat = false,
  });

  String _formatTime(DateTime time) {
    if (use24HourFormat) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.nowLineDark : AppColors.nowLineLight;

    return Stack(
      children: [
        // Glow effect behind the line
        Positioned(
          left: 0,
          right: 0,
          top: nowOffset - 20,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0),
                  lineColor.withValues(alpha: 0.4),
                  lineColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Main NOW line
        Positioned(
          left: 0,
          right: 0,
          top: nowOffset - 1,
          height: 2,
          child: Container(
            decoration: BoxDecoration(
              color: lineColor,
              boxShadow: [
                BoxShadow(
                  color: lineColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),

        // Time badge
        Positioned(
          right: 16,
          top: nowOffset - 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: lineColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _formatTime(currentTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // NOW label
        Positioned(
          left: 12,
          top: nowOffset - 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NOW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
