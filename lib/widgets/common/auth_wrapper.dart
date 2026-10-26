import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';
import '../../providers/navigation_provider.dart';

import '../../services/onboarding_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFlow();
    });
  }

  Future<void> _checkFlow() async {
    final hasSeenFeatures = await OnboardingService.hasSeenFeatures();
    if (!mounted) return;

    if (!hasSeenFeatures) {
      context.go(AppRoutes.featureOverview);
      return;
    }

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        context.go(AppRoutes.login);
      } else {
        ref.read(navigationProvider.notifier).reset();
        ref.read(bikeProvider.notifier).initialize(user.uid);
        context.go(AppRoutes.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}
