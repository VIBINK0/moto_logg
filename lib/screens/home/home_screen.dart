import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/total_expense_card.dart';
import '../../widgets/home/bike_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return StreamBuilder<List<Expense>>(
      stream: provider.allExpenses,
      builder: (ctx, snap) {
        final all = snap.data ?? [];
        final filtered = provider.applyFilter(all);
        final totals = provider.totals(filtered);
        final grand = provider.grand(filtered);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(),
                    TotalExpenseCard(grand: grand),
                    const SizedBox(height: 16),
                    BikeSection(totals: totals),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
