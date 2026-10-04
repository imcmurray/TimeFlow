import 'dart:math' show exp;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';
import 'package:timeflow/presentation/widgets/calendar_overview.dart';
import 'package:timeflow/presentation/widgets/timeline_long_press_hint_tooltip.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/screens/settings_screen.dart';
import 'package:timeflow/presentation/screens/share_screen.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// View mode for the timeline screen.
enum TimelineViewMode { day, calendar }

/// Main screen displaying the flowing daily timeline.
///
/// This is the heart of TimeFlow - a continuous vertical scrolling timeline
/// where tasks flow past the fixed NOW line as real time passes. Days stitch
/// together seamlessly, embodying the metaphor of time as a flowing river.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  DateTime _visibleDate = DateTime.now();
  bool _isNowLineVisible = true;
  final GlobalKey<TimelineViewState> _timelineKey = GlobalKey();

  TimelineViewMode _viewMode = TimelineViewMode.day;
  DateTime? _selectedDateFromCalendar;
  double _pinchScale = 1.0;
  bool _isPinching = false;
  late double _currentHourHeight = (TimelineViewState.defaultHourHeight *
          ref.read(settingsProvider).timelineZoom)
      .clamp(TimelineViewState.minHourHeight, TimelineViewState.maxHourHeight);
  late double _baseHourHeight = _currentHourHeight;
  final FocusNode _focusNode = FocusNode();
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    if (isCtrl != _isCtrlPressed) {
      setState(() => _isCtrlPressed = isCtrl);
    }
    return false; // don't consume - let other keyboard handlers fire
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == TimelineViewMode.day) {
        _viewMode = TimelineViewMode.calendar;
      } else {
        _viewMode = TimelineViewMode.day;
        _selectedDateFromCalendar = null;
        _jumpToNow();
      }
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _viewMode = TimelineViewMode.day;
      _selectedDateFromCalendar = date;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _isPinching = true;
      _pinchScale = 1.0;
      _baseHourHeight = _currentHourHeight;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isPinching) return;

    _pinchScale = details.scale;

    if (_viewMode == TimelineViewMode.day) {
      // In day view: pinch zooms the timeline (accumulative)
      _timelineKey.currentState
          ?.setHourHeightAbsolute(_baseHourHeight * _pinchScale);

      // Very aggressive pinch-in escapes to calendar
      if (_pinchScale < 0.5) {
        setState(() {
          _viewMode = TimelineViewMode.calendar;
          _isPinching = false;
        });
      }
    } else if (_viewMode == TimelineViewMode.calendar && _pinchScale > 1.3) {
      setState(() {
        _viewMode = TimelineViewMode.day;
        _isPinching = false;
      });
      _jumpToNow();
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isPinching = false;
    _pinchScale = 1.0;
  }

  void _onVisibleDateChanged(DateTime date) {
    setState(() {
      _visibleDate = date;
    });
  }

  void _onNowLineVisibilityChanged(bool isVisible) {
    setState(() {
      _isNowLineVisible = isVisible;
    });
  }

  void _jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }

  void _onZoomChanged(double hourHeight) {
    setState(() => _currentHourHeight = hourHeight);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      GestureBinding.instance.pointerSignalResolver.register(event, (_) {
        final newHeight =
            _currentHourHeight * exp(-event.scrollDelta.dy * 0.001);
        _timelineKey.currentState?.setHourHeightAbsolute(newHeight);
      });
    }
  }

  String _formatDate(DateTime date) => TimeFormatter.formatDate(date);

  bool get _isViewingToday {
    final now = DateTime.now();
    return _visibleDate.year == now.year &&
        _visibleDate.month == now.month &&
        _visibleDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _toggleViewMode();
          } else if (event.logicalKey == LogicalKeyboardKey.keyG &&
              HardwareKeyboard.instance.isControlPressed) {
            if (_viewMode == TimelineViewMode.day) {
              setState(() {
                _viewMode = TimelineViewMode.calendar;
              });
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _currentHourHeight != TimelineViewState.defaultHourHeight
              ? IconButton(
                  icon: Badge(
                    label: Text(
                      '${(_currentHourHeight / TimelineViewState.defaultHourHeight * 100).round()}%',
                      style: const TextStyle(fontSize: 9),
                    ),
                    child: const Icon(Icons.zoom_out_map),
                  ),
                  onPressed: () {
                    _timelineKey.currentState?.resetZoom();
                  },
                  tooltip: 'Reset zoom',
                )
              : null,
          title: GestureDetector(
            onTap: _toggleViewMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _viewMode == TimelineViewMode.calendar
                    ? colorScheme.tertiaryContainer
                    : _isViewingToday
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _viewMode == TimelineViewMode.calendar
                        ? 'Calendar'
                        : _formatDate(_visibleDate),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _viewMode == TimelineViewMode.calendar
                          ? colorScheme.tertiary
                          : _isViewingToday
                              ? colorScheme.primary
                              : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _viewMode == TimelineViewMode.calendar
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: _viewMode == TimelineViewMode.calendar
                        ? colorScheme.tertiary
                        : _isViewingToday
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShareScreen(date: _visibleDate),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _viewMode == TimelineViewMode.day
                  ? Listener(
                      onPointerSignal: _onPointerSignal,
                      child: AbsorbPointer(
                        absorbing: _isCtrlPressed,
                        child: GestureDetector(
                          key: const ValueKey('timeline'),
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onScaleEnd: _onScaleEnd,
                          child: TimelineView(
                            key: _timelineKey,
                            initialDate: _selectedDateFromCalendar,
                            onVisibleDateChanged: _onVisibleDateChanged,
                            onNowLineVisibilityChanged:
                                _onNowLineVisibilityChanged,
                            onZoomChanged: _onZoomChanged,
                          ),
                        ),
                      ),
                    )
                  : CalendarOverview(
                      key: const ValueKey('calendar'),
                      initialMonth: _visibleDate,
                      onDateSelected: _onDateSelected,
                    ),
            ),

            if (_viewMode == TimelineViewMode.day &&
                !ref.watch(
                    settingsProvider.select((s) => s.hasSeenLongPressHint)))
              LongPressHintTooltip(
                onDismiss: () => ref
                    .read(settingsProvider.notifier)
                    .setHasSeenLongPressHint(true),
              ),

            // Jump to NOW button (bottom left, only in day view when NOW line not visible)
            if (_viewMode == TimelineViewMode.day && !_isNowLineVisible)
              Positioned(
                left: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'jumpToNow',
                  onPressed: _jumpToNow,
                  tooltip: 'Jump to now',
                  child: const Icon(Icons.my_location),
                ),
              ),
          ],
        ),
        floatingActionButton: _viewMode == TimelineViewMode.day
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        initialDate: _visibleDate,
                      ),
                    ),
                  );
                },
                tooltip: 'Add task',
                child: const Icon(Icons.add),
              )
            : FloatingActionButton(
                onPressed: () {
                  _onDateSelected(DateTime.now());
                },
                tooltip: 'Go to today',
                child: const Icon(Icons.today),
              ),
      ),
    );
  }
}
