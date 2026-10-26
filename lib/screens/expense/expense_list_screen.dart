import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/expense_tile.dart';
import '../../widgets/sheets/add_expense_sheet.dart';
import '../../widgets/sheets/edit_expense_sheet.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  void _openEditSheet(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditExpenseSheet(expense: expense),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final filteredExpenses = ref.watch(expensesForSelectedBikeProvider);
    final bikes = ref.watch(selectableBikesProvider);
    final bikeState = ref.watch(bikeProvider);
    final filter = ref.watch(expenseFilterProvider);

    final activeBikeName = filter.selectedBikeName ?? bikeState.selectedBike?.name;
    final isAllSelected = filter.selectedBikeName == 'All';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Expenses',
                      style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 2),
                    if (bikes.length > 1)
                      Text(
                        isAllSelected
                            ? 'Showing all machines'
                            : 'Showing ${activeBikeName ?? "selected machine"}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        activeBikeName ?? 'Your machine',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.calendar),
                  icon: const Icon(Icons.calendar_month_rounded, size: 26),
                ),
              ],
            ),
          ),

          // ── Horizontal Machine Selector Chips (Multi-bike only) ────────
          if (bikes.length > 1) ...[
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(expenseFilterProvider.notifier).setSelectedBikeName('All');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isAllSelected
                            ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                            : const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAllSelected
                              ? const Color(0xFF00FF88)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isAllSelected ? 1.4 : 0.8,
                        ),
                      ),
                      child: Text(
                        'All Bikes',
                        style: TextStyle(
                          color: isAllSelected ? Colors.white : Colors.white60,
                          fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  ...bikes.map((bike) {
                    final isSelected = !isAllSelected &&
                        activeBikeName?.toLowerCase() == bike.name.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(bikeProvider.notifier).selectBike(bike);
                        ref.read(expenseFilterProvider.notifier).setSelectedBikeName(bike.name);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                              : const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00FF88)
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00FF88),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Text(
                              bike.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (_) {
                if (filteredExpenses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.two_wheeler_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAllSelected
                                ? 'No expenses recorded yet.'
                                : 'No expenses for ${activeBikeName ?? "this machine"} yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log fuel, service, or modifications to start tracking.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _openAddSheet(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF88),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = <String, List<Expense>>{};
                for (final e in filteredExpenses) {
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
                        const SizedBox(height: 20),
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
                            onEdit: () => _openEditSheet(context, e),
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
