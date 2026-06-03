// Add this to your existing auth service

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign out and clear bike selection
  static Future<void> signOut(BuildContext context) async {
    // Clear bike selection first
    await context.read<BikeProvider>().clearOnLogout();

    // Then sign out from Firebase
    await _auth.signOut();
  }
}
