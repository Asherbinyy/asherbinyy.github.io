import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// Produces public destinations without form values, addresses, or queries.
String? analyticsDestination(Uri url) {
  if (url.scheme == 'mailto') return 'email';
  if (url.scheme == 'tel') return 'phone';
  if (!['http', 'https'].contains(url.scheme) || url.userInfo.isNotEmpty) {
    return null;
  }
  final id = url.host == 'play.google.com' ? url.queryParameters['id'] : null;
  return url
      .replace(
        query: id != null && RegExp(r'^[A-Za-z0-9_.]{1,160}$').hasMatch(id)
            ? 'id=${Uri.encodeQueryComponent(id)}'
            : '',
        fragment: '',
      )
      .toString()
      .replaceFirst(RegExp(r'[?#]+$'), '');
}

/// Records an action without allowing transport failure to affect the action.
void recordAnalytics(
  BuildContext context,
  AnalyticsEvent event, {
  String? target,
  String? destination,
}) {
  try {
    final client = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(analyticsClientProvider);
    if (client == null) return;
    final route =
        GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ??
        '/';
    if (route == '/console') return;
    unawaited(
      client
          .record(
            beacon(
              event: event,
              route: route,
              deviceClass: context.platform.inputMode.name,
              referrerHost: currentReferrerHost(),
              campaign: currentCampaign(),
              target: target,
              destination: destination,
            ),
          )
          .catchError((Object _) => false),
    );
  } on Object {
    // Links remain usable in isolated widgets and if analytics is unavailable.
  }
}

/// Opens the original URL; only the redacted destination goes to analytics.
Future<bool> launchTrackedUrl(BuildContext context, Uri url, {String? target}) {
  final destination = analyticsDestination(url);
  if (destination != null) {
    recordAnalytics(
      context,
      AnalyticsEvent.outboundClick,
      target: target ?? 'link:${url.host.isEmpty ? url.scheme : url.host}',
      destination: destination,
    );
  }
  return launchUrl(url, mode: LaunchMode.externalApplication);
}
