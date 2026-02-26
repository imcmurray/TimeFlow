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

  int get _mergedCount {
    final count = event.metadata['_mergedCount'];
    return count is int ? count : 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? Theme.of(context).colorScheme.primary;
    final hasDuration = barHeight != null && barHeight! > 2;
    final showBadge = _mergedCount > 1;

    if (hasDuration) {
      return Positioned(
        top: top,
        left: 0,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: showBadge ? 20 : 4,
            height: barHeight!,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                if (showBadge)
                  Positioned(
                    top: -6,
                    left: 2,
                    child: _CountBadge(count: _mergedCount, color: color),
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
        child: SizedBox(
          width: showBadge ? 28 : 14,
          height: showBadge ? 24 : 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
              if (showBadge)
                Positioned(
                  top: -6,
                  right: -2,
                  child: _CountBadge(count: _mergedCount, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
