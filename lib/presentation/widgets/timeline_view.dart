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
import 'package:timeflow/presentation/widgets/breathing_room_indicator.dart';
import 'package:timeflow/presentation/widgets/confluence_modal.dart';
import 'package:timeflow/presentation/widgets/day_boundary_marker.dart';
import 'package:timeflow/presentation/widgets/merged_task_card.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';
import 'package:timeflow/presentation/widgets/time_of_day_background.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:timeflow/services/sun_times_service.dart';
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

class TimelineViewState extends ConsumerState<TimelineView>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  Timer? _timeUpdateTimer;
  bool _isUserScrolling = false;
  bool _wasNowLineVisible = true;
  DateTime? _lastReportedVisibleDate;
  DateTime _currentTime = DateTime.now();
  DateTime _lastUpdateTime = DateTime.now();

  /// Height in pixels per hour of timeline.
  static const double _hourHeight = 80.0;

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

    // Register lifecycle observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);

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
        _lastUpdateTime = DateTime.now();
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
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App has come back to foreground - immediately sync the NOW line
      _syncNowLinePosition();
    }
  }

  /// Syncs the NOW line position when returning from background.
  /// This handles cases where the user left the app running and returns hours later.
  void _syncNowLinePosition() {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdateTime);

    // Always update current time
    setState(() {
      _currentTime = now;
      _lastUpdateTime = now;
    });

    // If significant time has passed (more than 30 seconds), also update reference date
    // in case we've crossed midnight while the app was in background
    if (timeSinceLastUpdate.inSeconds > 30) {
      final newReferenceDate = DateTime(now.year, now.month, now.day);
      if (newReferenceDate != _referenceDate) {
        _referenceDate = newReferenceDate;
        _updateLoadedRange();
      }

      // Jump to NOW position (animated if not too far, immediate otherwise)
      if (_scrollController.hasClients && !_isUserScrolling) {
        final targetOffset = _calculateNowScrollOffset();
        final currentOffset = _scrollController.offset;
        final distance = (targetOffset - currentOffset).abs();

        // If we've drifted significantly (more than 4 hours), jump immediately
        // Otherwise animate smoothly
        if (distance > _hourHeight * 4) {
          _scrollController.jumpTo(targetOffset);
        } else {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    }
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

  /// Calculate scroll offset to position NOW line at the user's chosen viewport position.
  double _calculateNowScrollOffset() {
    if (!_scrollController.hasClients) return 0;

    final nowLinePosition = ref.read(settingsProvider).nowLineViewportPosition;
    final nowOffset = _getOffsetForDateTime(DateTime.now());
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = nowOffset - (viewportHeight * nowLinePosition);

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

    // Calculate the NOW line offset for scrollable content
    final nowOffset = _getOffsetForDateTime(_currentTime);

    return TimeOfDayBackground(
      hour: currentHour,
      isDark: isDark,
      child: NotificationListener<ScrollNotification>(
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

                // Day watermarks (large background date numbers)
                _DayWatermarksWithTasks(
                  hourHeight: _hourHeight,
                  upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                  referenceDate: _referenceDate,
                  daysLoadedBefore: _daysLoadedBefore,
                  daysLoadedAfter: _daysLoadedAfter,
                  loadedRange: _loadedRange,
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

                // Scrollable NOW line (scrolls with content, draggable)
                Builder(
                  builder: (context) {
                    // Get current scroll position for drag calculation
                    final scrollOffset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    final viewportHeight = _scrollController.hasClients
                        ? _scrollController.position.viewportDimension
                        : MediaQuery.of(context).size.height;

                    return _NowLineScrollable(
                      currentTime: _currentTime,
                      nowOffset: nowOffset,
                      use24HourFormat: use24Hour,
                      scrollOffset: scrollOffset,
                      viewportHeight: viewportHeight,
                      onPositionChanged: () => _scrollToNow(animated: true),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays hour markers for multiple days with sunrise/sunset indicators.
class _HourMarkersMultiDay extends ConsumerWidget {
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

  double _getOffsetForHour(int dayOffset, double hour) {
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

  double _getOffsetForDateTime(int dayOffset, DateTime time) {
    final fractionalHour = time.hour + (time.minute / 60.0);
    return _getOffsetForHour(dayOffset, fractionalHour);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor = isDark ? AppColors.hourMarkerDark : AppColors.hourMarkerLight;
    final settings = ref.watch(settingsProvider);

    // Pre-calculate sun times for each day if enabled
    final Map<int, SunTimes> sunTimesMap = {};
    if (settings.showSunTimes) {
      for (int dayOffset = -daysLoadedBefore; dayOffset <= daysLoadedAfter; dayOffset++) {
        final date = referenceDate.add(Duration(days: dayOffset));
        sunTimesMap[dayOffset] = SunTimesService.calculate(
          date: date,
          latitude: settings.latitude,
          longitude: settings.longitude,
          timezoneOffsetHours: settings.timezoneOffsetHours,
        );
      }
    }

    final markers = <Widget>[];

    // Generate hour markers for each day
    for (int dayOffset = -daysLoadedBefore; dayOffset <= daysLoadedAfter; dayOffset++) {
      final sunTimes = sunTimesMap[dayOffset];

      for (int hour = 0; hour < 24; hour++) {
        final offset = _getOffsetForHour(dayOffset, hour.toDouble());

        markers.add(
          Positioned(
            top: offset - 8,
            left: 4,
            right: 4,
            child: Row(
              children: [
                const SizedBox(width: 14), // Placeholder to align text
                // Hour text
                Expanded(
                  child: Text(
                    _formatHour(hour),
                    style: TextStyle(
                      fontSize: 11,
                      color: markerColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Add exact sunrise/sunset time markers (positioned precisely between hours)
      if (settings.showSunTimes && sunTimes != null) {
        // Sunrise marker
        if (sunTimes.sunrise != null && !sunTimes.isPolarDay && !sunTimes.isPolarNight) {
          final sunriseOffset = _getOffsetForDateTime(dayOffset, sunTimes.sunrise!);
          markers.add(
            Positioned(
              top: sunriseOffset - 8,
              left: 2,
              right: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_sunny,
                    size: 10,
                    color: Color(0xFFFFB74D),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      _formatExactTime(sunTimes.sunrise!),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sunset marker
        if (sunTimes.sunset != null && !sunTimes.isPolarDay && !sunTimes.isPolarNight) {
          final sunsetOffset = _getOffsetForDateTime(dayOffset, sunTimes.sunset!);
          markers.add(
            Positioned(
              top: sunsetOffset - 8,
              left: 2,
              right: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 10,
                    color: Color(0xFF7986CB),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      _formatExactTime(sunTimes.sunset!),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF7986CB),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
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

  String _formatExactTime(DateTime time) {
    if (use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'p' : 'a';
    return '$hour:${time.minute.toString().padLeft(2, '0')}$period';
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

/// Displays large watermark dates in the background of each day.
/// Adjusts position based on task overlap to avoid covering events.
class _DayWatermarksWithTasks extends ConsumerStatefulWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final DateRange loadedRange;

  const _DayWatermarksWithTasks({
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    required this.loadedRange,
  });

  @override
  ConsumerState<_DayWatermarksWithTasks> createState() => _DayWatermarksWithTasksState();
}

class _DayWatermarksWithTasksState extends ConsumerState<_DayWatermarksWithTasks> {
  // Track which day watermarks are currently highlighted (by day offset)
  final Map<int, DateTime> _highlightedWatermarks = {};
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _onWatermarkInteraction(int dayOffset) {
    setState(() {
      _highlightedWatermarks[dayOffset] = DateTime.now();
    });
    _startHighlightTimer();
  }

  void _startHighlightTimer() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final expiredKeys = <int>[];
      for (final entry in _highlightedWatermarks.entries) {
        if (now.difference(entry.value).inSeconds >= 30) {
          expiredKeys.add(entry.key);
        }
      }
      if (expiredKeys.isNotEmpty) {
        setState(() {
          for (final key in expiredKeys) {
            _highlightedWatermarks.remove(key);
          }
        });
      }
      if (_highlightedWatermarks.isEmpty) {
        _highlightTimer?.cancel();
      }
    });
  }

  double _getOffsetForHour(int dayOffset, double hour) {
    final hoursFromReference = (dayOffset * 24) + hour;
    final referenceOffset = widget.upcomingTasksAboveNow
        ? widget.daysLoadedAfter * 24 * widget.hourHeight
        : widget.daysLoadedBefore * 24 * widget.hourHeight;

    if (widget.upcomingTasksAboveNow) {
      return referenceOffset - (hoursFromReference * widget.hourHeight);
    } else {
      return referenceOffset + (hoursFromReference * widget.hourHeight);
    }
  }

  /// Find the best start hour for watermark (moving it earlier if tasks overlap)
  int _findBestWatermarkStartHour(DateTime date, List<Task> tasks, int defaultStartHour, int watermarkHeightHours) {
    final dayStart = DateTime(date.year, date.month, date.day);

    // Try positions from the default down to 0 (midnight)
    for (int startHour = defaultStartHour; startHour >= 0; startHour--) {
      final watermarkStart = dayStart.add(Duration(hours: startHour));
      final watermarkEnd = dayStart.add(Duration(hours: startHour + watermarkHeightHours));

      bool hasOverlap = false;
      for (final task in tasks) {
        // Check if task is on this day and overlaps with watermark time range
        if (task.startTime.isBefore(watermarkEnd) && task.endTime.isAfter(watermarkStart)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return startHour;
      }
    }

    // If all positions have overlap, use 0 (midnight) and let events overwrite
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final tasksAsync = ref.watch(tasksForRangeProvider(widget.loadedRange));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasksAsync.when(
      loading: () => _buildWatermarks(context, settings, today, []),
      error: (_, __) => _buildWatermarks(context, settings, today, []),
      data: (tasks) => _buildWatermarks(context, settings, today, tasks),
    );
  }

  Widget _buildWatermarks(BuildContext context, dynamic settings, DateTime today, List<Task> tasks) {
    final watermarks = <Widget>[];

    // Default position - early morning hours (around 4-8 AM)
    const defaultWatermarkStartHour = 4;
    const watermarkHeightHours = 5; // Spans about 5 hours

    for (int dayOffset = -widget.daysLoadedBefore; dayOffset <= widget.daysLoadedAfter; dayOffset++) {
      final date = widget.referenceDate.add(Duration(days: dayOffset));

      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      // Filter tasks for this day
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayTasks = tasks.where((t) =>
        t.startTime.isBefore(dayEnd) && t.endTime.isAfter(dayStart)
      ).toList();

      // Find the best position for the watermark (avoiding task overlap)
      final watermarkStartHour = _findBestWatermarkStartHour(
        date, dayTasks, defaultWatermarkStartHour, watermarkHeightHours
      );

      // Calculate position for this day's watermark
      final topOffset = _getOffsetForHour(dayOffset, watermarkStartHour.toDouble());
      final bottomOffset = _getOffsetForHour(dayOffset, (watermarkStartHour + watermarkHeightHours).toDouble());

      // For upcomingTasksAboveNow, the bottom offset is smaller than top offset
      final actualTop = widget.upcomingTasksAboveNow ? bottomOffset : topOffset;
      final height = (watermarkHeightHours * widget.hourHeight).abs();

      // Check if this watermark is highlighted
      final isHighlighted = _highlightedWatermarks.containsKey(dayOffset);

      watermarks.add(
        Positioned(
          top: actualTop,
          left: 70,
          right: 16,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _onWatermarkInteraction(dayOffset),
            child: MouseRegion(
              onEnter: (_) => _onWatermarkInteraction(dayOffset),
              child: DayWatermark(
                date: date,
                isToday: isToday,
                height: height,
                showWeekNumber: settings.watermarkShowWeekNumber,
                showDayOfYear: settings.watermarkShowDayOfYear,
                showHolidays: settings.watermarkShowHolidays,
                showMoonPhase: settings.watermarkShowMoonPhase,
                showQuarter: settings.watermarkShowQuarter,
                showDaysRemaining: settings.watermarkShowDaysRemaining,
                isHighlighted: isHighlighted,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: watermarks);
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

  // State for long-press task creation (using manual timer for web compatibility)
  bool _isCreatingTask = false;
  bool _isWaitingForLongPress = false;  // True while waiting for timer
  Timer? _longPressTimer;
  double? _createTaskStartY;      // Initial tap Y position (in timeline coordinates)
  double? _createTaskCurrentY;    // Current drag Y position
  double? _createTaskStartX;      // Track X for cancel gesture
  DateTime? _createTaskStartTime; // Snapped start time
  int _lastSnappedMinutes = -1;   // Track for haptic feedback on snap
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

  // ============ Long-press task creation methods ============
  // Using Listener + Timer for web compatibility (GestureDetector long-press
  // doesn't work well on web due to scroll view gesture conflicts)

  /// Snap a DateTime to 15-minute intervals
  DateTime _snapTo15Minutes(DateTime time) {
    final snappedMinutes = (time.minute / 15).round() * 15;
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
      final rawDateTime = _getDateTimeAtOffset(startY);
      final snappedStart = _snapTo15Minutes(rawDateTime);

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
      if (distance > 400) {  // 20^2 = 400
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
      final startTime = _createTaskStartTime!;
      final endTime = _getCreateTaskEndTime() ?? startTime.add(const Duration(hours: 1));

      // Ensure minimum duration of 15 minutes
      final duration = endTime.difference(startTime);
      final finalEndTime = duration.inMinutes < 15
          ? startTime.add(const Duration(minutes: 15))
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

  /// Get the end time based on drag position, snapped to 15 minutes
  DateTime? _getCreateTaskEndTime() {
    if (_createTaskStartTime == null || _createTaskStartY == null || _createTaskCurrentY == null) {
      return null;
    }

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

    // Default 1 hour + any drag extension
    final totalHours = 1.0 + hoursDelta;
    final durationMinutes = (totalHours * 60).round();

    // Ensure minimum 15 minutes
    final clampedMinutes = durationMinutes < 15 ? 15 : durationMinutes;

    final rawEndTime = _createTaskStartTime!.add(Duration(minutes: clampedMinutes));
    return _snapTo15Minutes(rawEndTime);
  }

  /// Calculate the visual bounds for the task creation preview
  ({double top, double height, Duration duration}) _getCreateTaskPreviewBounds() {
    if (_createTaskStartTime == null) {
      return (top: 0, height: 0, duration: Duration.zero);
    }

    final endTime = _getCreateTaskEndTime() ?? _createTaskStartTime!.add(const Duration(hours: 1));
    final duration = endTime.difference(_createTaskStartTime!);

    // Calculate positions
    final startOffset = _getOffsetForDateTime(_createTaskStartTime!);
    final endOffset = _getOffsetForDateTime(endTime);

    // Handle timeline direction
    final top = widget.upcomingTasksAboveNow
        ? endOffset  // When future is above, end is visually higher (smaller Y)
        : startOffset;
    final height = (startOffset - endOffset).abs();

    return (top: top, height: height, duration: duration);
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
                  final endTime = _getCreateTaskEndTime() ?? _createTaskStartTime!.add(const Duration(hours: 1));

                  return Positioned(
                    top: bounds.top,
                    left: 0,
                    right: 4,
                    height: bounds.height.clamp(40.0, double.infinity),
                    child: _TaskCreationPreview(
                      startTime: _createTaskStartTime!,
                      endTime: endTime,
                      duration: bounds.duration,
                      use24HourFormat: use24Hour,
                    ),
                  );
                },
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
/// Long-press and drag to change where on the viewport the NOW line appears.
class _NowLineScrollable extends ConsumerStatefulWidget {
  final DateTime currentTime;
  final double nowOffset;
  final bool use24HourFormat;
  final double scrollOffset;
  final double viewportHeight;
  final VoidCallback? onPositionChanged;

  const _NowLineScrollable({
    required this.currentTime,
    required this.nowOffset,
    required this.scrollOffset,
    required this.viewportHeight,
    this.use24HourFormat = false,
    this.onPositionChanged,
  });

  @override
  ConsumerState<_NowLineScrollable> createState() => _NowLineScrollableState();
}

class _NowLineScrollableState extends ConsumerState<_NowLineScrollable> {
  double? _dragDelta;

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

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _dragDelta = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      _dragDelta = details.offsetFromOrigin.dy;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_dragDelta != null) {
      // Calculate new viewport position
      // Current viewport position of NOW line
      final currentViewportY = widget.nowOffset - widget.scrollOffset;
      // New viewport position after drag
      final newViewportY = currentViewportY + _dragDelta!;
      // Convert to percentage (0.0 to 1.0)
      final newPosition = newViewportY / widget.viewportHeight;

      // Save the new viewport position
      ref.read(settingsProvider.notifier).setNowLineViewportPosition(newPosition);

      // Trigger scroll to new position after a brief delay to let state update
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.onPositionChanged?.call();
      });

      HapticFeedback.lightImpact();
    }
    setState(() {
      _dragDelta = null;
    });
  }

  void _onLongPressCancel() {
    setState(() {
      _dragDelta = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.nowLineDark : AppColors.nowLineLight;

    // NOW line is always at current time's offset
    // During drag, add the drag delta so the line visually follows the finger
    final isDragging = _dragDelta != null;
    final effectiveOffset = widget.nowOffset + (_dragDelta ?? 0);

    return Stack(
      children: [
        // Glow effect behind the line
        Positioned(
          left: 0,
          right: 0,
          top: effectiveOffset - 20,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0),
                  lineColor.withValues(alpha: isDragging ? 0.6 : 0.4),
                  lineColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Main NOW line with drag gesture
        Positioned(
          left: 0,
          right: 0,
          top: effectiveOffset - 20,
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            onLongPressCancel: _onLongPressCancel,
            child: Center(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: lineColor,
                  boxShadow: [
                    BoxShadow(
                      color: lineColor.withValues(alpha: 0.5),
                      blurRadius: isDragging ? 8 : 4,
                      spreadRadius: isDragging ? 2 : 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Time badge - always shows current time
        Positioned(
          right: 16,
          top: effectiveOffset - 14,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            onLongPressCancel: _onLongPressCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: lineColor.withValues(alpha: 0.3),
                    blurRadius: isDragging ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _formatTime(widget.currentTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // NOW label
        Positioned(
          left: 12,
          top: effectiveOffset - 12,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            onLongPressCancel: _onLongPressCancel,
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
        ),
      ],
    );
  }
}

/// Fixed NOW line that stays in place on screen at a specified position.
/// The calendar content scrolls to meet this fixed line.
class _FixedNowLine extends StatelessWidget {
  final DateTime currentTime;
  final bool use24HourFormat;
  final double nowLinePosition;

  const _FixedNowLine({
    required this.currentTime,
    required this.nowLinePosition,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final nowY = screenHeight * nowLinePosition;

    return IgnorePointer(
      child: Stack(
        children: [
          // Glow effect behind the line
          Positioned(
            left: 0,
            right: 0,
            top: nowY - 20,
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
            top: nowY - 1,
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
            top: nowY - 14,
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
            top: nowY - 12,
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
      ),
    );
  }
}

/// Preview widget shown during long-press task creation.
/// Displays a semi-transparent box with the task duration.
class _TaskCreationPreview extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool use24HourFormat;

  const _TaskCreationPreview({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.use24HourFormat,
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "New Task" label
              Text(
                'New Task',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Time range
              Text(
                '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Duration badge at bottom
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
