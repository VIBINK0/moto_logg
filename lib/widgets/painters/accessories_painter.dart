import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Custom background painter for Accessories Card.
/// Matched with App Theme background palette and subtle emerald green ambient glow.
class AccessoriesPainter extends CustomPainter {
  final double animationValue;

  AccessoriesPainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. UNIFORM APP CARD BACKGROUND
    final bgPaint = Paint()..color = AppColors.cardBg;
    canvas.drawRect(bgRect, bgPaint);

    // Subtle Accessories Emerald Glow Shader
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.6),
        radius: 1.2,
        colors: [
          AppColors.wash.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 2. CARBON HONEYCOMB ARMOR MESH GRID
    final hexPaint = Paint()
      ..color = AppColors.wash.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double radius = 11.0;
    final double hSpacing = radius * sqrt(3);
    const double vSpacing = radius * 1.5;

    for (double y = -radius; y < size.height + radius; y += vSpacing) {
      int row = (y / vSpacing).round();
      double xOffset = (row % 2 == 0) ? 0 : hSpacing / 2;

      for (double x = -radius; x < size.width + radius; x += hSpacing) {
        _drawSingleHexagon(canvas, Offset(x + xOffset, y), radius, hexPaint);
      }
    }

    // 3. HOLOGRAPHIC ACCESSORY TARGET HUD
    Offset hudCenter = Offset(size.width * 0.82, size.height * 0.50);
    double hudRadius = 28.0;

    // Outer notched ring rotating clockwise
    canvas.save();
    canvas.translate(hudCenter.dx, hudCenter.dy);
    canvas.rotate(animationValue * 2 * pi);

    final outerRingPaint = Paint()
      ..color = AppColors.wash.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset.zero, hudRadius, outerRingPaint);
    for (int i = 0; i < 12; i++) {
      double angle = (i / 12) * 2 * pi;
      double r1 = hudRadius - (i % 3 == 0 ? 5 : 3);
      double r2 = hudRadius + (i % 3 == 0 ? 3 : 1);
      canvas.drawLine(
        Offset(cos(angle) * r1, sin(angle) * r1),
        Offset(cos(angle) * r2, sin(angle) * r2),
        outerRingPaint,
      );
    }
    canvas.restore();

    // Inner notched ring rotating counter-clockwise
    canvas.save();
    canvas.translate(hudCenter.dx, hudCenter.dy);
    canvas.rotate(-animationValue * 2 * pi);

    final innerRingPaint = Paint()
      ..color = AppColors.wash.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, hudRadius * 0.65, innerRingPaint);
    canvas.drawLine(Offset(-hudRadius * 0.8, 0), Offset(-hudRadius * 0.4, 0), innerRingPaint);
    canvas.drawLine(Offset(hudRadius * 0.4, 0), Offset(hudRadius * 0.8, 0), innerRingPaint);
    canvas.drawLine(Offset(0, -hudRadius * 0.8), Offset(0, -hudRadius * 0.4), innerRingPaint);
    canvas.drawLine(Offset(0, hudRadius * 0.4), Offset(0, hudRadius * 0.8), innerRingPaint);

    canvas.restore();

    // Center target glow point
    canvas.drawCircle(
      hudCenter,
      3.0 + sin(animationValue * 2 * pi) * 1.0,
      Paint()..color = AppColors.wash.withValues(alpha: 0.85),
    );

    // 4. 360° RADAR / LASER SWEEPER ARC
    canvas.save();
    canvas.translate(hudCenter.dx, hudCenter.dy);
    canvas.rotate(animationValue * 2 * pi);

    final radarSweepShader = SweepGradient(
      colors: [
        Colors.transparent,
        AppColors.wash.withValues(alpha: 0.05),
        AppColors.wash.withValues(alpha: 0.35),
      ],
      stops: const [0.0, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: hudRadius * 1.6));

    canvas.drawCircle(
      Offset.zero,
      hudRadius * 1.5,
      Paint()..shader = radarSweepShader,
    );
    canvas.restore();

    // 5. ROTATING ACCESSORY MOUNT FASTENERS / CORNER HEX BOLTS
    final boltPaint = Paint()
      ..color = AppColors.wash.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawFastenerBolt(
      canvas,
      Offset(size.width * 0.12, size.height * 0.22),
      radius: 6.0,
      rotation: animationValue * 2 * pi,
      paint: boltPaint,
    );

    _drawFastenerBolt(
      canvas,
      Offset(size.width * 0.18, size.height * 0.78),
      radius: 5.5,
      rotation: -animationValue * 2 * pi,
      paint: boltPaint,
    );

    _drawFastenerBolt(
      canvas,
      Offset(size.width * 0.48, size.height * 0.30),
      radius: 5.0,
      rotation: animationValue * 2 * pi,
      paint: boltPaint,
    );

    // 6. FLOATING CYBER SPARKLES / ENERGY PARTICLES
    const int particleCount = 6;
    for (int p = 0; p < particleCount; p++) {
      double pProgress = ((animationValue + (p / particleCount)) % 1.0);
      double px = size.width * (0.15 + (p * 0.14)) + sin(pProgress * 2 * pi + p) * 4;
      double py = size.height * 0.95 - (pProgress * size.height * 0.90);
      double pOpacity = sin(pProgress * pi) * 0.85;

      final pPaint = Paint()
        ..color = AppColors.wash.withValues(alpha: pOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), 1.6 + (p % 2) * 0.8, pPaint);
    }
  }

  void _drawSingleHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * pi / 180;
      double x = center.dx + radius * cos(angle);
      double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFastenerBolt(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double rotation,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    canvas.drawCircle(Offset.zero, radius, paint);
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * pi / 180;
      double x = (radius * 0.5) * cos(angle);
      double y = (radius * 0.5) * sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AccessoriesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
