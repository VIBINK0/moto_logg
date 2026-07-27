import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../screens/bike/bike_selection_screen.dart';

class BikeCheckWrapper extends StatefulWidget {
  final String userId;
  final Widget dashboard;
  const BikeCheckWrapper({
    super.key,
    required this.userId,
    required this.dashboard,
  });
  @override
  State<BikeCheckWrapper> createState() => _BikeCheckWrapperState();
}

class _BikeCheckWrapperState extends State<BikeCheckWrapper> {
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
