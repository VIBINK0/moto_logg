import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/expense_provider.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/sheets/add_expense_sheet.dart';
import 'home/home_screen.dart';
import 'expense/expense_list_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class RootLayoutScreen extends StatelessWidget {
  const RootLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    const pages = [
      HomeScreen(),
      ExpenseListScreen(),
      ReportsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PageView.builder(
            scrollBehavior: const ScrollBehavior().copyWith(
              scrollbars: false,
              dragDevices: {
                PointerDeviceKind.trackpad,
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
              },
            ),
            onPageChanged: (index) {
              context.read<ExpenseProvider>().updateTabIndex(index);
            },
            itemCount: pages.length,
            controller: provider.pageController,
            itemBuilder: (_, index) {
              return pages[index];
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(current: provider.tabIndex),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExpenseProvider>(),
        child: const AddExpenseSheet(),
      ),
    );
  }
}
