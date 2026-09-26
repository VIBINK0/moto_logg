import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Custom background painter for Service Card.
/// Matched with App Theme background palette and subtle cyan ambient glow.
class ServicePainter extends CustomPainter {
  final double animationValue;

  ServicePainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. UNIFORM APP CARD BACKGROUND
    final bgPaint = Paint()..color = AppColors.cardBg;
    canvas.drawRect(bgRect, bgPaint);

    // Subtle Service Ambient Glow Shader
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 1.2,
        colors: [
          AppColors.service.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 2. OIL SLICK EXPANDING RIPPLES AT BOTTOM
    const int rippleCount = 3;
    for (int i = 0; i < rippleCount; i++) {
      double progress = ((animationValue + (i / rippleCount)) % 1.0);
      double rx = 10.0 + progress * (size.width * 0.40);
      double ry = 3.0 + progress * 12.0;
      double opacity = sin(progress * pi) * 0.45;

      final ripplePaint = Paint()
        ..color = AppColors.service.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      Offset center = Offset(
        size.width * (0.28 + i * 0.22),
        size.height * 0.82 + sin(progress * pi) * 2,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        ripplePaint,
      );
    }

    // 3. ENGINE OIL DROPS (Vertical drip with smooth alpha fade)
    const int dropCount = 4;
    for (int d = 0; d < dropCount; d++) {
      double dropProgress = ((animationValue + (d / dropCount)) % 1.0);
      double startX = size.width * (0.18 + d * 0.22);
      double startY = -8.0;
      double endY = size.height * 0.82;
      double currentY = startY + dropProgress * (endY - startY);

      double dropOpacity = sin(dropProgress * pi) * 0.85;

      final oilDropPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: dropOpacity),
            AppColors.service.withValues(alpha: dropOpacity * 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(startX - 3, currentY - 6, 6, 12));

      _drawOilDrop(
        canvas,
        Offset(startX, currentY),
        size: 4.2 + (d % 2) * 0.8,
        paint: oilDropPaint,
      );
    }

    // 4. SPINNING MECHANICAL GEARS
    final gearStroke = Paint()
      ..color = AppColors.service.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final gearFill = Paint()
      ..color = AppColors.service.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Main gear (top-right, rotating clockwise)
    _drawGear(
      canvas,
      center: Offset(size.width * 0.85, size.height * 0.25),
      radius: 30.0,
      teeth: 12,
      toothDepth: 6.0,
      rotation: animationValue * 2 * pi * 1.0,
      strokePaint: gearStroke,
      fillPaint: gearFill,
    );

    // Secondary gear (bottom-left, rotating counter-clockwise)
    _drawGear(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.72),
      radius: 22.0,
      teeth: 10,
      toothDepth: 5.0,
      rotation: -animationValue * 2 * pi * 1.0,
      strokePaint: gearStroke,
      fillPaint: gearFill,
    );

    // Small planetary gear (top-center, rotating counter-clockwise)
    _drawGear(
      canvas,
      center: Offset(size.width * 0.58, size.height * 0.20),
      radius: 14.0,
      teeth: 8,
      toothDepth: 4.0,
      rotation: -animationValue * 2 * pi * 2.0,
      strokePaint: gearStroke,
      fillPaint: gearFill,
    );

    // 5. FLOATING & ROTATING NUTS AND BOLTS
    final nutStroke = Paint()
      ..color = AppColors.service.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final nutFill = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Hex Nut 1 (mid center)
    _drawHexNut(
      canvas,
      center: Offset(
        size.width * 0.42,
        size.height * 0.48 + sin(animationValue * 2 * pi) * 4,
      ),
      radius: 8.5,
      rotation: animationValue * 2 * pi * 1.0,
      strokePaint: nutStroke,
      fillPaint: nutFill,
    );

    // Hex Nut 2 (top left)
    _drawHexNut(
      canvas,
      center: Offset(
        size.width * 0.12,
        size.height * 0.22 + cos(animationValue * 2 * pi) * 3,
      ),
      radius: 6.5,
      rotation: -animationValue * 2 * pi * 1.0,
      strokePaint: nutStroke,
      fillPaint: nutFill,
    );

    // Bolt Head 1 (bottom right)
    _drawBoltHead(
      canvas,
      center: Offset(
        size.width * 0.72,
        size.height * 0.78 + sin(animationValue * 2 * pi + 1) * 3,
      ),
      radius: 7.0,
      rotation: animationValue * 2 * pi * 1.0,
      strokePaint: nutStroke,
    );

    // Bolt Head 2 (mid right)
    _drawBoltHead(
      canvas,
      center: Offset(
        size.width * 0.88,
        size.height * 0.52,
      ),
      radius: 5.5,
      rotation: -animationValue * 2 * pi * 1.0,
      strokePaint: nutStroke,
    );
  }

  void _drawOilDrop(Canvas canvas, Offset center, {required double size, required Paint paint}) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size * 1.5);
    path.cubicTo(
      center.dx + size, center.dy,
      center.dx + size, center.dy + size,
      center.dx, center.dy + size,
    );
    path.cubicTo(
      center.dx - size, center.dy + size,
      center.dx - size, center.dy,
      center.dx, center.dy - size * 1.5,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGear(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required int teeth,
    required double toothDepth,
    required double rotation,
    required Paint strokePaint,
    required Paint fillPaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final a1 = (i / teeth) * 2 * pi;
      final a2 = ((i + 0.35) / teeth) * 2 * pi;
      final a3 = ((i + 0.65) / teeth) * 2 * pi;
      final a4 = ((i + 1.0) / teeth) * 2 * pi;

      final rOut = radius + toothDepth;
      final rIn = radius;

      if (i == 0) path.moveTo(cos(a1) * rIn, sin(a1) * rIn);
      path.lineTo(cos(a1) * rOut, sin(a1) * rOut);
      path.lineTo(cos(a2) * rOut, sin(a2) * rOut);
      path.lineTo(cos(a3) * rIn, sin(a3) * rIn);
      path.lineTo(cos(a4) * rIn, sin(a4) * rIn);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    canvas.drawCircle(Offset.zero, radius * 0.4, strokePaint);
    for (int s = 0; s < 4; s++) {
      double angle = (s / 4) * pi;
      canvas.drawLine(
        Offset(cos(angle) * (radius * 0.4), sin(angle) * (radius * 0.4)),
        Offset(cos(angle) * (radius * 0.85), sin(angle) * (radius * 0.85)),
        strokePaint,
      );
    }

    canvas.restore();
  }

  void _drawHexNut(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required Paint strokePaint,
    required Paint fillPaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i / 6) * 2 * pi;
      double x = cos(angle) * radius;
      double y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.drawCircle(Offset.zero, radius * 0.5, strokePaint);

    canvas.restore();
  }

  void _drawBoltHead(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required Paint strokePaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    canvas.drawCircle(Offset.zero, radius, strokePaint);
    canvas.drawLine(Offset(-radius * 0.6, 0), Offset(radius * 0.6, 0), strokePaint);
    canvas.drawLine(Offset(0, -radius * 0.6), Offset(0, radius * 0.6), strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ServicePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
