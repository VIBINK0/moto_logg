import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    // Use postFrameCallback to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user == null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        } else {
          // Initialize bike provider for the new user
          context.read<BikeProvider>().initialize(user.uid);
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      });
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
