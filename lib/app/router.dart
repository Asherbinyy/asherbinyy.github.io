import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/core/platform/app_messenger_host.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

/// Owns route configuration without requiring the generator to analyze Flutter.
abstract final class AppRouter {
  /// The app state owns and disposes this framework navigation service.
  /// Message hosts live inside route focus scopes so Tab can reach them.
  static GoRouter create() => GoRouter(
    routes: [
      for (final route in AppRoute.values)
        GoRoute(
          path: route.path,
          name: route.name,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: AppMessengerHost(child: PlaceholderScreen(route: route)),
          ),
        ),
    ],
    errorBuilder: (context, state) => const AppMessengerHost(
      child: PlaceholderScreen(route: AppRoute.station),
    ),
  );
}
