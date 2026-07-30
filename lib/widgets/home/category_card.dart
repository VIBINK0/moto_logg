import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';

class CategoryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: w,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${formatCurrency(amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ).animate(key: ValueKey(amount))
       .fadeIn(duration: 400.ms)
       .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}
