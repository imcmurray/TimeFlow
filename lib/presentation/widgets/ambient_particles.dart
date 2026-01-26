import 'dart:math';
import 'package:flutter/material.dart';

/// Ambient floating particles that drift across the timeline.
///
/// Creates a subtle, calming effect of particles flowing like
/// sediment in a gentle river current.
class AmbientParticles extends StatefulWidget {
  /// Number of particles to display.
  final int particleCount;

  /// Base color for particles.
  final Color color;

  /// Whether particles drift downward (true) or upward (false).
  final bool driftDown;

  /// Animation speed multiplier.
  final double speed;

  const AmbientParticles({
    super.key,
    this.particleCount = 30,
    this.color = Colors.white,
    this.driftDown = true,
    this.speed = 1.0,
  });

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (_) => _generateParticle(),
    );
  }

  _Particle _generateParticle({double? startY}) {
    return _Particle(
      x: _random.nextDouble(),
      y: startY ?? _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      opacity: _random.nextDouble() * 0.3 + 0.1,
      speed: (_random.nextDouble() * 0.5 + 0.5) * widget.speed,
      wobbleOffset: _random.nextDouble() * 2 * pi,
      wobbleSpeed: _random.nextDouble() * 2 + 1,
    );
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
          painter: _ParticlePainter(
            particles: _particles,
            color: widget.color,
            progress: _controller.value,
            driftDown: widget.driftDown,
            onParticleOffscreen: (index) {
              // Reset particle to top/bottom when it goes offscreen
              _particles[index] = _generateParticle(
                startY: widget.driftDown ? 0.0 : 1.0,
              );
            },
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double opacity;
  final double speed;
  final double wobbleOffset;
  final double wobbleSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.wobbleOffset,
    required this.wobbleSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double progress;
  final bool driftDown;
  final void Function(int index) onParticleOffscreen;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.progress,
    required this.driftDown,
    required this.onParticleOffscreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Calculate position with drift and wobble
      final wobble = sin(progress * 2 * pi * particle.wobbleSpeed + particle.wobbleOffset) * 0.02;
      final drift = progress * particle.speed * 0.1;

      double y;
      if (driftDown) {
        y = (particle.y + drift) % 1.0;
      } else {
        y = (particle.y - drift) % 1.0;
        if (y < 0) y += 1.0;
      }

      final x = (particle.x + wobble) % 1.0;

      // Update particle position for next frame
      particle.x = x;
      particle.y = y;

      // Check if particle went offscreen
      if ((driftDown && y < 0.01 && drift > 0.05) ||
          (!driftDown && y > 0.99 && drift > 0.05)) {
        onParticleOffscreen(i);
      }

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
