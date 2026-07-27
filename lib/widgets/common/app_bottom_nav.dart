import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/expense_provider.dart';

class AppBottomNav extends StatelessWidget {
  final int current;
  const AppBottomNav({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.receipt_long_rounded, 'Expenses'),
      (Icons.bar_chart_rounded, 'Reports'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == current;
              return GestureDetector(
                onTap: () => context.read<ExpenseProvider>().setTab(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: active ? AppColors.textPrimary : AppColors.textDim,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: active ? AppColors.textPrimary : AppColors.textDim,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      active
                          ? Container(
                              width: 20,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            )
                          : const SizedBox(height: 2),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
