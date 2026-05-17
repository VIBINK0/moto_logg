import 'dart:math';

import 'package:flutter/material.dart';

class FuelWavePainter extends CustomPainter {
  final double animationValue;
  final double level;

  FuelWavePainter({required this.animationValue, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    double baseHeight = size.height * (1 - level);
    double waveHeight = 12;

    // MAIN PETROL COLOR
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.orangeAccent.withOpacity(0.9),
          Colors.deepOrange.withOpacity(0.7),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      double y = waveHeight *
          sin((i / size.width * 2 * pi) +
              (animationValue * 2 * pi)) +
          baseHeight;

      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // SECOND WAVE (DEPTH)
    final paint2 = Paint()
      ..color = Colors.orange.withOpacity(0.3);

    final path2 = Path();
    path2.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      double y = waveHeight *
          cos((i / size.width * 2 * pi) +
              (animationValue * 2 * pi)) +
          baseHeight + 8;

      path2.lineTo(i, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);

    // SURFACE SHINE LINE
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final shinePath = Path();

    for (double i = 0; i <= size.width; i++) {
      double y = waveHeight *
          sin((i / size.width * 2 * pi) +
              (animationValue * 2 * pi)) +
          baseHeight;

      if (i == 0) {
        shinePath.moveTo(i, y);
      } else {
        shinePath.lineTo(i, y);
      }
    }

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}