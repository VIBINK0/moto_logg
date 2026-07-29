import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';

class BikeCheckWrapper extends StatelessWidget {
  final Widget dashboard;
  const BikeCheckWrapper({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
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

        if (!provider.hasBikeSelected && user != null) {
          // Use postFrameCallback for navigation during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.bikeSelection);
          });
          return const Scaffold(backgroundColor: AppColors.bg);
        }

        return dashboard;
      },
    );
  }
}
