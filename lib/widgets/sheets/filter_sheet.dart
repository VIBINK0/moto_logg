import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/expense_provider.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 2020 + 1,
      (i) => 2020 + i,
    ).reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter by',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ── Mode selector row ─────────────────────────
          Row(
            children: ['All Time', 'Month', 'Year'].map((mode) {
              final active = provider.filterMode == mode;
              return GestureDetector(
                onTap: () {
                  provider.setFilterMode(mode);
                  if (mode == 'All Time') Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.textPrimary : AppColors.iconBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: active ? AppColors.textPrimary : AppColors.border),
                  ),
                  child: Text(
                    mode,
                    style: TextStyle(
                      color: active ? Colors.black : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Month chips ───────────────────────────────
          if (provider.filterMode == 'Month') ...[
            const SizedBox(height: 20),
            const Text(
              'Month',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final m = i + 1;
                final sel = provider.selectedMonth == m;
                return GestureDetector(
                  onTap: () {
                    provider.setSelectedMonth(m);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.textPrimary : AppColors.iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.textPrimary : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _months[i],
                      style: TextStyle(
                        color: sel ? Colors.black : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Year sub-selector when in Month mode
            const Text(
              'Year',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: years.map((y) {
                final sel = provider.selectedYear == y;
                return GestureDetector(
                  onTap: () => provider.setSelectedYear(y),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.textPrimary : AppColors.iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.textPrimary : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color: sel ? Colors.black : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── Year chips ────────────────────────────────
          if (provider.filterMode == 'Year') ...[
            const SizedBox(height: 20),
            const Text(
              'Year',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: years.map((y) {
                final sel = provider.selectedYear == y;
                return GestureDetector(
                  onTap: () {
                    provider.setSelectedYear(y);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.textPrimary : AppColors.iconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.textPrimary : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color: sel ? Colors.black : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
