import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Enhanced custom background painter for Fuel Card.
/// Matched with App Theme background palette and subtle amber ambient glow.
class FuelWavePainter extends CustomPainter {
  final double animationValue;
  final double level;

  FuelWavePainter({
    required this.animationValue,
    this.level = 0.58,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double baseHeight = size.height * (1 - level);
    const double waveHeight = 9.0;
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. UNIFORM APP CARD BACKGROUND
    final bgPaint = Paint()..color = AppColors.cardBg;
    canvas.drawRect(bgRect, bgPaint);

    // Subtle Fuel Amber Ambient Glow Shader
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 1.2,
        colors: [
          AppColors.fuel.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 2. FUEL GAUGE METER ARC (E to F)
    Offset gaugeCenter = Offset(size.width * 0.85, size.height * 0.42);
    double gaugeRadius = 26.0;

    final arcPaint = Paint()
      ..color = AppColors.fuel.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: gaugeRadius),
      0.8 * pi,
      1.4 * pi,
      false,
      arcPaint,
    );

    final redZonePaint = Paint()
      ..color = AppColors.other.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: gaugeRadius),
      0.8 * pi,
      0.3 * pi,
      false,
      redZonePaint,
    );

    final tickPaint = Paint()
      ..color = AppColors.fuel.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;

    for (int t = 0; t <= 6; t++) {
      double angle = (0.8 * pi) + (t / 6) * (1.4 * pi);
      double innerR = gaugeRadius - 3;
      double outerR = gaugeRadius + 3;
      canvas.drawLine(
        Offset(gaugeCenter.dx + cos(angle) * innerR, gaugeCenter.dy + sin(angle) * innerR),
        Offset(gaugeCenter.dx + cos(angle) * outerR, gaugeCenter.dy + sin(angle) * outerR),
        tickPaint,
      );
    }

    double needleFlex = sin(animationValue * 2 * pi);
    double needleAngle = (0.8 * pi) + (0.82 + needleFlex * 0.12) * (1.4 * pi);

    final needlePaint = Paint()
      ..color = AppColors.fuel
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final needleGlow = Paint()
      ..color = AppColors.fuel.withValues(alpha: 0.6)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    Offset needleTip = Offset(
      gaugeCenter.dx + cos(needleAngle) * (gaugeRadius - 2),
      gaugeCenter.dy + sin(needleAngle) * (gaugeRadius - 2),
    );

    canvas.drawLine(gaugeCenter, needleTip, needleGlow);
    canvas.drawLine(gaugeCenter, needleTip, needlePaint);
    canvas.drawCircle(gaugeCenter, 3.0, Paint()..color = Colors.white);

    // 3. FUEL DISPENSER NOZZLE
    Offset nozzlePos = Offset(size.width * 0.18, size.height * 0.22);
    _drawFuelNozzle(canvas, pos: nozzlePos);

    const int dropCount = 3;
    for (int d = 0; d < dropCount; d++) {
      double dropProgress = ((animationValue + (d / dropCount)) % 1.0);
      double dropX = nozzlePos.dx + 12 + (dropProgress * 4);
      double startY = nozzlePos.dy + 8;
      double endY = baseHeight + 5;
      double dropY = startY + dropProgress * (endY - startY);
      double dropAlpha = sin(dropProgress * pi) * 0.85;

      final dropPaint = Paint()
        ..color = AppColors.fuel.withValues(alpha: dropAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawCircle(Offset(dropX, dropY), 1.8, dropPaint);
    }

    // 4. SECOND PETROL WAVE LAYER
    final wave2Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: 0.5),
          const Color(0xFFE65100).withValues(alpha: 0.4),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i += 2) {
      double y = waveHeight *
              cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) +
          baseHeight + 5;
      path2.lineTo(i, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, wave2Paint);

    // 5. MAIN PETROL WAVE LAYER
    final mainWavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.fuel.withValues(alpha: 0.90),
          const Color(0xFFFF9100).withValues(alpha: 0.85),
          AppColors.other.withValues(alpha: 0.85),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i += 2) {
      double y = waveHeight *
              sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) +
          baseHeight;
      path1.lineTo(i, y);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, mainWavePaint);

    // 6. SURFACE SHINE CREST LINE
    final shinePaint = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final shinePath = Path();
    for (double i = 0; i <= size.width; i += 2) {
      double y = waveHeight *
              sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) +
          baseHeight;
      if (i == 0) {
        shinePath.moveTo(i, y);
      } else {
        shinePath.lineTo(i, y);
      }
    }
    canvas.drawPath(shinePath, shinePaint);

    // 7. RISING GAS BUBBLES
    const int bubbleCount = 6;
    for (int b = 0; b < bubbleCount; b++) {
      double bProgress = ((animationValue + (b / bubbleCount)) % 1.0);
      double bx = size.width * (0.12 + b * 0.15) + sin(bProgress * 2 * pi + b) * 5;
      double startY = size.height - 4;
      double endY = baseHeight - 6;
      double by = startY - bProgress * (startY - endY);
      double bAlpha = sin(bProgress * pi) * 0.7;

      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: bAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(bx, by), 1.4 + (b % 2) * 0.8, bubblePaint);
    }
  }

  void _drawFuelNozzle(Canvas canvas, {required Offset pos}) {
    final nozzlePaint = Paint()
      ..color = AppColors.fuel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(pos.dx - 10, pos.dy + 8);
    path.lineTo(pos.dx - 2, pos.dy - 2);
    path.lineTo(pos.dx + 8, pos.dy - 2);
    path.lineTo(pos.dx + 14, pos.dy + 6);

    canvas.drawPath(path, nozzlePaint);
    canvas.drawCircle(pos + const Offset(-2, -2), 3.0, Paint()..color = AppColors.other);
  }

  @override
  bool shouldRepaint(covariant FuelWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.level != level;
  }
}
