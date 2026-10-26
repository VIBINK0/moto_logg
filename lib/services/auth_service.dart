import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../providers/bike_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/mileage_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/sms_transaction_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign out and clear session state
  static Future<void> signOut(BuildContext context, [WidgetRef? ref]) async {
    if (ref != null) {
      // 1. Reset navigation tab to Overview (index 0)
      ref.read(navigationProvider.notifier).reset();

      // 2. Reset expense filter
      ref.read(expenseFilterProvider.notifier).reset();

      // 3. Clear in-memory state of user-specific providers
      await ref.read(bikeProvider.notifier).clearOnLogout();
      ref.read(smsTransactionProvider.notifier).clearAll();

      // 4. Invalidate providers so they rebuild cleanly on next login
      ref.invalidate(bikeProvider);
      ref.invalidate(mileageProvider);
      ref.invalidate(expensesStreamProvider);
      ref.invalidate(expenseServiceProvider);
      ref.invalidate(authFormProvider);
      ref.invalidate(navigationProvider);
    }

    await _auth.signOut();

    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}
