import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  const ExpenseTile({super.key, required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final completer = Completer<bool>();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            padding: const EdgeInsets.all(5),
            content: const Text(
              'Interesting choice. Want to rethink it? 👀',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Chaos Mode',
              onPressed: () {
                if (!completer.isCompleted) {
                  completer.complete(true);
                }
              },
            ),
          ),
        ).closed.then((_) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        });

        return completer.future;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.textDim,
          size: 20,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                expense.category.iconData,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty)
                    Text(
                      expense.notes!,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${formatCurrency(expense.amount)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${expense.date.day.toString().padLeft(2, '0')}/'
                  '${expense.date.month.toString().padLeft(2, '0')}/'
                  '${expense.date.year}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
