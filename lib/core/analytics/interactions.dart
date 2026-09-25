import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// The one way a widget records an interaction.
///
/// Every emission point on the site goes through here so the transport check,
/// failure swallow and device-class lookup live in one place.
///
/// It is deliberately fire-and-forget and never throws: `03-ARCHITECTURE.md`
/// says analytics availability must never change navigation or visible
/// content, so a dead endpoint is silence, not an error.
extension RecordInteraction on WidgetRef {
  /// Records [event] against [route], with an optional [value].
  ///
  /// Returns without doing anything when this build has no analytics endpoint.
  void recordInteraction(
    AnalyticsEvent event, {
    required String route,
    required InputMode inputMode,
    int? value,
    String? target,
    String? destination,
  }) {
    final client = read(analyticsClientProvider);
    if (client == null) return;

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
              target: target,
              destination: destination,
            ),
          )
          .catchError((Object _) => false),
    );
  }
}
