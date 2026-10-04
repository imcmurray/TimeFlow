import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/theme/app_colors.dart';
import 'package:cron_timeflow/presentation/providers/settings_provider.dart';
import 'package:cron_timeflow/presentation/utils/time_formatter.dart';

/// NOW line that scrolls with the timeline content.
/// Long-press and drag to change where on the viewport the NOW line appears.
class NowLineScrollable extends ConsumerStatefulWidget {
  final DateTime currentTime;
  final double nowOffset;
  final bool use24HourFormat;
  final double scrollOffset;
  final double viewportHeight;
  final VoidCallback? onPositionChanged;

  const NowLineScrollable({
    super.key,
    required this.currentTime,
    required this.nowOffset,
    required this.scrollOffset,
    required this.viewportHeight,
    this.use24HourFormat = false,
    this.onPositionChanged,
  });

  @override
  ConsumerState<NowLineScrollable> createState() => _NowLineScrollableState();
}

class _NowLineScrollableState extends ConsumerState<NowLineScrollable> {
  double? _dragDelta;

  String _formatTime(DateTime time) =>
      TimeFormatter.formatTime(time, use24HourFormat: widget.use24HourFormat);

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
      ref
          .read(settingsProvider.notifier)
          .setNowLineViewportPosition(newPosition);

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
