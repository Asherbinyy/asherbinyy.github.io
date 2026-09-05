import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/route_title.dart';
import 'package:nocturne/core/platform/app_messenger_host.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';
import 'package:nocturne/features/signal/presentation/signal_screen.dart';
import 'package:nocturne/features/station/presentation/station_screen.dart';
import 'package:nocturne/features/station/presentation/widgets/acquisition_sequence.dart';
import 'package:nocturne/features/trace/presentation/station_trace.dart';

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
            child: RouteTitle(
              route: route,
              child: AppMessengerHost(child: _sequenced(route)),
            ),
          ),
        ),
    ],
    errorBuilder: (context, state) => RouteTitle(
      route: AppRoute.station,
      child: AppMessengerHost(child: _sequenced(AppRoute.station)),
    ),
  );

  /// The acquisition sequence wraps the whole frame on the station route.
  ///
  /// Its fourth beat draws the rail, header and footer in from their edges, so
  /// it has to sit above the chrome rather than inside the routed content.
  /// Every other route resolves straight to its settled state.
  static Widget _sequenced(AppRoute route) {
    final framed = _framed(route, _body(route));
    return route == AppRoute.station
        ? AcquisitionSequence(child: framed)
        : framed;
  }

  /// The screen for a route, or its reserved placeholder while one is pending.
  static Widget _body(AppRoute route) => switch (route) {
    AppRoute.station => const StationScreen(),
    AppRoute.signal => const SignalScreen(),
    _ => PlaceholderScreen(route: route),
  };

  /// Global chrome is present on every route except the two static ones.
  ///
  /// `/cv` and `/brief` are hand-written HTML served directly by Pages, so
  /// these Flutter routes only exist as reserved paths. Framing them would
  /// imply the app owns pages it does not.
  static Widget _framed(AppRoute route, Widget child) => route.hasGlobalChrome
      ? ChromeScaffold(
          route: route,
          // Section 6 runs the trace from the hero to the end of the career
          // sequence, both of which live on the station.
          backgroundBuilder: route == AppRoute.station
              ? (controller) => StationTrace(controller: controller)
              : null,
          child: child,
        )
      : Scaffold(body: child);
}
