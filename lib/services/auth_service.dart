// Add this to your existing auth service

import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';
import '../core/routes/app_routes.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign out and clear bike selection
  static Future<void> signOut(BuildContext context) async {
    // Then sign out from Firebase first to stop listeners from triggering bike checks
    await _auth.signOut();

    // Clear bike selection
    if (context.mounted) {
      await context.read<BikeProvider>().clearOnLogout();
    }

    // Navigate to login and clear stack
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}
