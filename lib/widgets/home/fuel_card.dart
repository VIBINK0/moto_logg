import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import 'category_card.dart';

class FuelCard extends StatelessWidget {
  final double left, top, w, h;
  final ExpenseCategory category;
  final double amount;

  const FuelCard({
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
    return CategoryCard(
      left: left,
      top: top,
      w: w,
      h: h,
      category: category,
      amount: amount,
    );
  }
}
