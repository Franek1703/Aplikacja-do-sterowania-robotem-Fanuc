
import 'package:go_router/go_router.dart';
import '../../views/auth/login_view.dart';
import '../../views/devices/devices_list_view.dart';
import '../../views/robots/robots_list_view.dart';
import '../../views/dashboard/dashboard_view.dart';
import '../../views/settings/settings_view.dart';

/// App router configuration using go_router
class AppRouter {
  static GoRouter createRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/devices',
          name: 'devices',
          builder: (context, state) => const DevicesListView(),
        ),
        GoRoute(
          path: '/robots',
          name: 'robots',
          builder: (context, state) {
            final deviceId = state.uri.queryParameters['deviceId'] ?? '';
            return RobotsListView(deviceId: deviceId);
          },
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) {
            final robotId = state.uri.queryParameters['robotId'] ?? '';
            final deviceId = state.uri.queryParameters['deviceId'] ?? '';
            return DashboardView(robotId: robotId, deviceId: deviceId);
          },
        ),
        GoRoute(
          path: '/account',
          name: 'account',
          builder: (context, state) => const SettingsView(),
        ),
      ],
    );
  }
}
