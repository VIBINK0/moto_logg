import 'package:go_router/go_router.dart';
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
  static final router = GoRouter(
    initialLocation: AppRoutes.root,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        name: 'root',
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.bikeSelection,
        name: 'bike-selection',
        builder: (context, state) => const BikeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'home',
        builder: (context, state) => const BikeCheckWrapper(
          dashboard: RootLayoutScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.bikeSettings,
        name: 'bike-settings',
        builder: (context, state) => const BikeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.mileageTracker,
        name: 'mileage-tracker',
        builder: (context, state) => const MileageTrackerScreen(),
      ),
    ],
  );
}
