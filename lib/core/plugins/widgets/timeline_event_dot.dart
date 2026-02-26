import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// Renders a single plugin event as a dot (zero/short duration)
/// or thin bar (events with duration > 0).
class TimelineEventDot extends StatelessWidget {
  final TimelineEvent event;
  final double top;
  final double? barHeight;
  final VoidCallback? onTap;

  const TimelineEventDot({
    super.key,
    required this.event,
    required this.top,
    this.barHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? Theme.of(context).colorScheme.primary;
    final hasDuration = barHeight != null && barHeight! > 2;

    if (hasDuration) {
      // Thin bar for events with duration
      return Positioned(
        top: top,
        left: 0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 4,
            height: barHeight!,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Dot for point-in-time events
    return Positioned(
      top: top - 7,
      left: -3,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
