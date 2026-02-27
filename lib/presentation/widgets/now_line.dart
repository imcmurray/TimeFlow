import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/theme/app_colors.dart';
import 'package:cron_timeflow/presentation/utils/time_formatter.dart';

/// The fixed NOW line that displays across the timeline.
///
/// This line stays fixed at ~75% down the screen, showing the current time
/// with a subtle glow effect. Tasks flow past this line as time progresses.
class NowLine extends StatefulWidget {
  /// Position of the NOW line as fraction from top (0.0 to 1.0).
  /// Default is 0.75 (75% down the screen).
  final double position;

  const NowLine({
    super.key,
    this.position = 0.75,
  });

  @override
  State<NowLine> createState() => _NowLineState();
}

class _NowLineState extends State<NowLine> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Update time display every second
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) => TimeFormatter.formatTime(time);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.nowLineDark : AppColors.nowLineLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final yPosition = constraints.maxHeight * widget.position;

        return Stack(
          children: [
            // Glow effect behind the line
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: yPosition - 20,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0),
                          lineColor.withValues(alpha: _pulseAnimation.value),
                          lineColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main NOW line
            Positioned(
              left: 0,
              right: 0,
              top: yPosition - 1,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: lineColor,
                  boxShadow: [
                    BoxShadow(
                      color: lineColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Time badge
            Positioned(
              right: 16,
              top: yPosition - 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: lineColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatTime(_currentTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // NOW label
            Positioned(
              left: 12,
              top: yPosition - 12,
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
          ],
        );
      },
    );
  }
}
