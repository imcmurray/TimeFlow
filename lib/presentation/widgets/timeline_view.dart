import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';

/// The main scrollable timeline widget.
///
/// Displays a vertical timeline with hour markers on the left
/// and task cards positioned according to their scheduled times.
/// Auto-scrolls in real-time to keep the NOW line fixed.
class TimelineView extends ConsumerStatefulWidget {
  /// The date being displayed.
  final DateTime selectedDate;

  /// Whether upcoming tasks appear above the NOW line.
  /// When true, later times render at the top and earlier times at the bottom.
  final bool upcomingTasksAboveNow;

  const TimelineView({
    super.key,
    required this.selectedDate,
    this.upcomingTasksAboveNow = true,
  });

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  DateTime? _lastAutoScrollTime;

  /// Height in pixels per hour of timeline.
  static const double _hourHeight = 80.0;

  /// Total timeline height (30 hours: current day + 6 hours into next day).
  static const double _totalHeight = 30 * _hourHeight;

  /// Position of NOW line as fraction from top (0.75 = 75% down).
  static const double _nowLinePosition = 0.75;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Wait for first frame then scroll to current time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime(animated: false);
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      // Date changed, scroll to appropriate position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isToday) {
          _scrollToCurrentTime(animated: true);
        } else {
          // Scroll to 8 AM for non-today dates
          _scrollToHour(8, animated: true);
        }
      });
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
  }

  /// Calculate the scroll offset needed to position the NOW line at 75% down.
  double _calculateNowScrollOffset() {
    final now = DateTime.now();
    // Use same coordinate system as hour markers and task positions
    final hourOfDay = now.hour + (now.minute / 60.0);
    final effectiveHour =
        widget.upcomingTasksAboveNow ? (30 - hourOfDay) : hourOfDay;

    // The position of NOW in timeline pixels
    final nowPixelPosition = effectiveHour * _hourHeight;

    // We want this position to appear at _nowLinePosition of the viewport
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = nowPixelPosition - (viewportHeight * _nowLinePosition);

    return targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
  }

  void _scrollToCurrentTime({required bool animated}) {
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

  void _scrollToHour(int hour, {required bool animated}) {
    if (!_scrollController.hasClients) return;

    // Invert hour position when upcomingTasksAboveNow is true (30-hour timeline)
    final effectiveHour = widget.upcomingTasksAboveNow ? (30 - hour) : hour;
    final targetOffset = effectiveHour * _hourHeight;
    final clampedOffset = targetOffset.clamp(
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

    if (!_isToday) return;

    // Update every second for smooth auto-scroll
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isUserScrolling && _isToday && _scrollController.hasClients) {
        final targetOffset = _calculateNowScrollOffset();
        final currentOffset = _scrollController.offset;

        // Only auto-scroll if we're close to where we should be
        // (user hasn't scrolled far away)
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          // Check if this is a user-initiated scroll
          if (notification.dragDetails != null) {
            _isUserScrolling = true;
          }
        } else if (notification is ScrollEndNotification) {
          // Resume auto-scroll after a delay
          _isUserScrolling = false;
        }
        return false;
      },
      child: Stack(
        children: [
          // Main scrollable timeline
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: _totalHeight + MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // Hour markers column
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 60,
                    child: _HourMarkers(
                      hourHeight: _hourHeight,
                      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                    ),
                  ),

                  // Timeline line
                  Positioned(
                    left: 56,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: Container(
                      color: isDark
                          ? AppColors.timelineDark
                          : AppColors.timelineLight,
                    ),
                  ),

                  // Task cards area
                  Positioned(
                    left: 70,
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: _TaskCardsLayer(
                      hourHeight: _hourHeight,
                      totalHeight: _totalHeight,
                      selectedDate: widget.selectedDate,
                      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Jump to NOW button (only shown when scrolled away)
          if (_isToday)
            Positioned(
              bottom: 80,
              right: 16,
              child: _JumpToNowButton(onTap: () {
                _scrollToCurrentTime(animated: true);
              }),
            ),
        ],
      ),
    );
  }
}

/// Displays hour markers on the left side of the timeline.
class _HourMarkers extends StatelessWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;

  const _HourMarkers({
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor =
        isDark ? AppColors.hourMarkerDark : AppColors.hourMarkerLight;

    return Stack(
      children: List.generate(31, (hour) {
        // Wrap hour labels at 24 (so hour 25 shows as 1 AM, etc.)
        final label = _formatHour(hour % 24);
        // Invert position when upcomingTasksAboveNow is true (30-hour timeline)
        final effectiveHour = upcomingTasksAboveNow ? (30 - hour) : hour;
        return Positioned(
          top: effectiveHour * hourHeight - 8,
          left: 8,
          right: 8,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: markerColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        );
      }),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

/// Layer containing positioned task cards.
class _TaskCardsLayer extends ConsumerWidget {
  final double hourHeight;
  final double totalHeight;
  final DateTime selectedDate;
  final bool upcomingTasksAboveNow;

  const _TaskCardsLayer({
    required this.hourHeight,
    required this.totalHeight,
    required this.selectedDate,
    required this.upcomingTasksAboveNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksForDateProvider(selectedDate));

    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final overlappingGroups = _groupOverlappingTasks(tasks);
        final positionedCards = <Widget>[];

        for (final group in overlappingGroups) {
          final columnCount = group.length;
          for (int i = 0; i < group.length; i++) {
            final task = group[i];
            final columnWidth = availableWidth / columnCount;
            final left = i * columnWidth;

            positionedCards.add(
              Positioned(
                top: _calculateTop(task.startTime, task.duration),
                left: left,
                width: columnWidth - 4,
                height: _calculateHeight(task.duration),
                child: TaskCard(
                  task: task,
                  onTap: () => _openTaskDetail(context, task),
                  onComplete: () => _toggleComplete(ref, task),
                  onDelete: () => _deleteTask(ref, task),
                ),
              ),
            );
          }
        }

        return Stack(children: positionedCards);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTop(DateTime startTime, Duration duration) {
    // When future is above (upcomingTasksAboveNow=true), the TOP of the card
    // should align with the END time (which is higher on screen since future is up).
    // When past is above, the TOP aligns with START time as usual.
    final topTime = upcomingTasksAboveNow ? startTime.add(duration) : startTime;

    final hourOfDay = topTime.hour + (topTime.minute / 60.0);
    final effectiveHour = upcomingTasksAboveNow ? (30 - hourOfDay) : hourOfDay;

    return effectiveHour * hourHeight;
  }

  double _calculateHeight(Duration duration) {
    final durationMinutes = duration.inMinutes.toDouble();
    return (durationMinutes / 60) * hourHeight;
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

  void _toggleComplete(WidgetRef ref, Task task) {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    ref.read(taskRepositoryProvider).save(updated);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
  }

  void _deleteTask(WidgetRef ref, Task task) {
    ref.read(taskRepositoryProvider).delete(task.id);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();
  }
}

/// Button to jump back to the current time.
class _JumpToNowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _JumpToNowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'jumpToNow',
      onPressed: onTap,
      tooltip: 'Jump to now',
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      child: const Icon(Icons.my_location),
    );
  }
}
