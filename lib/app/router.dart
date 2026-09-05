import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
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
            child: AppMessengerHost(
              child: _framed(route, PlaceholderScreen(route: route)),
            ),
          ),
        ),
    ],
    errorBuilder: (context, state) => AppMessengerHost(
      child: _framed(
        AppRoute.station,
        const PlaceholderScreen(route: AppRoute.station),
      ),
    ),
  );

  /// Global chrome is present on every route except the two static ones.
  ///
  /// `/cv` and `/brief` are hand-written HTML served directly by Pages, so
  /// these Flutter routes only exist as reserved paths. Framing them would
  /// imply the app owns pages it does not.
  static Widget _framed(AppRoute route, Widget child) => route.hasGlobalChrome
      ? ChromeScaffold(route: route, child: child)
      : Scaffold(body: child);
}
