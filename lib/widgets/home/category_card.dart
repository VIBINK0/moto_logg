import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../painters/accessories_painter.dart';
import '../painters/fuel_wave_painter.dart';
import '../painters/modifications_painter.dart';
import '../painters/service_painter.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CustomPainter _getPainter(double animValue) {
    switch (widget.category) {
      case ExpenseCategory.fuel:
        return FuelWavePainter(
          animationValue: animValue,
          level: 0.58,
        );
      case ExpenseCategory.modifications:
        return ModificationsPainter(
          animationValue: animValue,
        );
      case ExpenseCategory.accessories:
        return AccessoriesPainter(
          animationValue: animValue,
        );
      case ExpenseCategory.service:
        return ServicePainter(
          animationValue: animValue,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: widget.w,
          height: widget.h,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],

          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.w, widget.h),
                    painter: _getPainter(_controller.value),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.category.label,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${formatCurrency(widget.amount)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
