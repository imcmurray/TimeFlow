import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeflow/core/plugins/crossing_alerts.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:timeflow/presentation/timeline/timeline_tasks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/clock_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/timeline/day_layers.dart';
import 'package:timeflow/presentation/timeline/hour_markers_layer.dart';
import 'package:timeflow/presentation/timeline/now_line.dart';
import 'package:timeflow/presentation/timeline/plugin_events_layer.dart';
import 'package:timeflow/presentation/timeline/task_layer.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';
import 'package:timeflow/presentation/widgets/time_of_day_background.dart';

/// Horizontal layout of the timeline content.
abstract final class TimelineLayout {
  /// Width of the hour-label gutter.
  static const gutter = 60.0;

  /// X position of the vertical timeline line.
  static const lineX = 56.0;

  /// Left edge of task cards.
  static const contentLeft = 70.0;

  /// Right margin of task cards.
  static const contentRight = 16.0;

  /// Width of the plugin-indicator lane left of the cards, when plugins are on.
  static const pluginLane = 22.0;
}

/// Where NOW is when it's off screen.
@immutable
class OffscreenNow {
  /// NOW is above the visible area (otherwise below).
  final bool above;

  /// How far the middle of the screen is from NOW, e.g. "3 h ahead".
  final String distance;

  const OffscreenNow({required this.above, required this.distance});

  @override
  bool operator ==(Object other) =>
      other is OffscreenNow &&
      other.above == above &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(above, distance);
}

/// "45 min ahead", "3 h back", "2 days ahead": how far [viewed] is from
/// [now], in the largest sensible unit.
String describeDistanceFromNow(DateTime now, DateTime viewed) {
  final minutes = viewed.difference(now).inMinutes;
  final direction = minutes >= 0 ? 'ahead' : 'back';
  final m = minutes.abs();
  if (m < 60) return '${m < 1 ? 1 : m} min $direction';
  if (m < 24 * 60) return '${(m / 60).round()} h $direction';
  final days = LocalDate.of(now).daysUntil(LocalDate.of(viewed)).abs();
  final d = days < 1 ? 1 : days;
  return d == 1 ? '1 day $direction' : '$d days $direction';
}

/// The scrolling river of time: a vertical timeline that keeps the NOW line
/// at a fixed place on screen while tasks flow past it.
///
/// The timeline spans two years around the day it opens on (and re-centres
/// if the user jumps beyond that), so it never has to grow and shift the
/// scroll position. Only the days around the viewport are built.
class TimelineView extends ConsumerStatefulWidget {
  /// Date to show first; null opens at NOW.
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onVisibleDateChanged;

  /// Called with where NOW is while it's off screen, and null once it's
  /// visible again.
  final ValueChanged<OffscreenNow?>? onOffscreenNowChanged;
  final ValueChanged<double>? onZoomChanged;

  const TimelineView({
    super.key,
    this.initialDate,
    this.onVisibleDateChanged,
    this.onOffscreenNowChanged,
    this.onZoomChanged,
  });

  @override
  ConsumerState<TimelineView> createState() => TimelineViewState();
}

class TimelineViewState extends ConsumerState<TimelineView>
    with WidgetsBindingObserver {
  static const defaultHourHeight = 80.0;
  static const minHourHeight = 40.0;
  static const maxHourHeight = 320.0;

  /// Days on the timeline. Two years, centred on the opening day.
  static const _dayCount = 731;

  /// How often the NOW line moves and the view follows it.
  static const _tick = Duration(seconds: 5);

  final _scroll = ScrollController();
  late TimelineGeometry _geometry;
  late final ValueNotifier<DayRange> _visibleDays;
  late final ValueNotifier<DateTime> _now;
  Timer? _ticker;
  Timer? _saveZoom;

  /// Whether the view keeps NOW in place as time passes. Turns off when the
  /// user scrolls away and back on when they return or tap "jump to now".
  bool _following = true;
  bool _userScrolling = false;
  bool _nowVisible = true;
  OffscreenNow? _reportedOffscreen;

  /// True while the view moves itself (following NOW, zooming, jumping), so
  /// the scrollbar only appears for the user's own scrolling.
  bool _scrollingProgrammatically = false;

  /// True during the app's own animated scrolls (jump to NOW, go to date).
  bool _animating = false;
  LocalDate? _reportedDay;

  double get hourHeight => _geometry.hourHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = ref.read(settingsProvider);
    final center = LocalDate.of(widget.initialDate ?? DateTime.now());
    _geometry = TimelineGeometry(
      firstDay: center.addDays(-(_dayCount ~/ 2)),
      dayCount: _dayCount,
      hourHeight: (defaultHourHeight * settings.timelineZoom).clamp(
        minHourHeight,
        maxHourHeight,
      ),
      futureAtTop: settings.upcomingTasksAboveNow,
    );
    _visibleDays = ValueNotifier(
      DayRange(center.addDays(-1), center.addDays(1)),
    );
    _now = ValueNotifier(DateTime.now());
    _following = widget.initialDate == null;
    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDate != null) {
        scrollToDate(widget.initialDate!, animated: false);
      } else {
        _scrollToNow(animated: false);
      }
      _onScroll();
    });
    _ticker = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _saveZoom?.cancel();
    _scroll.dispose();
    _visibleDays.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onTick();
  }

  /// Runs [move] without showing the scrollbar.
  void _quietly(VoidCallback move) {
    _scrollingProgrammatically = true;
    try {
      move();
    } finally {
      _scrollingProgrammatically = false;
    }
  }

  DateTime _lastCrossingCheck = DateTime.now();
  final Set<String> _alertedEvents = {};

  /// Alerts for plugin events (e.g. cron jobs) that reached NOW since the
  /// last check, for plugins with crossing alerts on.
  Future<void> _checkPluginCrossings(DateTime now) async {
    final previous = _lastCrossingCheck;
    _lastCrossingCheck = now;
    final alertsOn = ref.read(pluginCrossingAlertStateProvider);
    final window = taskWindowFor(DayRange.single(LocalDate.of(now)));
    for (final plugin in ref.read(enabledPluginsProvider)) {
      if (!(alertsOn[plugin.id] ?? true)) continue;
      final provider = plugin.eventsProviderFor(window);
      if (provider == null) continue;
      final List<TimelineEvent> events;
      try {
        events = await ref.read(provider.future);
      } catch (_) {
        continue;
      }
      final crossed = detectCrossingEvents(
        previous: previous,
        now: now,
        events: events,
        alreadyAlerted: _alertedEvents,
      );
      if (crossed.isEmpty || !mounted) continue;
      _alertedEvents.addAll(crossed.map((e) => e.id));
      final settings = ref.read(settingsProvider);
      if (settings.reminderSoundEnabled) {
        ReminderSoundService.play(settings.reminderSound);
      }
      HapticFeedback.mediumImpact();
      plugin.onEventTap?.call(context, crossed.first);
    }
  }

  void _onTick() {
    if (!mounted) return;
    _now.value = DateTime.now();
    _checkPluginCrossings(_now.value);
    if (_following && !_userScrolling && _scroll.hasClients) {
      _quietly(() => _scroll.jumpTo(_nowScrollOffset()));
    } else {
      _onScroll(); // NOW moved; refresh the off-screen distance.
    }
  }

  // ------------------------------------------------------------- positions

  double get _viewport => _scroll.hasClients
      ? _scroll.position.viewportDimension
      : MediaQuery.sizeOf(context).height;

  /// Scroll offset that puts the NOW line at its chosen place on screen.
  double _nowScrollOffset() {
    final fraction = ref.read(settingsProvider).nowLineViewportPosition;
    final target = _geometry.yOf(DateTime.now()) - _viewport * fraction;
    if (!_scroll.hasClients) return target;
    return target.clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
  }

  void _scrollToNow({required bool animated}) {
    if (!_scroll.hasClients) return;
    final today = LocalDate.today();
    if (_needsRecentre(today)) {
      _recentre(today, then: () => _scrollToNow(animated: false));
      return;
    }
    final target = _nowScrollOffset();
    if (animated) {
      _animateTo(target);
    } else {
      _quietly(() => _scroll.jumpTo(target));
    }
  }

  /// An animated scroll the app makes itself, which must not count as the
  /// user scrolling away from NOW.
  void _animateTo(double target) {
    _animating = true;
    _scroll
        .animateTo(
          target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _animating = false);
  }

  /// Scrolls back to NOW and resumes following it.
  void jumpToNow() {
    _following = true;
    _scrollToNow(animated: true);
  }

  /// Shows [date], with 8:00 a quarter of the way down the screen.
  void scrollToDate(DateTime date, {bool animated = true}) {
    final day = LocalDate.of(date);
    if (_needsRecentre(day)) {
      _recentre(day, then: () => scrollToDate(date, animated: false));
      return;
    }
    if (!_scroll.hasClients) return;
    _following = false;
    final y = _geometry.yOfDayHour(day, 8);
    final target =
        (_geometry.futureAtTop ? y - _viewport * 0.75 : y - _viewport * 0.25)
            .clamp(
              _scroll.position.minScrollExtent,
              _scroll.position.maxScrollExtent,
            );
    if (animated) {
      _animateTo(target);
    } else {
      _quietly(() => _scroll.jumpTo(target));
    }
  }

  bool _needsRecentre(LocalDate day) =>
      _geometry.firstDay.daysUntil(day) < 30 ||
      day.daysUntil(_geometry.lastDay) < 30;

  void _recentre(LocalDate day, {required VoidCallback then}) {
    setState(() => _geometry = _geometry.centeredOn(day));
    WidgetsBinding.instance.addPostFrameCallback((_) => then());
  }

  // ------------------------------------------------------------------ zoom

  /// Sets the zoom (pixels per hour), keeping the NOW line, or the middle of
  /// the screen when NOW is off screen, at the same place.
  void setHourHeightAbsolute(double height) {
    final newHeight = height.clamp(minHourHeight, maxHourHeight);
    if (newHeight == _geometry.hourHeight) return;
    final anchorTime = _nowVisible
        ? DateTime.now()
        : _geometry.timeAt(_scroll.offset + _viewport / 2);
    final anchorScreenY = _geometry.yOf(anchorTime) - _scroll.offset;
    setState(() => _geometry = _geometry.copyWith(hourHeight: newHeight));
    if (_scroll.hasClients) {
      _quietly(() => _scroll.jumpTo(_geometry.yOf(anchorTime) - anchorScreenY));
    }
    widget.onZoomChanged?.call(newHeight);
    _saveZoom?.cancel();
    _saveZoom = Timer(const Duration(milliseconds: 600), () {
      ref
          .read(settingsProvider.notifier)
          .setTimelineZoom(newHeight / defaultHourHeight);
    });
  }

  void setZoomLevel(double scale) =>
      setHourHeightAbsolute(defaultHourHeight * scale);

  void resetZoom() => setHourHeightAbsolute(defaultHourHeight);

  // ---------------------------------------------------------------- scroll

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final top = _scroll.offset;
    final viewport = _viewport;

    // Build one extra screen above and below, rounded out to whole days.
    final days = _geometry.daysIn(top - viewport, top + viewport * 2);
    if (days != _visibleDays.value) _visibleDays.value = days;

    final centerDay = LocalDate.of(_geometry.timeAt(top + viewport / 2));
    if (centerDay != _reportedDay) {
      _reportedDay = centerDay;
      widget.onVisibleDateChanged?.call(centerDay.startOfDay);
    }

    final now = DateTime.now();
    final nowY = _geometry.yOf(now) - top;
    _nowVisible = nowY >= 0 && nowY <= viewport;
    final offscreen = _nowVisible
        ? null
        : OffscreenNow(
            above: nowY < 0,
            distance: describeDistanceFromNow(
              now,
              _geometry.timeAt(top + viewport / 2),
            ),
          );
    if (offscreen != _reportedOffscreen) {
      _reportedOffscreen = offscreen;
      widget.onOffscreenNowChanged?.call(offscreen);
    }
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.depth != 0) return false;
    // Any movement the app didn't make is the user's: touch drags, but also
    // mouse wheels, trackpads, the scrollbar and the keyboard, none of which
    // carry drag details. Scrolling away stops following NOW.
    if (n is ScrollUpdateNotification &&
        !_scrollingProgrammatically &&
        !_animating) {
      _userScrolling = true;
      _following = false;
    } else if (n is ScrollEndNotification && _userScrolling) {
      _userScrolling = false;
      // Letting go close to NOW picks the current back up.
      if ((_scroll.offset - _nowScrollOffset()).abs() < hourHeight / 4) {
        _following = true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final futureAtTop = ref.watch(
      settingsProvider.select((s) => s.upcomingTasksAboveNow),
    );
    if (futureAtTop != _geometry.futureAtTop) {
      _geometry = _geometry.copyWith(futureAtTop: futureAtTop);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _following = true;
        _scrollToNow(animated: false);
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour =
        ref.watch(minuteClockProvider).value?.hour ?? DateTime.now().hour;
    final geometry = _geometry;
    // With plugins on, their indicators get their own lane beside the cards
    // instead of sitting on the cards' edges.
    final pluginLane = ref.watch(enabledPluginsProvider).isEmpty
        ? 0.0
        : TimelineLayout.pluginLane;

    return TimeOfDayBackground(
      hour: hour,
      isDark: isDark,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            controller: _scroll,
            // Only the user's own scrolling shows the scrollbar, not the view
            // following NOW every few seconds.
            notificationPredicate: (n) =>
                n.depth == 0 && !_scrollingProgrammatically,
            child: SingleChildScrollView(
              controller: _scroll,
              child: SizedBox(
                height: geometry.totalHeight,
                child: ValueListenableBuilder<DayRange>(
                  valueListenable: _visibleDays,
                  builder: (context, days, _) => Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: TimelineLayout.gutter,
                        child: HourMarkersLayer(geometry: geometry, days: days),
                      ),
                      Positioned(
                        left: TimelineLayout.lineX,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: ColoredBox(
                          color: isDark
                              ? AppColors.timelineDark
                              : AppColors.timelineLight,
                        ),
                      ),
                      DayDividersLayer(geometry: geometry, days: days),
                      DayWatermarksLayer(geometry: geometry, days: days),
                      Positioned(
                        left: TimelineLayout.contentLeft + pluginLane,
                        right: TimelineLayout.contentRight,
                        top: 0,
                        bottom: 0,
                        child: TaskLayer(geometry: geometry, days: days),
                      ),
                      Positioned(
                        left: TimelineLayout.contentLeft,
                        width: pluginLane,
                        top: 0,
                        bottom: 0,
                        child: PluginEventsLayer(
                          geometry: geometry,
                          days: days,
                        ),
                      ),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _now,
                        builder: (context, now, _) => NowLine(
                          currentTime: now,
                          y: geometry.yOf(now),
                          scrollController: _scroll,
                          onPositionChanged: jumpToNow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
