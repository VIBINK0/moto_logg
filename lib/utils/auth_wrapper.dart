// lib/utils/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/bike_provider.dart';
import '../screens/bike_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget dashboard;
  final Widget loginScreen;

  const AuthWrapper({
    super.key,
    required this.dashboard,
    required this.loginScreen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return loginScreen;
        }

        // Logged in - check bike selection
        final user = snapshot.data!;
        return _BikeCheckWrapper(
          userId: user.uid,
          dashboard: dashboard,
        );
      },
    );
  }
}

class _BikeCheckWrapper extends StatefulWidget {
  final String userId;
  final Widget dashboard;

  const _BikeCheckWrapper({
    required this.userId,
    required this.dashboard,
  });

  @override
  State<_BikeCheckWrapper> createState() => _BikeCheckWrapperState();
}

class _BikeCheckWrapperState extends State<_BikeCheckWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize bike provider with user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BikeProvider>().initialize(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        // Loading bike data
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // No bike selected - show selection screen
        if (!provider.hasBikeSelected) {
          return const BikeSelectionScreen();
        }

        // Bike selected - show dashboard
        return widget.dashboard;
      },
    );
  }
}
