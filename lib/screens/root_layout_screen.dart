import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/sms_permission_helper.dart';
import '../providers/navigation_provider.dart';
import '../services/sms_transaction_service.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/sheets/add_expense_sheet.dart';
import 'home/home_screen.dart';
import 'expense/expense_list_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class RootLayoutScreen extends ConsumerWidget {
  const RootLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);

    // Listen to incoming SMS detected transactions
    ref.listen(smsTransactionProvider, (previous, next) {
      final tx = next.detectedTransaction;
      if (tx != null) {
        ref.read(smsTransactionProvider.notifier).clearTransaction();
        context.push(AppRoutes.expenseConfirm, extra: tx);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialTx = ref.read(smsTransactionProvider).detectedTransaction;
      if (initialTx != null) {
        ref.read(smsTransactionProvider.notifier).clearTransaction();
        context.push(AppRoutes.expenseConfirm, extra: initialTx);
      }

      // Proactively check and request SMS permissions if not yet granted
      final permStatus = await SmsPermissionHelper.checkPermissions();
      if (!permStatus.isFullyGranted) {
        await SmsPermissionHelper.requestPermissions();
      }
    });
    
    const pages = [
      HomeScreen(),
      ExpenseListScreen(),
      ReportsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
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
              ref.read(navigationProvider.notifier).updateIndex(index);
            },
            itemCount: pages.length,
            controller: navState.pageController,
            itemBuilder: (_, index) => pages[index],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(current: navState.currentIndex),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}
