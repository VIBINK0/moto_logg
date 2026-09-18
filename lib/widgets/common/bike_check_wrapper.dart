import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';

class BikeCheckWrapper extends ConsumerWidget {
  final Widget dashboard;
  const BikeCheckWrapper({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeState = ref.watch(bikeProvider);

    if (bikeState.isLoading) {
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

    if (!bikeState.hasBikeSelected && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.bikeSelection);
      });
      return const Scaffold(backgroundColor: AppColors.bg);
    }

    return dashboard;
  }
}
