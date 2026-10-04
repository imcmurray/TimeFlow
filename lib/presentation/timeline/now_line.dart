import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// The NOW line. It sits in the scrolling content at the current time; the
/// timeline scrolls so it stays at a fixed place on screen.
///
/// Long-press and drag it to choose where on screen NOW should sit.
class NowLine extends ConsumerStatefulWidget {
  final DateTime currentTime;

  /// Vertical position of [currentTime] in the timeline content.
  final double y;
  final ScrollController scrollController;

  /// Called after the user moves the line, to re-align the timeline.
  final VoidCallback? onPositionChanged;

  const NowLine({
    super.key,
    required this.currentTime,
    required this.y,
    required this.scrollController,
    this.onPositionChanged,
  });

  @override
  ConsumerState<NowLine> createState() => _NowLineState();
}

class _NowLineState extends ConsumerState<NowLine> {
  double? _dragDelta;

  void _start(LongPressStartDetails _) {
    setState(() => _dragDelta = 0);
    HapticFeedback.mediumImpact();
  }

  void _update(LongPressMoveUpdateDetails d) =>
      setState(() => _dragDelta = d.offsetFromOrigin.dy);

  void _end(LongPressEndDetails _) {
    final delta = _dragDelta;
    setState(() => _dragDelta = null);
    final scroll = widget.scrollController;
    if (delta == null || !scroll.hasClients) return;
    final screenY = widget.y - scroll.offset + delta;
    ref.read(settingsProvider.notifier).setNowLineViewportPosition(
        screenY / scroll.position.viewportDimension);
    widget.onPositionChanged?.call();
    HapticFeedback.lightImpact();
  }

  void _cancel() => setState(() => _dragDelta = null);

  Widget _draggable(Widget child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: _start,
        onLongPressMoveUpdate: _update,
        onLongPressEnd: _end,
        onLongPressCancel: _cancel,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.nowLineDark : AppColors.nowLineLight;
    final onColor = isDark ? AppColors.onNowLineDark : AppColors.onNowLineLight;
    final use24Hour =
        ref.watch(settingsProvider.select((s) => s.use24HourFormat));
    final dragging = _dragDelta != null;
    final y = widget.y + (_dragDelta ?? 0);
    final time = TimeFormatter.formatTime(widget.currentTime,
        use24HourFormat: use24Hour);

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: y - 20,
          height: 40,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: dragging ? 0.6 : 0.4),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: y - 20,
          height: 40,
          child: Semantics(
            label: 'Now, $time',
            hint: 'Long press and drag to move the NOW line',
            liveRegion: false,
            child: _draggable(
              Center(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: dragging ? 8 : 4,
                        spreadRadius: dragging ? 2 : 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: y - 14,
          child: ExcludeSemantics(
            child: _draggable(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: dragging ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: y - 12,
          child: ExcludeSemantics(
            child: _draggable(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NOW',
                  style: TextStyle(
                    color: onColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
