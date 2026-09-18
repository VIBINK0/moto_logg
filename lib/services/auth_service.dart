import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../providers/bike_provider.dart';
import '../services/bike_storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign out and clear bike selection
  static Future<void> signOut(BuildContext context, [WidgetRef? ref]) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await BikeStorageService.clearSelectedBike(uid);
    }

    if (ref != null) {
      await ref.read(bikeProvider.notifier).clearOnLogout();
    }

    await _auth.signOut();

    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}
