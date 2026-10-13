import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';

class CategoryCard extends StatefulWidget {
  final double left, top, w, h;
  final ExpenseCategory category;
  final double amount;

  const CategoryCard({
    super.key,
    required this.left,
    required this.top,
    required this.w,
    required this.h,
    required this.category,
    required this.amount,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _amountController;
  late Animation<double> _amountAnimation;
  double _lastAmount = 0.0;

  late AnimationController _ambientController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 1. Apple-style staggered entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Stagger start based on category index
    final delayMs = widget.category.index * 60;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _entranceController.forward();
      }
    });

    // 2. Smooth animated amount number counter
    _amountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _amountAnimation = Tween<double>(
      begin: 0.0,
      end: widget.amount,
    ).animate(
      CurvedAnimation(
        parent: _amountController,
        curve: Curves.easeOutQuart,
      ),
    );
    _lastAmount = widget.amount;
    Future.delayed(Duration(milliseconds: delayMs + 100), () {
      if (mounted) {
        _amountController.forward();
      }
    });

    // 3. Calm ambient background animation loop (smooth 4.5s cycle)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _amountAnimation = Tween<double>(
        begin: _lastAmount,
        end: widget.amount,
      ).animate(
        CurvedAnimation(
          parent: _amountController,
          curve: Curves.easeOutQuart,
        ),
      );
      _lastAmount = widget.amount;
      _amountController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _amountController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  CustomPainter _getBgPainter(double t) {
    switch (widget.category) {
      case ExpenseCategory.fuel:
        return _FuelBgPainter(t: t);
      case ExpenseCategory.service:
        return _ServiceBgPainter(t: t);
      case ExpenseCategory.modifications:
        return _ModificationsBgPainter(t: t);
      case ExpenseCategory.accessories:
        return _AccessoriesBgPainter(t: t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: Container(
                width: widget.w,
                height: widget.h,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF19191C),
                      Color(0xFF101012),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _isPressed ? 0.28 : 0.09,
                    ),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 1. Clean, neat Apple-style background animation
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _ambientController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _getBgPainter(_ambientController.value),
                          );
                        },
                      ),
                    ),

                    // 2. Subtle top specular bevel line
                    Positioned(
                      top: 0,
                      left: 14,
                      right: 14,
                      height: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Top-right category-specific micro-indicator
                    Positioned(
                      top: 10,
                      right: 12,
                      child: _buildCategoryMicroIndicator(),
                    ),

                    // 4. Foreground Card Content: Label & Count-up Amount
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.category.label.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          AnimatedBuilder(
                            animation: _amountAnimation,
                            builder: (context, child) {
                              return Text(
                                '₹${formatCurrency(_amountAnimation.value)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // 5. Subtle hairline bottom accent
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 0,
                      height: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Clean, neat Apple-style geometric micro-indicators in top-right
  Widget _buildCategoryMicroIndicator() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;

        switch (widget.category) {
          case ExpenseCategory.fuel:
            return _FuelMicroGauge(t: t);
          case ExpenseCategory.modifications:
            return _TelemetryMicroBars(t: t);
          case ExpenseCategory.accessories:
            return _ModularMicroNodes(t: t);
          case ExpenseCategory.service:
            return _PrecisionMicroOrbit(t: t);
        }
      },
    );
  }
}

// ============================================================================
// CLEAN APPLE MONOCHROME BACKGROUND PAINTERS
// ============================================================================

/// 1. FUEL BACKGROUND: Subtle precision fluid horizon & tank meter arc
class _FuelBgPainter extends CustomPainter {
  final double t;
  _FuelBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final baseH = size.height * 0.60;
    const waveAmp = 3.2;

    // Fluid under-wave gradient fill
    final wavePath = Path();
    wavePath.moveTo(0, size.height);
    wavePath.lineTo(0, baseH);
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseH + sin((x / size.width * 2 * pi) + (t * 2 * pi)) * waveAmp;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, baseH - waveAmp, size.width, size.height - baseH + waveAmp));
    canvas.drawPath(wavePath, fillPaint);

    // Primary crest hairline
    final crestPath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseH + sin((x / size.width * 2 * pi) + (t * 2 * pi)) * waveAmp;
      if (x == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(crestPath, crestPaint);

    // Secondary subtle ghost wave
    final ghostPath = Path();
    final ghostH = baseH + 4.0;
    for (double x = 0; x <= size.width; x += 4) {
      final y = ghostH + sin((x / size.width * 2 * pi) + (t * 2 * pi) + 1.6) * 2.0;
      if (x == 0) {
        ghostPath.moveTo(x, y);
      } else {
        ghostPath.lineTo(x, y);
      }
    }
    final ghostPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(ghostPath, ghostPaint);

    // Subtle fuel gauge meter arc at right
    final arcCenter = Offset(size.width * 0.88, size.height * 0.48);
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: 24),
      -0.6 * pi,
      0.9 * pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FuelBgPainter oldDelegate) => oldDelegate.t != t;
}

/// 2. SERVICE BACKGROUND: Precision chronograph calibration dial
class _ServiceBgPainter extends CustomPainter {
  final double t;
  _ServiceBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.84, size.height * 0.50);

    // Outer calibration dial
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 28, outerPaint);

    // Inner dial
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 18, innerPaint);

    // Concentric tick marks around dial
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final p1 = Offset(center.dx + 25 * cos(angle), center.dy + 25 * sin(angle));
      final p2 = Offset(center.dx + 28 * cos(angle), center.dy + 28 * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Rotating chronograph sweep arm
    final sweepAngle = t * 2 * pi;
    final sweepTip = Offset(
      center.dx + 26 * cos(sweepAngle),
      center.dy + 26 * sin(sweepAngle),
    );
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, sweepTip, sweepPaint);

    // Sweep indicator luminous dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sweepTip, 1.5, dotPaint);

    // Center pivot
    final pivotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, pivotPaint);

    // Secondary subtle counter-rotating ring in bottom-left
    final secondaryCenter = Offset(size.width * 0.18, size.height * 0.82);
    final secRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(secondaryCenter, 14, secRingPaint);
  }

  @override
  bool shouldRepaint(covariant _ServiceBgPainter oldDelegate) => oldDelegate.t != t;
}

/// 3. MODIFICATIONS BACKGROUND: High performance telemetry curve & CAD grid
class _ModificationsBgPainter extends CustomPainter {
  final double t;
  _ModificationsBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle CAD vertical grid ticks
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (double x = 25; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 15), Offset(x, size.height - 10), gridPaint);
    }

    // 2. High performance dyno powerband curve
    final dynoPath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final progress = x / size.width;
      final dynoY = size.height * (0.78 - 0.38 * sin(progress * pi * 0.85)) +
          sin(progress * 3.5 * pi + t * 2 * pi) * 2.8;
      if (x == 0) {
        dynoPath.moveTo(x, dynoY);
      } else {
        dynoPath.lineTo(x, dynoY);
      }
    }

    // Under-curve gradient fill
    final fillPath = Path.from(dynoPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.045),
          Colors.white.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Primary dyno hairline
    final dynoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(dynoPath, dynoPaint);

    // Secondary torque curve
    final torquePath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final progress = x / size.width;
      final torqueY = size.height * (0.84 - 0.24 * sin(progress * pi * 0.9)) +
          cos(progress * 3 * pi + t * 2 * pi) * 2.0;
      if (x == 0) {
        torquePath.moveTo(x, torqueY);
      } else {
        torquePath.lineTo(x, torqueY);
      }
    }
    final torquePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(torquePath, torquePaint);
  }

  @override
  bool shouldRepaint(covariant _ModificationsBgPainter oldDelegate) => oldDelegate.t != t;
}

/// 4. ACCESSORIES BACKGROUND: Floating geometric nodes & blueprint hairlines
class _AccessoriesBgPainter extends CustomPainter {
  final double t;
  _AccessoriesBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final diamondStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    // Node 1 (right mid)
    final yOffset1 = sin(t * 2 * pi) * 2.8;
    final c1 = Offset(size.width * 0.82, size.height * 0.42 + yOffset1);
    _drawDiamond(canvas, c1, 10.0, diamondStroke);
    canvas.drawCircle(c1, 1.5, dotPaint);

    // Node 2 (bottom right)
    final yOffset2 = cos(t * 2 * pi) * 2.2;
    final c2 = Offset(size.width * 0.65, size.height * 0.72 + yOffset2);
    _drawDiamond(canvas, c2, 7.5, diamondStroke);
    canvas.drawCircle(c2, 1.2, dotPaint);

    // Node 3 (top right faint)
    final c3 = Offset(size.width * 0.92, size.height * 0.78 - yOffset1);
    _drawDiamond(
      canvas,
      c3,
      6.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Connecting modular hairlines between nodes
    canvas.drawLine(c1, c2, linePaint);
    canvas.drawLine(c1, c3, linePaint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.8, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.8, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AccessoriesBgPainter oldDelegate) => oldDelegate.t != t;
}

// ============================================================================
// TOP-RIGHT MICRO-INDICATORS
// ============================================================================

/// 1. FUEL: Clean Apple Watch-style 4-segment gauge
class _FuelMicroGauge extends StatelessWidget {
  final double t;
  const _FuelMicroGauge({required this.t});

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(t * 2 * pi) + 1) / 2;
    return SizedBox(
      width: 26,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (i) {
          final isActive = i < 3;
          final isTip = i == 2;
          final alpha = isActive
              ? (isTip ? 0.40 + 0.35 * pulse : 0.65)
              : 0.15;

          return Container(
            width: 3.5,
            height: 7.0 + (i * 1.5),
            margin: const EdgeInsets.only(left: 2.2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

/// 2. MODIFICATIONS: Precision telemetry equalizer micro-bars
class _TelemetryMicroBars extends StatelessWidget {
  final double t;
  const _TelemetryMicroBars({required this.t});

  @override
  Widget build(BuildContext context) {
    final h1 = 5.0 + 3.5 * sin(t * 2 * pi);
    final h2 = 8.5 + 4.0 * cos(t * 2 * pi);
    final h3 = 6.0 + 3.0 * sin(t * 2 * pi + 1.2);

    return SizedBox(
      width: 22,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(h1, 0.45),
          const SizedBox(width: 2.5),
          _bar(h2, 0.75),
          const SizedBox(width: 2.5),
          _bar(h3, 0.55),
        ],
      ),
    );
  }

  Widget _bar(double h, double alpha) {
    return Container(
      width: 3.0,
      height: h.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

/// 3. ACCESSORIES: Modular geometric node constellation
class _ModularMicroNodes extends StatelessWidget {
  final double t;
  const _ModularMicroNodes({required this.t});

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(t * 2 * pi) + 1) / 2;
    return SizedBox(
      width: 16,
      height: 14,
      child: CustomPaint(
        painter: _ModularNodesPainter(pulse: pulse),
      ),
    );
  }
}

class _ModularNodesPainter extends CustomPainter {
  final double pulse;
  _ModularNodesPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final dotActive = Paint()
      ..color = Colors.white.withValues(alpha: 0.40 + 0.35 * pulse)
      ..style = PaintingStyle.fill;

    final dotSubtle = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final p1 = const Offset(3, 3);
    final p2 = Offset(size.width - 3, 3);
    final p3 = Offset(size.width - 3, size.height - 3);
    final p4 = Offset(3, size.height - 3);

    canvas.drawLine(p1, p3, linePaint);
    canvas.drawLine(p2, p4, linePaint);

    canvas.drawCircle(p1, 1.8, dotActive);
    canvas.drawCircle(p2, 1.5, dotSubtle);
    canvas.drawCircle(p3, 1.8, dotActive);
    canvas.drawCircle(p4, 1.5, dotSubtle);
  }

  @override
  bool shouldRepaint(covariant _ModularNodesPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// 4. SERVICE: Precision circular calibration ring & orbit
class _PrecisionMicroOrbit extends StatelessWidget {
  final double t;
  const _PrecisionMicroOrbit({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _PrecisionOrbitPainter(t: t),
      ),
    );
  }
}

class _PrecisionOrbitPainter extends CustomPainter {
  final double t;
  _PrecisionOrbitPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, trackPaint);

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.2, centerPaint);

    final angle = t * 2 * pi;
    final dotX = center.dx + r * cos(angle);
    final dotY = center.dy + r * sin(angle);
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 1.6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PrecisionOrbitPainter oldDelegate) =>
      oldDelegate.t != t;
}
