import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/route_title.dart';
import 'package:nocturne/core/analytics/analytics_route_view.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/engagement_reporter.dart';
import 'package:nocturne/core/platform/app_messenger_host.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';
import 'package:nocturne/features/console/presentation/console_screen.dart';
import 'package:nocturne/features/signal/presentation/signal_screen.dart';
import 'package:nocturne/features/about/presentation/about_screen.dart';
import 'package:nocturne/features/ascent/presentation/ascent_screen.dart';
import 'package:nocturne/features/station/presentation/station_screen.dart';
import 'package:nocturne/features/work/presentation/case_study_screen.dart';
import 'package:nocturne/features/work/presentation/work_screen.dart';
import 'package:nocturne/features/writing/presentation/writing_screen.dart';
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
          redirect: route == AppRoute.campaign
              ? (context, state) {
                  // The campaign slug is only worth capturing if something
                  // will report it, and capturing it writes to sessionStorage
                  // — which `/privacy` promises this build does not do. So the
                  // link keeps working and lands on the station either way,
                  // and nothing is written while collection is off.
                  if (ProviderScope.containerOf(
                    context,
                    listen: false,
                  ).read(analyticsIsCollectingProvider)) {
                    captureCampaign(state.pathParameters['campaign']);
                  }
                  return AppRoute.station.path;
                }
              : null,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: EngagementReporter(
              route: state.uri.path,
              child: AnalyticsRouteView(
                route: state.uri.path,
                child: RouteTitle(
                  route: route,
                  child: AppMessengerHost(
                    child: _sequenced(
                      route,
                      slug: state.pathParameters['slug'],
                    ),
                  ),
                ),
              ),
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
  static Widget _sequenced(AppRoute route, {String? slug}) {
    return route == AppRoute.station
        ? AcquisitionSequence(
            builder: (context, contentReveal, chromeReveal) => _framed(
              route,
              _body(route, acquisitionReveal: contentReveal),
              contentReveal: contentReveal,
              chromeReveal: chromeReveal,
            ),
          )
        : _framed(route, _body(route, slug: slug));
  }

  /// The screen for a route, or its reserved placeholder while one is pending.
  static Widget _body(
    AppRoute route, {
    Animation<double>? acquisitionReveal,
    String? slug,
  }) => switch (route) {
    AppRoute.station => StationScreen(acquisitionReveal: acquisitionReveal),
    AppRoute.signal => const SignalScreen(),
    AppRoute.work => const WorkScreen(),
    // A missing slug cannot happen for a matched `/work/:slug`, but the
    // screen's own "not written yet" state is the honest fallback anyway.
    AppRoute.caseStudy => CaseStudyScreen(slug: slug ?? ''),
    AppRoute.writing => const WritingScreen(),
    AppRoute.about => const AboutScreen(),
    AppRoute.ascent => const AscentScreen(),
    AppRoute.console => const ConsoleScreen(),
    _ => PlaceholderScreen(route: route),
  };

  /// Global chrome is present on every route except the two static ones.
  ///
  /// `/cv` and `/brief` are hand-written HTML served directly by Pages, so
  /// these Flutter routes only exist as reserved paths. Framing them would
  /// imply the app owns pages it does not.
  static Widget _framed(
    AppRoute route,
    Widget child, {
    Animation<double>? contentReveal,
    Animation<double>? chromeReveal,
  }) => route.hasGlobalChrome
      ? ChromeScaffold(
          route: route,
          contentReveal: contentReveal,
          chromeReveal: chromeReveal,
          // Section 6 runs the trace from the hero to the end of the career
          // sequence, both of which live on the station.
          backgroundBuilder: route == AppRoute.station
              ? (controller) => StationTrace(controller: controller)
              : null,
          child: child,
        )
      : Scaffold(body: child);
}
