import 'package:flutter/material.dart';
import 'package:cron_timeflow/presentation/utils/time_formatter.dart';

/// Preview widget shown during long-press task creation.
/// Displays a semi-transparent box with the task duration.
class TaskCreationPreview extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool use24HourFormat;
  final bool hasConflict;

  const TaskCreationPreview({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.use24HourFormat,
    this.hasConflict = false,
  });

  String _formatTime(DateTime time) =>
      TimeFormatter.formatTime(time, use24HourFormat: use24HourFormat);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if task crosses midnight (spans multiple days)
  bool get _crossesMidnight {
    final startDay = DateTime(startTime.year, startTime.month, startTime.day);
    final endDay = DateTime(endTime.year, endTime.month, endTime.day);
    return endDay.isAfter(startDay);
  }

  /// Get the number of days the task spans
  int get _daySpan {
    final startDay = DateTime(startTime.year, startTime.month, startTime.day);
    final endDay = DateTime(endTime.year, endTime.month, endTime.day);
    return endDay.difference(startDay).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Use orange/red color when there's a conflict
    final conflictColor = Colors.orange;
    final baseColor = hasConflict ? conflictColor : primaryColor;

    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: baseColor.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRect(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showTimeRange = constraints.maxHeight > 50;
                final showDuration = constraints.maxHeight > 80;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "New Task" label with conflict warning
                    Row(
                      children: [
                        if (hasConflict) ...[
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: conflictColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            hasConflict ? 'Overlapping Task' : 'New Task',
                            style: TextStyle(
                              color: hasConflict
                                  ? conflictColor
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Time range with midnight crossing indicator
                    if (showTimeRange) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          if (_crossesMidnight) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    (isDark ? Colors.white24 : Colors.black12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${_daySpan}d',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    // Duration badge at bottom
                    if (showDuration) ...[
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
