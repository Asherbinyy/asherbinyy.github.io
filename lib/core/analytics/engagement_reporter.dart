import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// Reports how far down a route the viewer read, and how long they stayed.
///
/// Both are consented fields from `06-ANALYTICS-AND-PRIVACY.md` — "scroll
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
/// Nothing is captured at all until consent is granted: `recordInteraction`
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

class _EngagementReporterState extends ConsumerState<EngagementReporter>
    with WidgetsBindingObserver {
  /// Deepest quartile reached, 0 to 4.
  int _deepest = 0;

  /// When this route became visible.
  final Stopwatch _active = Stopwatch();
  bool _consented = false;
  bool _foreground = true;

  ValueNotifier<double>? _progress;
  InputMode? _inputMode;

  /// Cached because `ref` must not be used once dispose has begun, while a
  /// container reference stays valid. Reading the client *from* it at report
  /// time still respects a consent decision made moments earlier.
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(consentControllerProvider, (previous, next) {
      _consented = next.allowsSessionEvents;
      if (!_consented) {
        _active
          ..stop()
          ..reset();
        _deepest = 0;
      } else if (_foreground) {
        _active.start();
      }
    }, fireImmediately: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _consented) {
      _active.start();
    } else {
      _active.stop();
    }
  }

  @override
  void didUpdateWidget(EngagementReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route == widget.route) return;
    _report(oldWidget.route);
    _active
      ..stop()
      ..reset();
    _deepest = 0;
    if (_consented && _foreground) _active.start();
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
    if (!_consented || !_foreground) return;
    final progress = _progress?.value ?? 0;
    final quartile = (progress.clamp(0.0, 1.0) * 4).floor();
    if (quartile > _deepest) _deepest = quartile;
  }

  @override
  void dispose() {
    _progress?.removeListener(_onScroll);
    WidgetsBinding.instance.removeObserver(this);
    _active.stop();
    _report(widget.route);
    super.dispose();
  }

  /// Emits both measurements as the route goes away.
  void _report(String route) {
    final inputMode = _inputMode;
    if (!_consented || inputMode == null || route == '/console') return;

    // The container can already be gone: when the whole app is torn down it
    // disposes before its widgets do, and reading a disposed container throws.
    // A beacon on the way out is best-effort by nature, and analytics must
    // never surface — least of all as an exception during teardown.
    final AnalyticsClient? client;
    try {
      client = _container?.read(analyticsClientProvider);
    } on Object {
      return;
    }
    if (client == null) return;

    final seconds = _active.elapsed.inSeconds.clamp(0, 3600);
    // A glance is not a reading. Under two seconds says nothing worth storing,
    // and storing it anyway would make brief visits individually distinctive.
    if (seconds >= 2) {
      _send(client, AnalyticsEvent.sectionDwell, inputMode, seconds, route);
    }
    if (_deepest > 0) {
      _send(client, AnalyticsEvent.scrollDepth, inputMode, _deepest, route);
    }
  }

  /// Fire and forget: a page being disposed must not wait on a beacon, and a
  /// failed one must never surface.
  void _send(
    AnalyticsClient client,
    AnalyticsEvent event,
    InputMode inputMode,
    int value,
    String route,
  ) {
    unawaited(
      client
          .record(
            beacon(
              event: event,
              route: route,
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
