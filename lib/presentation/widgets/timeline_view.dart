import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';

/// The main scrollable timeline widget.
///
/// Displays a vertical timeline with hour markers on the left
/// and task cards positioned according to their scheduled times.
/// Auto-scrolls in real-time to keep the NOW line fixed.
class TimelineView extends ConsumerStatefulWidget {
  /// The date being displayed.
  final DateTime selectedDate;

  const TimelineView({
    super.key,
    required this.selectedDate,
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

  /// Total timeline height (24 hours).
  static const double _totalHeight = 24 * _hourHeight;

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
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final fractionOfDay = minutesSinceMidnight / (24 * 60);

    // The position of NOW in timeline pixels
    final nowPixelPosition = fractionOfDay * _totalHeight;

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

    final targetOffset = hour * _hourHeight;
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
                    child: _HourMarkers(hourHeight: _hourHeight),
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
                      selectedDate: widget.selectedDate,
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

  const _HourMarkers({required this.hourHeight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor =
        isDark ? AppColors.hourMarkerDark : AppColors.hourMarkerLight;

    return Stack(
      children: List.generate(25, (hour) {
        final label = _formatHour(hour);
        return Positioned(
          top: hour * hourHeight - 8,
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
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

/// Layer containing positioned task cards.
class _TaskCardsLayer extends ConsumerWidget {
  final double hourHeight;
  final DateTime selectedDate;

  const _TaskCardsLayer({
    required this.hourHeight,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch tasks provider for selectedDate
    // For now, show empty state or sample tasks

    return Stack(
      children: [
        // Empty state centered in viewport
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first task',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                ),
              ],
            ),
          ),
        ),

        // TODO: Map actual tasks to TaskCard widgets positioned by time
        // Example:
        // Positioned(
        //   top: _calculateTop(task.startTime),
        //   left: 0,
        //   right: 0,
        //   height: _calculateHeight(task.duration),
        //   child: TaskCard(task: task),
        // ),
      ],
    );
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
