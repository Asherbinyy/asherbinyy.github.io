import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// The one way a widget records a Tier 1 interaction.
///
/// Every emission point on the site goes through here so the consent check,
/// the failure swallow and the device-class lookup live in one place rather
/// than being re-implemented — slightly differently — at each call site.
///
/// It is deliberately fire-and-forget and never throws: `03-ARCHITECTURE.md`
/// says analytics availability must never change navigation or visible
/// content, so a dead endpoint is silence, not an error.
extension RecordInteraction on WidgetRef {
  /// Records [event] against [route], with an optional [value].
  ///
  /// Returns without doing anything when consent has not reached Tier 1,
  /// because `AnalyticsClient` is a hard no-op there — not a queue.
  void recordInteraction(
    AnalyticsEvent event, {
    required String route,
    required InputMode inputMode,
    int? value,
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
            ),
          )
          .catchError((Object _) => false),
    );
  }
}
