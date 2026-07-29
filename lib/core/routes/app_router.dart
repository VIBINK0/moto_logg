import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/bike/bike_selection_screen.dart';
import '../../screens/bike/bike_settings_screen.dart';
import '../../screens/expense/calendar_screen.dart';
import '../../screens/mileage/mileage_tracker_screen.dart';
import '../../screens/root_layout_screen.dart';
import '../../widgets/common/auth_wrapper.dart';
import '../../widgets/common/bike_check_wrapper.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.bikeSelection:
        return MaterialPageRoute(
          builder: (_) => const BikeSelectionScreen(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const BikeCheckWrapper(
            dashboard: RootLayoutScreen(),
          ),
        );

      case AppRoutes.bikeSettings:
        return MaterialPageRoute(
          builder: (_) => const BikeSettingsScreen(),
        );

      case AppRoutes.calendar:
        return MaterialPageRoute(
          builder: (_) => const CalendarScreen(),
        );

      case AppRoutes.mileageTracker:
        return MaterialPageRoute(
          builder: (_) => const MileageTrackerScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
