import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// Reports how far down a route the viewer read, and how long they stayed.
///
/// Both are Tier 1 fields from `06-ANALYTICS-AND-PRIVACY.md` §4 — "scroll
/// depth" and "time per section", where a section on this site is a route.
///
/// Both are reported **once, on leaving**, not continuously:
///
/// - A stream of scroll offsets would describe the viewer's reading motion
///   frame by frame, which is much closer to the session replay §2 bans
///   outright than to a depth metric. A single quartile answers the question
///   that matters — did they reach the work — and answers nothing else.
/// - Dwell is whole seconds. Millisecond precision on a page visit is a
///   sharper number than the question deserves and a more distinguishing one
///   than a viewer should have to carry.
///
/// Nothing is captured at all until consent reaches Tier 1: `recordInteraction`
/// resolves the client, and the client is a hard no-op below that tier.
class EngagementReporter extends ConsumerStatefulWidget {
  /// [route] is the path this reporter is measuring.
  const EngagementReporter({
    required this.route,
    required this.child,
    super.key,
  });

  /// The route being measured.
  final String route;

  /// Page content, unaffected by whether anything is recorded.
  final Widget child;

  @override
  ConsumerState<EngagementReporter> createState() => _EngagementReporterState();
}

class _EngagementReporterState extends ConsumerState<EngagementReporter> {
  /// Deepest quartile reached, 0 to 4.
  int _deepest = 0;

  /// When this route became visible.
  DateTime? _arrived;

  ValueNotifier<double>? _progress;
  InputMode? _inputMode;

  /// Cached because `ref` must not be used once dispose has begun, while a
  /// container reference stays valid. Reading the client *from* it at report
  /// time still respects a consent decision made moments earlier.
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _arrived = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cached because dispose() cannot read an InheritedWidget: by then this
    // element is being unmounted and the lookup throws.
    _inputMode = context.platform.inputMode;
    _container = ProviderScope.containerOf(context, listen: false);

    final scope = ChromeScrollScope.maybeOf(context);
    if (scope?.progress == _progress) return;
    _progress?.removeListener(_onScroll);
    _progress = scope?.progress;
    _progress?.addListener(_onScroll);
  }

  void _onScroll() {
    final progress = _progress?.value ?? 0;
    final quartile = (progress.clamp(0.0, 1.0) * 4).round();
    if (quartile > _deepest) _deepest = quartile;
  }

  @override
  void dispose() {
    _progress?.removeListener(_onScroll);
    _report();
    super.dispose();
  }

  /// Emits both measurements as the route goes away.
  void _report() {
    final arrived = _arrived;
    final inputMode = _inputMode;
    final client = _container?.read(analyticsClientProvider);
    if (arrived == null || inputMode == null || client == null) return;

    final seconds = DateTime.now().difference(arrived).inSeconds;
    // A glance is not a reading. Under two seconds says nothing worth storing,
    // and storing it anyway would make brief visits individually distinctive.
    if (seconds >= 2) {
      _send(client, AnalyticsEvent.sectionDwell, inputMode, seconds);
    }
    if (_deepest > 0) {
      _send(client, AnalyticsEvent.scrollDepth, inputMode, _deepest);
    }
  }

  /// Fire and forget: a page being disposed must not wait on a beacon, and a
  /// failed one must never surface.
  void _send(
    AnalyticsClient client,
    AnalyticsEvent event,
    InputMode inputMode,
    int value,
  ) {
    unawaited(
      client
          .record(
            beacon(
              event: event,
              route: widget.route,
              deviceClass: inputMode.name,
              referrerHost: currentReferrerHost(),
              campaign: currentCampaign(),
              value: value,
            ),
          )
          .catchError((Object _) => false),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
