// lib/widgets/industrial_background.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class IndustrialBackground extends StatefulWidget {
  final Widget child;

  const IndustrialBackground({super.key, required this.child});

  @override
  State<IndustrialBackground> createState() => _IndustrialBackgroundState();
}

class _IndustrialBackgroundState extends State<IndustrialBackground>
    with TickerProviderStateMixin {
  late AnimationController _sparkController;
  late AnimationController _gearController;
  final List<Spark> _sparks = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_generateSparks);
    _sparkController.repeat();

    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _generateSparks() {
    if (_random.nextDouble() > 0.7) {
      _sparks.add(Spark(
        x: _random.nextDouble(),
        y: 0.3 + _random.nextDouble() * 0.4,
        size: 1 + _random.nextDouble() * 3,
        opacity: 0.5 + _random.nextDouble() * 0.5,
        velocity: 0.01 + _random.nextDouble() * 0.02,
      ));
    }
    _sparks.removeWhere((s) => s.opacity <= 0);
    for (var spark in _sparks) {
      spark.update();
    }
  }

  @override
  void dispose() {
    _sparkController.dispose();
    _gearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A1A),
                Color(0xFF0D0D0D),
              ],
            ),
          ),
        ),

        // Industrial texture overlay
        Opacity(
          opacity: 0.1,
          child: CustomPaint(
            size: Size.infinite,
            painter: MetallicTexturePainter(),
          ),
        ),

        // Animated gears
        AnimatedBuilder(
          animation: _gearController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: GearsPainter(
                rotation: _gearController.value * 2 * math.pi,
              ),
            );
          },
        ),

        // Sparks animation
        AnimatedBuilder(
          animation: _sparkController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: SparksPainter(sparks: _sparks),
            );
          },
        ),

        // Dark overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),

        // Vignette effect
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Spark {
  double x;
  double y;
  double size;
  double opacity;
  double velocity;

  Spark({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.velocity,
  });

  void update() {
    y += velocity;
    opacity -= 0.02;
    size *= 0.98;
  }
}

class SparksPainter extends CustomPainter {
  final List<Spark> sparks;

  SparksPainter({required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    for (var spark in sparks) {
      final paint = Paint()
        ..color = Colors.orange.withOpacity(spark.opacity.clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spark.size);

      canvas.drawCircle(
        Offset(spark.x * size.width, spark.y * size.height),
        spark.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GearsPainter extends CustomPainter {
  final double rotation;

  GearsPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw rotating gears in corners
    _drawGear(canvas, Offset(size.width * 0.1, size.height * 0.2), 60, rotation, paint);
    _drawGear(canvas, Offset(size.width * 0.9, size.height * 0.3), 80, -rotation, paint);
    _drawGear(canvas, Offset(size.width * 0.15, size.height * 0.8), 50, rotation * 1.5, paint);
    _drawGear(canvas, Offset(size.width * 0.85, size.height * 0.85), 70, -rotation * 0.8, paint);
  }

  void _drawGear(Canvas canvas, Offset center, double radius, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    const teeth = 12;
    const toothDepth = 10.0;

    for (var i = 0; i < teeth; i++) {
      final angle = (i / teeth) * 2 * math.pi;
      final nextAngle = ((i + 0.5) / teeth) * 2 * math.pi;

      final outerX = math.cos(angle) * (radius + toothDepth);
      final outerY = math.sin(angle) * (radius + toothDepth);
      final innerX = math.cos(nextAngle) * radius;
      final innerY = math.sin(nextAngle) * radius;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset.zero, radius * 0.3, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GearsPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class MetallicTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    // Diagonal industrial lines
    for (var i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
