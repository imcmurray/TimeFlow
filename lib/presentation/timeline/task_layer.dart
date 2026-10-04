import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/presentation/helpers/task_actions.dart';
import 'package:timeflow/presentation/providers/clock_provider.dart';
import 'package:timeflow/presentation/providers/reminder_ack_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/timeline/task_layout.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';
import 'package:timeflow/presentation/timeline/timeline_tasks.dart';
import 'package:timeflow/presentation/widgets/confluence_modal.dart';
import 'package:timeflow/presentation/widgets/merged_task_card.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';
import 'package:timeflow/presentation/widgets/task_card.dart';
import 'package:timeflow/presentation/widgets/task_summary_sheet.dart';
import 'package:timeflow/presentation/widgets/timeline_task_creation_preview.dart';

/// Task cards for the visible days, plus the gestures on the timeline itself:
/// long-press a card and drag to move it, long-press empty space (and drag)
/// to create a task there.
class TaskLayer extends ConsumerStatefulWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const TaskLayer({super.key, required this.geometry, required this.days});

  @override
  ConsumerState<TaskLayer> createState() => _TaskLayerState();
}

class _TaskLayerState extends ConsumerState<TaskLayer> {
  /// Narrower than this, overlapping tasks merge into one confluence card.
  static const _minColumnWidth = 120.0;
  static const _minCardHeight = 30.0;
  static const _longPressDelay = Duration(milliseconds: 500);
  static const _moveSnapMinutes = 5;

  List<Task> _tasks = const [];
  bool _readOnly = false;

  // Moving a task.
  Task? _moving;
  double _moveDelta = 0;

  // Creating a task by long-pressing empty space.
  Timer? _createTimer;
  Offset? _pressStart;
  DateTime? _createStart;
  double _createDragDelta = 0;
  int _lastSnappedEnd = -1;

  TimelineGeometry get _g => widget.geometry;
  TaskActions get _actions => TaskActions(ref);

  @override
  void dispose() {
    _createTimer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------- geometry

  ({double top, double height}) _span(DateTime start, DateTime end) {
    final s = _g.spanOf(start, end);
    if (s.height >= _minCardHeight) return s;
    // Grow short tasks downward from their visual top.
    return (top: s.top, height: _minCardHeight);
  }

  DateTime _snap(DateTime t, int minutes) {
    final snapped = (minuteOfDay(t) / minutes).round() * minutes;
    return DateTime(t.year, t.month, t.day, 0, snapped);
  }

  // --------------------------------------------------------------- moving

  void _startMove(Task task) {
    setState(() {
      _moving = task;
      _moveDelta = 0;
    });
    HapticFeedback.mediumImpact();
  }

  /// Start time the moving task would get if dropped now.
  DateTime _movedStart(Task task) {
    final span = _g.spanOf(task.startTime, task.endTime);
    final top = span.top + _moveDelta;
    // The card's top edge is its start time, or its end time when the
    // future is at the top.
    final edgeTime = _g.timeAt(top);
    final start = _g.futureAtTop
        ? addWallMinutes(edgeTime, -task.durationMinutes)
        : edgeTime;
    return _snap(start, _moveSnapMinutes);
  }

  Future<void> _endMove() async {
    final task = _moving;
    if (task == null) return;
    final newStart = _movedStart(task);
    setState(() => _moving = null);
    await _actions.move(context, task, newStart);
  }

  // ------------------------------------------------------------- creating

  int get _snapMinutes =>
      ref.read(settingsProvider).longPressSnapIntervalMinutes;
  int get _defaultMinutes =>
      ref.read(settingsProvider).longPressDefaultDurationMinutes;

  void _onPointerDown(PointerDownEvent e) {
    _createTimer?.cancel();
    _pressStart = e.localPosition;
    _createTimer = Timer(_longPressDelay, () {
      final start = _snap(_g.timeAt(e.localPosition.dy), _snapMinutes);
      setState(() {
        _createStart = start;
        _createDragDelta = 0;
        _lastSnappedEnd = -1;
      });
      HapticFeedback.mediumImpact();
    });
  }

  void _onPointerMove(PointerMoveEvent e, double width) {
    final start = _pressStart;
    if (start == null) return;
    if (_createStart == null) {
      // Moving before the long press completes means the user is scrolling.
      if ((e.localPosition - start).distance > 20) _cancelCreate();
      return;
    }
    if (e.localPosition.dx < -50 || e.localPosition.dx > width + 50) {
      _cancelCreate();
      return;
    }
    setState(() => _createDragDelta = e.localPosition.dy - start.dy);
    final end = _createEnd();
    if (end != null && minuteOfDay(end) != _lastSnappedEnd) {
      _lastSnappedEnd = minuteOfDay(end);
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    final start = _createStart;
    final end = _createEnd();
    _cancelCreate();
    if (start == null || end == null) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailScreen(initialStartTime: start, initialEndTime: end),
      ),
    );
  }

  void _cancelCreate() {
    _createTimer?.cancel();
    _createTimer = null;
    _pressStart = null;
    if (_createStart != null) setState(() => _createStart = null);
  }

  /// End time of the task being created: the default length, stretched by
  /// dragging (down for later when the future is below, up when it's above).
  DateTime? _createEnd() {
    final start = _createStart;
    if (start == null) return null;
    final dragMinutes =
        (_createDragDelta / _g.hourHeight * 60 * (_g.futureAtTop ? -1 : 1))
            .round();
    final minutes = (_defaultMinutes + dragMinutes).clamp(
      _snapMinutes,
      24 * 60,
    );
    return _snap(addWallMinutes(start, minutes), _snapMinutes);
  }

  // -------------------------------------------------------------- building

  @override
  Widget build(BuildContext context) {
    _tasks = watchTimelineTasks(ref, widget.days, _tasks);
    final now = ref.watch(minuteClockProvider).value ?? DateTime.now();
    final acks = ref.watch(reminderAcksProvider);
    final use24Hour = ref.watch(
      settingsProvider.select((s) => s.use24HourFormat),
    );
    _readOnly = ref.watch(timelineReadOnlyProvider);

    final from = widget.days.start;
    final to = widget.days.end;
    final visible = _tasks
        .where((t) => t.startTime.isBefore(to) && t.endTime.isAfter(from))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final children = <Widget>[
          if (!_readOnly)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onPointerDown,
                onPointerMove: (e) => _onPointerMove(e, width),
                onPointerUp: _onPointerUp,
                onPointerCancel: (_) => _cancelCreate(),
                child: const SizedBox.expand(),
              ),
            ),
          for (final t in visible) ..._reminderDot(t, now, acks[t.id]),
        ];

        for (final cluster in layoutTasks(visible)) {
          final columnWidth = width / cluster.columns;
          if (cluster.columns == 1 || columnWidth >= _minColumnWidth) {
            for (final placed in cluster.placed) {
              children.add(
                _card(
                  placed.task,
                  placed.column * columnWidth,
                  columnWidth - 4,
                  now,
                  acks,
                  use24Hour,
                ),
              );
            }
          } else {
            children.add(_mergedCard(cluster, width, now, acks, use24Hour));
          }
        }

        if (_createStart != null) children.add(_creationPreview(use24Hour));
        return Stack(children: children);
      },
    );
  }

  List<Widget> _reminderDot(Task task, DateTime now, ReminderAck? ack) {
    final state = reminderStateOf(task, now, ack);
    final at = effectiveReminderTime(task, ack);
    if (state == null || state == ReminderState.acknowledged || at == null) {
      return const [];
    }
    return [
      Positioned(
        left: 4,
        top: _g.yOf(at) - 5,
        child: ExcludeSemantics(child: ReminderDot(state: state)),
      ),
    ];
  }

  Widget _card(
    Task task,
    double left,
    double width,
    DateTime now,
    Map<String, ReminderAck> acks,
    bool use24Hour,
  ) {
    final moving = _moving?.id == task.id;
    var display = task;
    var span = _span(task.startTime, task.endTime);
    if (moving) {
      final start = _movedStart(task);
      display = task.copyWith(
        startTime: start,
        endTime: addWallMinutes(start, task.durationMinutes),
      );
      span = (top: span.top + _moveDelta, height: span.height);
    }
    final ack = acks[task.id];
    final reminderState = reminderStateOf(task, now, ack);

    return Positioned(
      key: ValueKey(task.id),
      top: span.top,
      left: left,
      width: width,
      height: span.height,
      child: GestureDetector(
        onLongPressStart: _readOnly ? null : (_) => _startMove(task),
        onLongPressMoveUpdate: _readOnly
            ? null
            : (d) => setState(() => _moveDelta = d.localOffsetFromOrigin.dy),
        onLongPressEnd: _readOnly ? null : (_) => _endMove(),
        onLongPressCancel: _readOnly
            ? null
            : () => setState(() => _moving = null),
        child: AnimatedScale(
          scale: moving ? 1.03 : 1,
          duration: const Duration(milliseconds: 150),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: moving
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: TaskCard(
              task: display,
              reminderState: reminderState,
              reminderTime: effectiveReminderTime(task, ack),
              onTap: moving ? null : () => _openDetail(task),
              onComplete: moving || _readOnly
                  ? null
                  : () => _actions.toggleComplete(task),
              onDelete: moving || _readOnly
                  ? null
                  : () => _actions.delete(context, task),
              onReminderAcknowledged: reminderState == ReminderState.triggered
                  ? () => ref
                        .read(reminderAcksProvider.notifier)
                        .acknowledge(task)
                  : null,
              onReminderRescheduled: reminderState == ReminderState.acknowledged
                  ? () => ref.read(reminderAcksProvider.notifier).snooze(task)
                  : null,
              use24HourFormat: use24Hour,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mergedCard(
    TaskCluster cluster,
    double width,
    DateTime now,
    Map<String, ReminderAck> acks,
    bool use24Hour,
  ) {
    final tasks = cluster.tasks;
    final span = _span(cluster.start, cluster.end);
    final states = <String, ReminderState>{};
    final times = <String, DateTime>{};
    for (final t in tasks) {
      final s = reminderStateOf(t, now, acks[t.id]);
      if (s != null) states[t.id] = s;
      final at = effectiveReminderTime(t, acks[t.id]);
      if (at != null) times[t.id] = at;
    }
    return Positioned(
      key: ValueKey('cluster-${tasks.first.id}'),
      top: span.top,
      left: 0,
      width: width - 4,
      height: span.height,
      child: MergedTaskCard(
        tasks: tasks,
        use24HourFormat: use24Hour,
        reminderStates: states,
        reminderTimes: times,
        onTap: () => _showConfluence(tasks, states, times, use24Hour),
        onTapTask: _openDetail,
      ),
    );
  }

  Widget _creationPreview(bool use24Hour) {
    final start = _createStart!;
    final end = _createEnd()!;
    final span = _g.spanOf(start, end);
    final conflict = _tasks.any(
      (t) => start.isBefore(t.endTime) && end.isAfter(t.startTime),
    );
    return Positioned(
      top: span.top,
      left: 0,
      right: 4,
      height: span.height < 40 ? 40 : span.height,
      child: TaskCreationPreview(
        startTime: start,
        endTime: end,
        duration: Duration(minutes: wallMinutesBetween(start, end)),
        use24HourFormat: use24Hour,
        hasConflict: conflict,
      ),
    );
  }

  void _showConfluence(
    List<Task> tasks,
    Map<String, ReminderState> states,
    Map<String, DateTime> times,
    bool use24Hour,
  ) {
    showConfluenceModal(
      context: context,
      tasks: tasks,
      use24HourFormat: use24Hour,
      reminderStates: states,
      reminderTimes: times,
      onTaskTap: (task) {
        Navigator.of(context).pop();
        _openDetail(task);
      },
      onTaskComplete: _readOnly ? null : _actions.toggleComplete,
      onTaskDelete: _readOnly
          ? null
          : (task) async {
              Navigator.of(context).pop();
              await _actions.delete(context, task);
            },
      onReminderAcknowledged: (task) =>
          ref.read(reminderAcksProvider.notifier).acknowledge(task),
      onReminderRescheduled: (task) =>
          ref.read(reminderAcksProvider.notifier).snooze(task),
    );
  }

  void _openDetail(Task task) {
    if (_readOnly) {
      showTaskSummarySheet(
        context,
        task,
        use24Hour: ref.read(settingsProvider).use24HourFormat,
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
  }
}
