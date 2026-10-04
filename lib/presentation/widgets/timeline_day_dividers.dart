import 'package:flutter/material.dart';
import 'package:timeflow/presentation/utils/timeline_offset.dart';
import 'package:timeflow/presentation/widgets/day_boundary_marker.dart';

/// Displays day dividers at midnight boundaries.
class DayDividers extends StatelessWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;

  const DayDividers({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
  });

  double _getOffsetForDayStart(int dayOffset) {
    return TimelineOffset.forHour(
      dayOffset: dayOffset,
      hour: 0,
      hourHeight: hourHeight,
      daysLoadedBefore: daysLoadedBefore,
      daysLoadedAfter: daysLoadedAfter,
      upcomingTasksAboveNow: upcomingTasksAboveNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dividers = <Widget>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int dayOffset = -daysLoadedBefore;
        dayOffset <= daysLoadedAfter;
        dayOffset++) {
      final date = referenceDate.add(Duration(days: dayOffset));
      final offset = _getOffsetForDayStart(dayOffset);

      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      dividers.add(
        Positioned(
          top: offset - 16,
          left: 70,
          right: 16,
          child: SimpleDayDivider(
            date: date,
            isToday: isToday,
          ),
        ),
      );
    }

    return Stack(children: dividers);
  }
}

/// Overlay that renders day divider lines on top of task cards.
/// This allows users to see midnight boundaries through tasks that span days.
class DayDividerOverlay extends StatelessWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;

  const DayDividerOverlay({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
  });

  double _getOffsetForDayStart(int dayOffset) {
    return TimelineOffset.forHour(
      dayOffset: dayOffset,
      hour: 0,
      hourHeight: hourHeight,
      daysLoadedBefore: daysLoadedBefore,
      daysLoadedAfter: daysLoadedAfter,
      upcomingTasksAboveNow: upcomingTasksAboveNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2);

    final lines = <Widget>[];

    for (int dayOffset = -daysLoadedBefore;
        dayOffset <= daysLoadedAfter;
        dayOffset++) {
      final offset = _getOffsetForDayStart(dayOffset);

      lines.add(
        Positioned(
          top: offset,
          left: 70,
          right: 16,
          child: CustomPaint(
            size: const Size(double.infinity, 2),
            painter: DashedLinePainter(color: lineColor),
          ),
        ),
      );
    }

    return Stack(children: lines);
  }
}

/// Paints a dashed horizontal line.
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  static const double _dashWidth = 6;
  static const double _dashSpace = 4;
  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + _dashWidth, y),
        paint,
      );
      startX += _dashWidth + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
