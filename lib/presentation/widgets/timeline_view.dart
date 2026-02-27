import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/theme/app_colors.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';
import 'package:cron_timeflow/core/plugins/widgets/event_detail_popup.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/presentation/providers/settings_provider.dart';
import 'package:cron_timeflow/presentation/widgets/time_of_day_background.dart';
import 'package:cron_timeflow/presentation/utils/timeline_offset.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_day_dividers.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_day_watermarks.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_hour_markers.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_now_line_scrollable.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_plugin_events_layer.dart';
import 'package:cron_timeflow/presentation/widgets/timeline_task_cards_layer.dart';
import 'package:cron_timeflow/services/reminder_sound_service.dart';

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

  /// Called when the zoom level (hour height) changes.
  final ValueChanged<double>? onZoomChanged;

  /// Initial hour height (zoom level) to use when the widget is first created.
  final double initialHourHeight;

  const TimelineView({
    super.key,
    this.upcomingTasksAboveNow = true,
    this.initialDate,
    this.onVisibleDateChanged,
    this.onNowLineVisibilityChanged,
    this.onZoomChanged,
    this.initialHourHeight = TimelineViewState.defaultHourHeight,
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

  // Now-line crossing alert tracking
  final Set<String> _alertedEventIds = {};
  DateTime _previousTickTime = DateTime.now();

  /// Default height in pixels per hour of timeline (1x zoom).
  static const double defaultHourHeight = 80.0;

  /// Height in pixels per hour of timeline. Mutable for zoom.
  late double _hourHeight;

  /// Public getter for current hour height.
  double get hourHeight => _hourHeight;

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
    _hourHeight = widget.initialHourHeight;
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
      _checkEventCrossings();
    });
  }

  void _updateLoadedRange() {
    _loadedRange = DateRange(
      _referenceDate.subtract(Duration(days: _daysLoadedBefore)),
      _referenceDate.add(Duration(days: _daysLoadedAfter)),
    );
    // Clear crossing alert history when range changes
    _alertedEventIds.clear();
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

  /// Checks if any plugin events have crossed the now line since the last tick.
  void _checkEventCrossings() {
    final settings = ref.read(settingsProvider);
    if (!settings.eventCrossingAlertEnabled) return;

    final now = _currentTime;
    final previous = _previousTickTime;
    _previousTickTime = now;

    // Skip if time went backwards (e.g. manual clock change)
    if (!now.isAfter(previous)) return;

    final plugins = ref.read(enabledPluginsProvider);
    final crossingAlertState = ref.read(pluginCrossingAlertStateProvider);
    final registry = ref.read(pluginRegistryProvider);

    for (final plugin in plugins) {
      if (!(crossingAlertState[plugin.id] ?? true)) continue;

      final provider = plugin.eventsProviderFor(_loadedRange);
      if (provider == null) continue;

      final eventsAsync = ref.read(provider);
      eventsAsync.whenData((events) {
        for (final event in events) {
          if (_alertedEventIds.contains(event.id)) continue;

          // Event crosses NOW if startTime is in (previous, now]
          if (event.startTime.isAfter(previous) &&
              !event.startTime.isAfter(now)) {
            _alertedEventIds.add(event.id);
            _fireEventCrossingAlert(
                event, registry.getById(event.pluginId) ?? plugin);
          }
        }
      });
    }
  }

  /// Fires a now-line crossing alert: plays sound, haptic feedback, shows popup.
  void _fireEventCrossingAlert(TimelineEvent event, TimeFlowPlugin plugin) {
    final settings = ref.read(settingsProvider);

    // Play sound
    if (settings.reminderSoundEnabled) {
      ReminderSoundService.play(settings.eventCrossingAlertSound);
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Show detail popup
    if (mounted) {
      showEventDetailPopup(context, event);
    }
  }

  /// Total number of days in the loaded range.
  int get _totalDays => _daysLoadedBefore + _daysLoadedAfter + 1;

  /// Total timeline height in pixels.
  double get _totalHeight => _totalDays * 24 * _hourHeight;

  /// Calculate pixel offset for a given DateTime.
  double _getOffsetForDateTime(DateTime dateTime) {
    return TimelineOffset.forDateTime(
      dateTime: dateTime,
      referenceDate: _referenceDate,
      hourHeight: _hourHeight,
      daysLoadedBefore: _daysLoadedBefore,
      daysLoadedAfter: _daysLoadedAfter,
      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
    );
  }

  /// Calculate DateTime for a given pixel offset.
  DateTime _getDateTimeAtOffset(double offset) {
    return TimelineOffset.atOffset(
      offset: offset,
      referenceDate: _referenceDate,
      hourHeight: _hourHeight,
      daysLoadedBefore: _daysLoadedBefore,
      daysLoadedAfter: _daysLoadedAfter,
      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
    );
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

  /// Internal setter that clamps, updates state, and fires the callback.
  /// Adjusts scroll position so the NOW line stays fixed on screen.
  void _setHourHeight(double height) {
    final newHeight = height.clamp(40.0, 320.0);
    if (newHeight != _hourHeight) {
      // Capture the NOW line's screen position before changing height.
      final nowScreenY = _scrollController.hasClients
          ? _getOffsetForDateTime(DateTime.now()) - _scrollController.offset
          : 0.0;
      setState(() {
        _hourHeight = newHeight;
      });
      if (_scrollController.hasClients) {
        // The NOW offset scales by ratio; keep it at the same screen Y.
        final newNowOffset = _getOffsetForDateTime(DateTime.now());
        _scrollController.jumpTo(newNowOffset - nowScreenY);
      }
      widget.onZoomChanged?.call(_hourHeight);
    }
  }

  /// Set zoom level as a scale of default. [scale] is clamped to keep hourHeight between 40–320px.
  void setZoomLevel(double scale) {
    _setHourHeight(defaultHourHeight * scale);
  }

  /// Set hour height to an absolute pixel value (clamped 40–320).
  void setHourHeightAbsolute(double height) {
    _setHourHeight(height);
  }

  /// Reset zoom to the default (1x).
  void resetZoom() {
    _setHourHeight(defaultHourHeight);
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
    final centerDay =
        DateTime(centerDate.year, centerDate.month, centerDate.day);

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
    final isNowVisible =
        nowLineScreenPosition >= 0 && nowLineScreenPosition <= viewportHeight;

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
                  child: HourMarkersMultiDay(
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
                    color: isDark
                        ? AppColors.timelineDark
                        : AppColors.timelineLight,
                  ),
                ),

                // Day dividers (full width) - now with sunrise/sunset icons
                DayDividers(
                  hourHeight: _hourHeight,
                  upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                  referenceDate: _referenceDate,
                  daysLoadedBefore: _daysLoadedBefore,
                  daysLoadedAfter: _daysLoadedAfter,
                ),

                // Day watermarks (large background date numbers)
                DayWatermarksWithTasks(
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
                  child: TaskCardsLayerMultiDay(
                    hourHeight: _hourHeight,
                    upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                    referenceDate: _referenceDate,
                    daysLoadedBefore: _daysLoadedBefore,
                    daysLoadedAfter: _daysLoadedAfter,
                    loadedRange: _loadedRange,
                  ),
                ),

                // Plugin events layer (ServerFlow dots/bars)
                Positioned(
                  left: 70,
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: PluginEventsLayer(
                    hourHeight: _hourHeight,
                    upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                    referenceDate: _referenceDate,
                    daysLoadedBefore: _daysLoadedBefore,
                    daysLoadedAfter: _daysLoadedAfter,
                    loadedRange: _loadedRange,
                  ),
                ),

                // Day divider overlay (shows through tasks spanning midnight)
                IgnorePointer(
                  child: DayDividerOverlay(
                    hourHeight: _hourHeight,
                    upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
                    referenceDate: _referenceDate,
                    daysLoadedBefore: _daysLoadedBefore,
                    daysLoadedAfter: _daysLoadedAfter,
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

                    return NowLineScrollable(
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
