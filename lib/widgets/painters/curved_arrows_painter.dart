import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArrowData {
  final Offset from, to;
  final double curveDir;
  const ArrowData(this.from, this.to, {this.curveDir = 1});
}

class CurvedArrowsPainter extends CustomPainter {
  final List<ArrowData> arrows;
  const CurvedArrowsPainter({required this.arrows});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final a in arrows) {
      final from = a.from, to = a.to;
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final perp = Offset(
        -(to.dy - from.dy) * 0.25 * a.curveDir,
        (to.dx - from.dx) * 0.25 * a.curveDir,
      );
      final ctrl = mid + perp;

      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy),
        p,
      );

      final tangent = to - ctrl;
      final angle = math.atan2(tangent.dy, tangent.dx);
      const aLen = 9.0, aAng = 0.45;
      canvas.drawLine(
        to,
        Offset(
          to.dx - aLen * math.cos(angle - aAng),
          to.dy - aLen * math.sin(angle - aAng),
        ),
        p,
      );
      canvas.drawLine(
        to,
        Offset(
          to.dx - aLen * math.cos(angle + aAng),
          to.dy - aLen * math.sin(angle + aAng),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CurvedArrowsPainter old) => false;
}
