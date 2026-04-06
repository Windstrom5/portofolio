import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ZUTOMAYO-inspired floating geometric particles
/// Triangles, diamonds, circles, and crosses in the signature
/// midnight color palette (deep purple, hot pink, electric blue, warm yellow)
class SakuraParticles extends StatefulWidget {
  const SakuraParticles({super.key});

  @override
  State<SakuraParticles> createState() => _SakuraParticlesState();
}

class _SakuraParticlesState extends State<SakuraParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MidnightParticle> _particles =
      List.generate(25, (index) => _MidnightParticle());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
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
          painter: _MidnightPainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

// ZUTOMAYO color palette
const _ztmyColors = [
  Color(0x557B2FF7), // Deep purple
  Color(0x55FF2D78), // Hot pink
  Color(0x5500D4FF), // Electric blue
  Color(0x55FFD700), // Warm yellow
  Color(0x44C084FC), // Soft lavender
  Color(0x44FF6B9D), // Rose
];

enum _ShapeType { triangle, diamond, circle, cross, ring, dot }

class _MidnightParticle {
  final _rng = math.Random();

  late double x = _rng.nextDouble();
  late double y = _rng.nextDouble();
  late double size = _rng.nextDouble() * 8 + 3;
  late double speed = _rng.nextDouble() * 0.08 + 0.02;
  late double drift = (_rng.nextDouble() - 0.5) * 0.3;
  late double angle = _rng.nextDouble() * math.pi * 2;
  late double rotSpeed = (_rng.nextDouble() - 0.5) * 2.0;
  late double fadePhase = _rng.nextDouble() * math.pi * 2;
  late Color color = _ztmyColors[_rng.nextInt(_ztmyColors.length)];
  late _ShapeType shape =
      _ShapeType.values[_rng.nextInt(_ShapeType.values.length)];
}

class _MidnightPainter extends CustomPainter {
  final List<_MidnightParticle> particles;
  final double progress;

  _MidnightPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.isFinite) return;

    for (var p in particles) {
      // Floating drift + vertical fall
      double dx = p.x * size.width +
          math.sin(progress * math.pi * 2 + p.angle) * 30 * p.drift;
      double dy = (p.y + progress * p.speed * 8) % 1.0 * size.height;

      // Pulsing opacity
      double opacity =
          (math.sin(progress * math.pi * 6 + p.fadePhase) * 0.3 + 0.5)
              .clamp(0.15, 0.65);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;

      final strokePaint = Paint()
        ..color = p.color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.angle + progress * math.pi * p.rotSpeed);

      final s = p.size;

      switch (p.shape) {
        case _ShapeType.triangle:
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s * 0.866, s * 0.5)
            ..lineTo(-s * 0.866, s * 0.5)
            ..close();
          canvas.drawPath(path, paint);
          canvas.drawPath(path, strokePaint);
          break;

        case _ShapeType.diamond:
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s * 0.6, 0)
            ..lineTo(0, s)
            ..lineTo(-s * 0.6, 0)
            ..close();
          canvas.drawPath(path, paint);
          canvas.drawPath(path, strokePaint);
          break;

        case _ShapeType.circle:
          canvas.drawCircle(Offset.zero, s * 0.5, paint);
          canvas.drawCircle(Offset.zero, s * 0.5, strokePaint);
          break;

        case _ShapeType.cross:
          final crossPaint = Paint()
            ..color = p.color.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(0, -s * 0.6), Offset(0, s * 0.6), crossPaint);
          canvas.drawLine(Offset(-s * 0.6, 0), Offset(s * 0.6, 0), crossPaint);
          break;

        case _ShapeType.ring:
          final ringPaint = Paint()
            ..color = p.color.withOpacity(opacity * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawCircle(Offset.zero, s * 0.5, ringPaint);
          break;

        case _ShapeType.dot:
          canvas.drawCircle(Offset.zero, s * 0.25,
              paint..color = p.color.withOpacity(opacity * 1.2));
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
