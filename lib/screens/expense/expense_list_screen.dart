import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/expense_tile.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesStreamProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Expenses',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.calendar),
                  icon: const Icon(Icons.calendar_month_rounded, size: 26),
                ),
              ],
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No expenses yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final grouped = <String, List<Expense>>{};
                for (final e in list) {
                  final k = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
                  grouped.putIfAbsent(k, () => []).add(e);
                }
                final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                
                const months = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                ];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final k = keys[i];
                    final items = grouped[k]!;
                    final total = items.fold<double>(0, (s, e) => s + e.amount);
                    final parts = k.split('-');
                    final label = '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '₹${formatCurrency(total)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...items.map(
                          (e) => ExpenseTile(
                            expense: e,
                            onDelete: () {
                              ref.read(expenseServiceProvider)?.delete(e.id);
                            },
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
