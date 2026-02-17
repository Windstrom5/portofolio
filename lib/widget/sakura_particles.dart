import 'package:flutter/material.dart';
import 'dart:math' as math;

class SakuraParticles extends StatefulWidget {
  const SakuraParticles({super.key});

  @override
  State<SakuraParticles> createState() => _SakuraParticlesState();
}

class _SakuraParticlesState extends State<SakuraParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SakuraPetal> _petals =
      List.generate(20, (index) => _SakuraPetal());

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
          painter: _SakuraPainter(_petals, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SakuraPetal {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 8 + 4;
  double speed = math.Random().nextDouble() * 0.1 + 0.05;
  double angle = math.Random().nextDouble() * math.pi * 2;
}

class _SakuraPainter extends CustomPainter {
  final List<_SakuraPetal> petals;
  final double progress;

  _SakuraPainter(this.petals, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.isFinite) return;
    final paint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var petal in petals) {
      double dx = petal.x * size.width +
          math.sin(progress * math.pi * 2 + petal.angle) * 20;
      double dy = (petal.y + progress * petal.speed * 10) % 1.0 * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(petal.angle + progress * math.pi);

      var path = Path();
      path.moveTo(0, -petal.size / 2);
      path.quadraticBezierTo(petal.size / 2, -petal.size, petal.size, 0);
      path.quadraticBezierTo(petal.size / 2, petal.size, 0, petal.size / 2);
      path.quadraticBezierTo(-petal.size / 2, petal.size, -petal.size, 0);
      path.quadraticBezierTo(-petal.size / 2, -petal.size, 0, -petal.size / 2);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
