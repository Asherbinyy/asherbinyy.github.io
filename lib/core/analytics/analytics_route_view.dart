import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// Records one aggregate route view when a routed page becomes active.
class AnalyticsRouteView extends ConsumerStatefulWidget {
  /// [route] is the URL path only, with query and fragment already discarded.
  const AnalyticsRouteView({
    required this.route,
    required this.child,
    super.key,
  });

  /// Current routed path.
  final String route;

  /// Page content, unaffected when analytics is disabled or unavailable.
  final Widget child;

  @override
  ConsumerState<AnalyticsRouteView> createState() => _AnalyticsRouteViewState();
}

class _AnalyticsRouteViewState extends ConsumerState<AnalyticsRouteView> {
  String? _recordedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recordedRoute == widget.route) return;
    _recordedRoute = widget.route;
    unawaited(_record());
  }

  @override
  void didUpdateWidget(AnalyticsRouteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_recordedRoute == widget.route) return;
    _recordedRoute = widget.route;
    unawaited(_record());
  }

  Future<void> _record() async {
    final client = ref.read(analyticsClientProvider);
    if (client == null || !mounted) return;
    final mode = context.platform.inputMode;
    try {
      await client.record((
        event: AnalyticsEvent.routeView,
        route: widget.route,
        deviceClass: mode.name,
        referrerHost: currentReferrerHost(),
        campaign: currentCampaign(),
      ));
    } on Exception {
      // Analytics availability must not change navigation or visible content.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
