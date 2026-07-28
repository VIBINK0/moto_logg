import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/expense_tile.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Expenses',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.calendar),
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: provider.allExpenses,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textDim,
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses yet.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  );
                }

                final grouped = <String, List<Expense>>{};
                for (final e in list) {
                  final k =
                      '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
                  grouped.putIfAbsent(k, () => []).add(e);
                }
                final keys = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));
                const months = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                ];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final k = keys[i];
                    final items = grouped[k]!;
                    final total = items.fold<double>(0, (s, e) => s + e.amount);
                    final parts = k.split('-');
                    final label =
                        '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '₹${formatCurrency(total)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.map(
                          (e) => ExpenseTile(
                            expense: e,
                            onDelete: () => provider.delete(e.id),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
