import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/sms_permission_helper.dart';
import '../models/detected_transaction_model.dart';
import '../providers/navigation_provider.dart';
import '../services/sms_transaction_service.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/sheets/add_expense_sheet.dart';
import 'home/home_screen.dart';
import 'expense/expense_list_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class RootLayoutScreen extends ConsumerStatefulWidget {
  const RootLayoutScreen({super.key});

  @override
  ConsumerState<RootLayoutScreen> createState() => _RootLayoutScreenState();
}

class _RootLayoutScreenState extends ConsumerState<RootLayoutScreen>
    with WidgetsBindingObserver {
  bool _isNavigatingToConfirm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkPermissionsAndCatchup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Catch up any SMS transactions received while app was closed / in background
      ref.read(smsTransactionProvider.notifier).syncMissedTransactions();
    }
  }

  Future<void> _checkPermissionsAndCatchup() async {
    final permStatus = await SmsPermissionHelper.checkPermissions();
    if (!permStatus.isFullyGranted) {
      await SmsPermissionHelper.requestPermissions();
    }
    if (mounted) {
      await ref.read(smsTransactionProvider.notifier).syncMissedTransactions();
    }
  }

  Future<void> _navigateToConfirm(DetectedTransaction tx) async {
    if (_isNavigatingToConfirm) return;
    _isNavigatingToConfirm = true;
    try {
      await context.push(AppRoutes.expenseConfirm, extra: tx);
    } finally {
      _isNavigatingToConfirm = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);

    // Listen to incoming SMS detected transactions
    ref.listen(smsTransactionProvider, (previous, next) {
      final tx = next.detectedTransaction;
      if (tx != null && previous?.detectedTransaction != tx) {
        _navigateToConfirm(tx);
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
      bottomNavigationBar: AppBottomNav(
        current: navState.currentIndex,
        onAdd: () => _showAddSheet(context),
      ),
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
