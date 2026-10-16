import 'dart:math' show exp;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/domain/beta_access.dart';
import 'package:timeflow/presentation/providers/beta_access_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/timeline/now_chip.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';
import 'package:timeflow/presentation/widgets/calendar_overview.dart';
import 'package:timeflow/presentation/widgets/timeline_long_press_hint_tooltip.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/screens/settings_screen.dart';
import 'package:timeflow/presentation/screens/share_screen.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/services/beta_feedback.dart';

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

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with WidgetsBindingObserver {
  DateTime _visibleDate = DateTime.now();
  OffscreenNow? _offscreenNow;
  final GlobalKey<TimelineViewState> _timelineKey = GlobalKey();

  TimelineViewMode _viewMode = TimelineViewMode.day;
  DateTime? _selectedDateFromCalendar;
  double _pinchScale = 1.0;
  bool _isPinching = false;
  late double _currentHourHeight =
      (TimelineViewState.defaultHourHeight *
              ref.read(settingsProvider).timelineZoom)
          .clamp(
            TimelineViewState.minHourHeight,
            TimelineViewState.maxHourHeight,
          );
  late double _baseHourHeight = _currentHourHeight;
  final FocusNode _focusNode = FocusNode();
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    if (betaModeOffered) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (betaModeOffered) WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  /// Ask the portal how many steps are left when the app comes back — and only then. The
  /// number changes when the tester does something in the portal, so a timer would spend
  /// requests to learn nothing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(betaAccessProvider.notifier).refresh();
    }
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
      _timelineKey.currentState?.setHourHeightAbsolute(
        _baseHourHeight * _pinchScale,
      );

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

  void _onOffscreenNowChanged(OffscreenNow? now) {
    setState(() => _offscreenNow = now);
  }

  void _jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }

  Future<void> _openBetaFeedback() => _openPortal(
    openBetaFeedback,
    intent: 'report',
    ifNoBrowser:
        "Couldn't open a browser. Report it at testers.rinserepeatlabs.com",
  );

  Future<void> _openBetaTasks() => _openPortal(
    openBetaTasks,
    intent: 'tasks',
    ifNoBrowser:
        "Couldn't open a browser. Your tasks are at testers.rinserepeatlabs.com",
  );

  Future<void> _openPortal(
    Future<bool> Function({required bool isTablet, String handoff}) open, {
    required String intent,
    required String ifNoBrowser,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    // Minted here, on the tap, so a connected tester lands signed in. An unconnected one
    // gets an empty string and the portal asks for their email as it always has.
    final connected =
        (ref.read(betaAccessProvider).value ?? BetaAccess.disconnected)
            .connected;
    final handoff = connected
        ? await ref.read(betaAccessServiceProvider).handoff(intent: intent)
        : '';
    if (!await open(isTablet: isTablet, handoff: handoff)) {
      messenger.showSnackBar(SnackBar(content: Text(ifNoBrowser)));
    }
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
    final betaAccess = betaModeOffered
        ? (ref.watch(betaAccessProvider).value ?? BetaAccess.disconnected)
        : BetaAccess.disconnected;

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
            // Actions contributed by enabled plugins (e.g. ServerFlow's filter).
            for (final plugin in ref.watch(enabledPluginsProvider))
              for (final ext in plugin.uiExtensions)
                if (ext.extensionPoint == UIExtensionPoint.appBarAction)
                  ext.builder(context, ref),
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
            // A beta build always offers these. Any other build that offers beta mode at
            // all — the web app — shows them once a code has been pasted in Settings, so
            // the toggle is the gate rather than how the build was compiled.
            if (betaFeedback || betaAccess.connected) ...[
              IconButton(
                icon: Badge(
                  isLabelVisible: betaAccess.showBadge,
                  label: Text('${betaAccess.tasksLeft}'),
                  child: const Icon(Icons.fact_check_outlined),
                ),
                tooltip: betaAccess.showBadge
                    ? 'Beta tasks (${betaAccess.tasksLeft} left)'
                    : 'Beta tasks',
                onPressed: _openBetaTasks,
              ),
              IconButton(
                icon: const Icon(Icons.feedback_outlined),
                tooltip: 'Beta feedback',
                onPressed: _openBetaFeedback,
              ),
            ],
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
                    scale: Tween<double>(
                      begin: 0.95,
                      end: 1.0,
                    ).animate(animation),
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
                            onOffscreenNowChanged: _onOffscreenNowChanged,
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
                  settingsProvider.select((s) => s.hasSeenLongPressHint),
                ))
              LongPressHintTooltip(
                onDismiss: () => ref
                    .read(settingsProvider.notifier)
                    .setHasSeenLongPressHint(true),
              ),

            // While NOW is off screen, a chip on its side of the timeline
            // says how far away it is and jumps back.
            if (_viewMode == TimelineViewMode.day && _offscreenNow != null)
              Positioned(
                left: 0,
                right: 0,
                top: _offscreenNow!.above ? 12 : null,
                bottom: _offscreenNow!.above ? null : 24,
                child: Center(
                  child: NowChip(now: _offscreenNow!, onTap: _jumpToNow),
                ),
              ),
          ],
        ),
        floatingActionButton: _viewMode == TimelineViewMode.day
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskDetailScreen(initialDate: _visibleDate),
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
