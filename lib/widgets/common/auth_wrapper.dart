import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/root_layout_screen.dart';
import 'bike_check_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still resolving auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        // Not logged in → show Login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }
        final user = snapshot.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BikeProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: BikeCheckWrapper(
            userId: user.uid,
            dashboard: const RootLayoutScreen(),
          ),
        );
      },
    );
  }
}
