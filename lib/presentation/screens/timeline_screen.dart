import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/widgets/timeline_view.dart';
import 'package:timeflow/presentation/widgets/calendar_overview.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/screens/settings_screen.dart';
import 'package:timeflow/presentation/screens/share_screen.dart';

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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isPinching) return;

    _pinchScale = details.scale;

    if (_viewMode == TimelineViewMode.day && _pinchScale < 0.7) {
      setState(() {
        _viewMode = TimelineViewMode.calendar;
        _isPinching = false;
      });
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShareScreen(date: _visibleDate),
                  ),
                );
              },
              tooltip: 'Share schedule',
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
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _viewMode == TimelineViewMode.day
                  ? GestureDetector(
                      key: const ValueKey('timeline'),
                      behavior: HitTestBehavior.translucent,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      child: TimelineView(
                        key: _timelineKey,
                        upcomingTasksAboveNow:
                            ref.watch(settingsProvider).upcomingTasksAboveNow,
                        initialDate: _selectedDateFromCalendar,
                        onVisibleDateChanged: _onVisibleDateChanged,
                        onNowLineVisibilityChanged: _onNowLineVisibilityChanged,
                      ),
                    )
                  : CalendarOverview(
                      key: const ValueKey('calendar'),
                      initialMonth: _visibleDate,
                      onDateSelected: _onDateSelected,
                    ),
            ),

              // Jump to NOW button (bottom left, only in day view when NOW line not visible)
              if (_viewMode == TimelineViewMode.day && !_isNowLineVisible)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'jumpToNow',
                    onPressed: _jumpToNow,
                    tooltip: 'Jump to now',
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
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
