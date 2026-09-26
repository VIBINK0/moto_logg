import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Custom background painter for Modifications Card.
/// Matched with App Theme background palette and subtle purple ambient glow.
class ModificationsPainter extends CustomPainter {
  final double animationValue;

  ModificationsPainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. UNIFORM APP CARD BACKGROUND
    final bgPaint = Paint()..color = AppColors.cardBg;
    canvas.drawRect(bgRect, bgPaint);

    // Subtle Modifications Purple Glow Shader
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.6),
        radius: 1.2,
        colors: [
          AppColors.mods.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 2. CARBON FIBER RACING MESH
    final carbonPaint = Paint()
      ..color = AppColors.mods.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (double i = -size.height; i < size.width; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height * 1.2, size.height), carbonPaint);
    }

    // 3. SPINNING TRACK TYRE & BRAKE DISC ROTOR (Right side)
    Offset tyreCenter = Offset(size.width * 0.82, size.height * 0.52);
    _drawTrackTyre(
      canvas,
      center: tyreCenter,
      radius: 28.0,
      rotation: animationValue * 2 * pi,
    );

    // 4. CNC ADJUSTABLE BRAKE / CLUTCH LEVER (Top-left area)
    Offset leverPivot = Offset(size.width * 0.15, size.height * 0.28);
    _drawBrakeLever(
      canvas,
      pivot: leverPivot,
      pullAngle: sin(animationValue * 2 * pi) * 0.16,
    );

    // 5. CUSTOM CARBON EXHAUST MUFFLER & EXHAUST FLAME PUFFS (Bottom area)
    Offset exhaustOutlet = Offset(size.width * 0.42, size.height * 0.78);
    _drawExhaustMuffler(
      canvas,
      outlet: exhaustOutlet,
      animVal: animationValue,
    );

    // 6. FLOATING NITRO SPARKS
    const int sparkCount = 6;
    for (int p = 0; p < sparkCount; p++) {
      double pProgress = ((animationValue + (p / sparkCount)) % 1.0);
      double px = size.width * (0.10 + (p * 0.15)) + sin(pProgress * 2 * pi + p) * 5;
      double py = size.height * 0.95 - (pProgress * size.height * 0.90);
      double pOpacity = sin(pProgress * pi) * 0.85;

      final sparkPaint = Paint()
        ..color = (p % 2 == 0 ? AppColors.mods : const Color(0xFFFF4081))
            .withValues(alpha: pOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), 1.6 + (p % 3) * 0.8, sparkPaint);
    }
  }

  void _drawTrackTyre(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
  }) {
    // Fixed Red Brake Caliper
    final caliperPaint = Paint()
      ..color = AppColors.other.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      1.15 * pi,
      0.55 * pi,
      true,
      caliperPaint,
    );

    // Rotating Tyre & Disc Rotor
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Outer Tyre Rubber
    final tyrePaint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;

    canvas.drawCircle(Offset.zero, radius, tyrePaint);

    // Tyre Tread Notches
    final treadPaint = Paint()
      ..color = AppColors.mods.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;

    for (int t = 0; t < 12; t++) {
      double angle = (t / 12) * 2 * pi;
      canvas.drawLine(
        Offset(cos(angle) * (radius - 3), sin(angle) * (radius - 3)),
        Offset(cos(angle) * (radius + 3), sin(angle) * (radius + 3)),
        treadPaint,
      );
    }

    // Drilled Disc Rotor
    final rotorPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    canvas.drawCircle(Offset.zero, radius * 0.68, rotorPaint);

    // Drilled Rotor Holes
    final holePaint = Paint()
      ..color = AppColors.cardBg
      ..style = PaintingStyle.fill;

    for (int h = 0; h < 8; h++) {
      double angle = (h / 8) * 2 * pi;
      double holeR = radius * 0.68;
      canvas.drawCircle(Offset(cos(angle) * holeR, sin(angle) * holeR), 1.2, holePaint);
    }

    // 5-Spoke Alloy Rim
    final rimPaint = Paint()
      ..color = AppColors.mods.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (int s = 0; s < 5; s++) {
      double angle = (s / 5) * 2 * pi;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * (radius - 3.5), sin(angle) * (radius - 3.5)),
        rimPaint,
      );
    }

    canvas.drawCircle(Offset.zero, 3.0, Paint()..color = Colors.white);
    canvas.restore();
  }

  void _drawBrakeLever(
    Canvas canvas, {
    required Offset pivot,
    required double pullAngle,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(pullAngle);

    final perchPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.fill;

    final leverPaint = Paint()
      ..color = AppColors.mods
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final dialPaint = Paint()
      ..color = AppColors.other
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 5.0, perchPaint);
    canvas.drawCircle(const Offset(4, -4), 2.5, dialPaint);

    final leverPath = Path();
    leverPath.moveTo(0, 0);
    leverPath.quadraticBezierTo(20, 2, 42, 12);
    canvas.drawPath(leverPath, leverPaint);

    canvas.drawCircle(const Offset(42, 12), 2.8, Paint()..color = Colors.white);
    canvas.restore();
  }

  void _drawExhaustMuffler(
    Canvas canvas, {
    required Offset outlet,
    required double animVal,
  }) {
    final canisterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF37474F),
          const Color(0xFF212121),
          const Color(0xFF101010),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(outlet.dx - 36, outlet.dy - 6, 36, 12));

    final canisterBorder = Paint()
      ..color = AppColors.mods.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final canisterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(outlet.dx - 36, outlet.dy - 6, 36, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(canisterRect, canisterPaint);
    canvas.drawRRect(canisterRect, canisterBorder);

    final tipPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.service,
          AppColors.mods,
          AppColors.other,
        ],
      ).createShader(Rect.fromLTWH(outlet.dx, outlet.dy - 5, 8, 10));

    canvas.drawRect(Rect.fromLTWH(outlet.dx, outlet.dy - 5, 8, 10), tipPaint);

    const int flameCount = 3;
    for (int f = 0; f < flameCount; f++) {
      double fProgress = ((animVal + (f / flameCount)) % 1.0);
      double fx = outlet.dx + 8 + (fProgress * 28);
      double fy = outlet.dy + sin(fProgress * pi) * 2;
      double fRadius = 2.0 + fProgress * 6.0;
      double fOpacity = sin(fProgress * pi) * 0.85;

      final flamePaint = Paint()
        ..color = (f % 2 == 0 ? AppColors.other : AppColors.fuel)
            .withValues(alpha: fOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(fx, fy), fRadius, flamePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ModificationsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
