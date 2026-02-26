import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';

/// Descriptive metadata for each [DisplayMode].
extension DisplayModeInfo on DisplayMode {
  String get displayName {
    switch (this) {
      case DisplayMode.individualDots:
        return 'Individual Dots';
      case DisplayMode.hostSummary:
        return 'By Host';
      case DisplayMode.timeClusters:
        return 'Clustered';
    }
  }

  String get description {
    switch (this) {
      case DisplayMode.individualDots:
        return 'Each cron job appears as a separate dot on the timeline.';
      case DisplayMode.hostSummary:
        return 'Jobs are grouped into bars by host, showing activity ranges.';
      case DisplayMode.timeClusters:
        return 'Nearby jobs merge into clusters showing the count per window.';
    }
  }

  IconData get icon {
    switch (this) {
      case DisplayMode.individualDots:
        return Icons.scatter_plot;
      case DisplayMode.hostSummary:
        return Icons.dns_outlined;
      case DisplayMode.timeClusters:
        return Icons.bubble_chart;
    }
  }
}

/// A selectable card showing a display mode's name, description, icon,
/// and a mini [CustomPaint] preview of what the timeline will look like.
class DisplayModeCard extends StatelessWidget {
  final DisplayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const DisplayModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Icon(
                mode.icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mini preview
              CustomPaint(
                size: const Size(80, 56),
                painter: _DisplayModePreviewPainter(
                  mode: mode,
                  primaryColor: colorScheme.primary,
                  secondaryColor: colorScheme.tertiary,
                  tertiaryColor: colorScheme.secondary,
                  lineColor: colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a stylized mini-preview of how each display mode renders events.
class _DisplayModePreviewPainter extends CustomPainter {
  final DisplayMode mode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color lineColor;

  _DisplayModePreviewPainter({
    required this.mode,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical timeline line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(10, 0),
      Offset(10, size.height),
      linePaint,
    );

    switch (mode) {
      case DisplayMode.individualDots:
        _paintDots(canvas, size);
      case DisplayMode.hostSummary:
        _paintBars(canvas, size);
      case DisplayMode.timeClusters:
        _paintClusters(canvas, size);
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final colors = [primaryColor, secondaryColor, tertiaryColor];
    // Scattered dots at various positions
    final dots = [
      (18.0, 8.0, 3.5, 0),
      (35.0, 15.0, 3.0, 1),
      (50.0, 10.0, 3.5, 2),
      (25.0, 28.0, 3.0, 0),
      (60.0, 32.0, 3.5, 1),
      (42.0, 44.0, 3.0, 2),
    ];
    for (final (x, y, r, ci) in dots) {
      final paint = Paint()..color = colors[ci];
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    final bars = [
      (primaryColor, 8.0, 55.0),
      (secondaryColor, 24.0, 40.0),
      (tertiaryColor, 40.0, 30.0),
    ];
    for (final (color, y, width) in bars) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(18, y, width, 8),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintClusters(Canvas canvas, Size size) {
    final clusters = [
      (primaryColor, 35.0, 14.0, 12.0, '3'),
      (secondaryColor, 55.0, 35.0, 10.0, '5'),
      (tertiaryColor, 30.0, 48.0, 8.0, '2'),
    ];
    for (final (color, cx, cy, r, label) in clusters) {
      final paint = Paint()..color = color.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(cx, cy), r, paint);
      // Border
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), r, borderPaint);
      // Count text
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: math.min(r, 10),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DisplayModePreviewPainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.primaryColor != primaryColor;
  }
}
