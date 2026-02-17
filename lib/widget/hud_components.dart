import 'package:flutter/material.dart';
import 'dart:math' as math;

class HUDPainter extends CustomPainter {
  final Color accentColor;
  final double cornerRadius;
  final double bracketSize;
  final bool showGrid;
  final bool showScanlines;
  final double opacity;

  HUDPainter({
    this.accentColor = Colors.cyanAccent,
    this.cornerRadius = 24.0,
    this.bracketSize = 30.0,
    this.showGrid = true,
    this.showScanlines = true,
    this.opacity = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.isFinite) return;
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Background HUD shape with angled corners
    final path = Path()
      ..moveTo(cornerRadius, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..lineTo(size.width, cornerRadius)
      ..lineTo(size.width, size.height - cornerRadius)
      ..lineTo(size.width - cornerRadius, size.height)
      ..lineTo(cornerRadius, size.height)
      ..lineTo(0, size.height - cornerRadius)
      ..lineTo(0, cornerRadius)
      ..close();

    canvas.drawShadow(path, accentColor.withOpacity(0.3), 8, true);
    canvas.drawPath(path, paint);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = accentColor.withOpacity(0.05)
        ..strokeWidth = 0.5;

      for (double i = 0; i < size.width; i += 25) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      }
      for (double i = 0; i < size.height; i += 25) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }
    }

    if (showScanlines) {
      final scanlinePaint = Paint()
        ..color = Colors.white.withOpacity(0.02)
        ..strokeWidth = 1.0;
      for (double i = 0; i < size.height; i += 5) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), scanlinePaint);
      }
    }

    // Neon Border
    final borderPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // HUD Brackets with Pulse
    final pulse =
        (math.sin(DateTime.now().millisecondsSinceEpoch / 500) * 0.5) + 0.5;
    final bracketPaint = Paint()
      ..color = accentColor.withOpacity(0.3 + (pulse * 0.7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Optional: Add a subtle glow/shadow to the pulse
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.2 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    _drawBrackets(canvas, size, glowPaint);
    _drawBrackets(canvas, size, bracketPaint);
  }

  void _drawBrackets(Canvas canvas, Size size, Paint paint) {
    // Top Left
    canvas.drawPath(
        Path()
          ..moveTo(0, bracketSize)
          ..lineTo(0, 0)
          ..lineTo(bracketSize, 0),
        paint);
    // Top Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - bracketSize, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, bracketSize),
        paint);
    // Bottom Left
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - bracketSize)
          ..lineTo(0, size.height)
          ..lineTo(bracketSize, size.height),
        paint);
    // Bottom Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - bracketSize, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - bracketSize),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HUDContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color accentColor;
  final double cornerRadius;
  final double bracketSize;
  final bool showGrid;
  final bool showScanlines;
  final double opacity;

  const HUDContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.accentColor = Colors.cyanAccent,
    this.cornerRadius = 24.0,
    this.bracketSize = 30.0,
    this.showGrid = true,
    this.showScanlines = true,
    this.opacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: CustomPaint(
        painter: HUDPainter(
          accentColor: accentColor,
          cornerRadius: cornerRadius, // Reverted the incorrect string literal
          bracketSize: bracketSize,
          showGrid: showGrid,
          showScanlines: showScanlines,
          opacity: opacity,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
