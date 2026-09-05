import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/analytics_route_view.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

class _Sender {
  final sent = <AnalyticsBeacon>[];

  Future<void> call(AnalyticsBeacon beacon) async => sent.add(beacon);
}

void main() {
  testWidgets('records a route using resolved pointer capability', (
    tester,
  ) async {
    final sender = _Sender();
    final client = AnalyticsClient(sender.call);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(client)],
        child: const PlatformScope(
          service: PlatformService(
            capabilities: PointerCapabilities(
              canHover: true,
              hasFinePointer: true,
            ),
            viewportWidth: 1200,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AnalyticsRouteView(route: '/work', child: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(sender.sent, hasLength(1));
    expect(sender.sent.single.event, AnalyticsEvent.routeView);
    expect(sender.sent.single.route, '/work');
    expect(sender.sent.single.deviceClass, 'pointer');
    expect(sender.sent.single.referrerHost, isNull);
    expect(sender.sent.single.campaign, isNull);
  });

  testWidgets('an explicit rejection sends no route view', (tester) async {
    final sender = _Sender();
    final client = AnalyticsClient(sender.call, tier: ConsentTier.none);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(client)],
        child: const PlatformScope(
          service: PlatformService(
            capabilities: PointerCapabilities(hasCoarsePointer: true),
            viewportWidth: 400,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AnalyticsRouteView(route: '/', child: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(sender.sent, isEmpty);
  });

  testWidgets('an absent endpoint leaves the page unchanged', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlatformScope(
          service: PlatformService(
            capabilities: PointerCapabilities(),
            viewportWidth: 400,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AnalyticsRouteView(route: '/', child: Text('content')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
