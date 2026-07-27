import 'dart:math' as math;
import 'package:flutter/material.dart';

class FallbackBikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF606060)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final w = size.width, h = size.height;

    void wheel(Offset c) {
      final r = w * 0.14;
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c, r * 0.55, p..strokeWidth = 1);
      canvas.drawCircle(c, r * 0.12, p);
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          c + Offset(math.cos(a) * r * 0.12, math.sin(a) * r * 0.12),
          c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55),
          p..strokeWidth = 0.8,
        );
      }
      p.strokeWidth = 2;
    }

    wheel(Offset(w * 0.23, h * 0.76));
    wheel(Offset(w * 0.77, h * 0.76));

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h * 0.60)
        ..lineTo(w * 0.40, h * 0.32)
        ..lineTo(w * 0.60, h * 0.36)
        ..lineTo(w * 0.65, h * 0.60)
        ..lineTo(w * 0.23, h * 0.60)
        ..moveTo(w * 0.40, h * 0.32)
        ..lineTo(w * 0.52, h * 0.24)
        ..lineTo(w * 0.60, h * 0.36)
        ..moveTo(w * 0.60, h * 0.36)
        ..lineTo(w * 0.77, h * 0.60),
      p,
    );

    final tank = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..quadraticBezierTo(w * 0.44, h * 0.18, w * 0.58, h * 0.22)
      ..lineTo(w * 0.60, h * 0.36)
      ..lineTo(w * 0.40, h * 0.36)
      ..close();
    canvas.drawPath(tank, fill);
    canvas.drawPath(tank, p);

    final seat = Path()
      ..moveTo(w * 0.26, h * 0.34)
      ..quadraticBezierTo(w * 0.32, h * 0.25, w * 0.42, h * 0.28)
      ..lineTo(w * 0.40, h * 0.36)
      ..quadraticBezierTo(w * 0.30, h * 0.38, w * 0.24, h * 0.42)
      ..close();
    canvas.drawPath(seat, fill);
    canvas.drawPath(seat, p);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.50, w * 0.20, h * 0.12),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.50, w * 0.20, h * 0.12),
        const Radius.circular(3),
      ),
      p,
    );
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(w * 0.40, h * 0.50 + i * h * 0.04),
        Offset(w * 0.60, h * 0.50 + i * h * 0.04),
        p..strokeWidth = 0.8,
      );
    }
    p.strokeWidth = 2;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.40, h * 0.59)
        ..quadraticBezierTo(w * 0.30, h * 0.65, w * 0.16, h * 0.60),
      p..strokeWidth = 2.5,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.82, h * 0.34),
        width: 18,
        height: 14,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.82, h * 0.34),
        width: 18,
        height: 14,
      ),
      p..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
