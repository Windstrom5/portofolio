import 'package:flutter/material.dart';
import 'dart:math' as math;

class CrtOverlay extends StatefulWidget {
  final Widget child;
  const CrtOverlay({super.key, required this.child});

  @override
  State<CrtOverlay> createState() => _CrtOverlayState();
}

class _CrtOverlayState extends State<CrtOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CrtPainter(offset: _controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CrtPainter extends CustomPainter {
  final double offset;

  _CrtPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.isFinite) return;
    final Rect rect = Offset.zero & size;

    // 1. Scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      // Slightly animate the scanlines moving down
      double y = (i + (offset * 4)) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // 2. Large Rolling Interference Bar (Subtle)
    final barY = (offset * size.height) % size.height;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.015),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final barPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, barY - 100, size.width, 200));
    canvas.drawRect(Rect.fromLTWH(0, barY - 100, size.width, 200), barPaint);

    // 3. Vignette (Darkened Edges)
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.1),
        Colors.black.withOpacity(0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final vignettePaint = Paint()
      ..shader = vignetteGradient.createShader(rect)
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(rect, vignettePaint);

    // 4. Slight Static Noise (Random dots)
    // We only do this occasionally or subtly to avoid performance hits
    final random = math.Random(offset.hashCode);
    final noisePaint = Paint()..color = Colors.white.withOpacity(0.01);
    for (int i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        0.5,
        noisePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrtPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
