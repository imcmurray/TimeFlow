import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A subtle water ripple effect painter for the Confluent Merge cards.
///
/// Creates gentle concentric circles that emanate from the center,
/// evoking the feeling of rivers converging.
class WaterRipplePainter extends CustomPainter {
  /// Animation value from 0.0 to 1.0, controls ripple expansion.
  final double animationValue;

  /// Base color for the ripples.
  final Color color;

  /// Number of ripple rings to display.
  final int rippleCount;

  WaterRipplePainter({
    required this.animationValue,
    required this.color,
    this.rippleCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.6;

    for (int i = 0; i < rippleCount; i++) {
      // Stagger each ripple by offsetting its animation phase
      final phaseOffset = i / rippleCount;
      final adjustedValue = (animationValue + phaseOffset) % 1.0;

      // Ripple expands from center
      final radius = maxRadius * adjustedValue;

      // Fade out as ripple expands
      final opacity = (1.0 - adjustedValue) * 0.15;

      if (opacity > 0.01) {
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WaterRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

/// A widget that wraps content with an animated water ripple effect.
class WaterRippleEffect extends StatefulWidget {
  /// The child widget to display.
  final Widget child;

  /// The color of the ripples.
  final Color rippleColor;

  /// Whether the ripple animation is active.
  final bool isActive;

  /// Duration of one complete ripple cycle.
  final Duration duration;

  const WaterRippleEffect({
    super.key,
    required this.child,
    required this.rippleColor,
    this.isActive = true,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<WaterRippleEffect> createState() => _WaterRippleEffectState();
}

class _WaterRippleEffectState extends State<WaterRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaterRippleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WaterRipplePainter(
            animationValue: _controller.value,
            color: widget.rippleColor,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
