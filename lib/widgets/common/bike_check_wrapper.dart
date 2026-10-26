import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/bike_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../../screens/bike/legacy_bike_migration_screen.dart';

class BikeCheckWrapper extends ConsumerWidget {
  final Widget dashboard;
  const BikeCheckWrapper({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeState = ref.watch(bikeProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    // Wait until both bike state and expenses stream are initialized
    if (bikeState.isLoading || expensesAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textDim,
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return dashboard;
    }

    final expenses = expensesAsync.value ?? [];

    // 1. If user has previous data without bike name, show migration screen
    final hasLegacyExpenses = expenses.any(
      (e) => e.bikeName == null || e.bikeName!.trim().isEmpty,
    );

    if (hasLegacyExpenses) {
      return const LegacyBikeMigrationScreen();
    }

    // 2. Check the last data (most recent expense) and select the bike if none is currently selected
    if (!bikeState.hasBikeSelected && expenses.isNotEmpty) {
      final latestExpense = expenses.first;
      if (latestExpense.bikeName != null &&
          latestExpense.bikeName!.trim().isNotEmpty) {
        final bikeFromLastData =
            BikeModel.findByName(latestExpense.bikeName);
        if (bikeFromLastData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(bikeProvider.notifier).selectBike(bikeFromLastData);
          });
        }
      }
    } else if (expenses.isEmpty) {
      // 3. Brand new user with 0 expenses and no bike selected
      if (!bikeState.hasBikeSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoutes.bikeSelection);
        });
        return const Scaffold(backgroundColor: AppColors.bg);
      }
    }

    return dashboard;
  }
}
