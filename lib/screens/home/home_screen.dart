import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/total_expense_card.dart';
import '../../widgets/home/bike_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (allExpenses) {
            final totals = ref.watch(expenseTotalsProvider);
            final grandTotal = ref.watch(grandTotalProvider);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 24),
                  TotalExpenseCard(grand: grandTotal),
                  const SizedBox(height: 8),
                  BikeSection(totals: totals)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.05),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
