import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/theme/nocturne_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/analytics/analytics_consent.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

Widget _harness(PreferenceStore store) => ProviderScope(
  overrides: [
    analyticsIsCollectingProvider.overrideWithValue(true),
    preferenceStoreProvider.overrideWithValue(store),
  ],
  child: MaterialApp(
    theme: NocturneTheme.create(viewportWidth: 320),
    darkTheme: NocturneTheme.create(viewportWidth: 320),
    themeMode: ThemeMode.dark,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: const PlatformScope(
      service: PlatformService(
        capabilities: PointerCapabilities(hasCoarsePointer: true),
        viewportWidth: 320,
      ),
      child: Scaffold(body: AnalyticsConsent()),
    ),
  ),
);

void main() {
  testWidgets('reject stores the decision and removes the first-visit choice', (
    tester,
  ) async {
    final store = InMemoryPreferenceStore();
    await tester.pumpWidget(_harness(store));

    expect(find.text('Allow analytics'), findsOneWidget);
    await tester.tap(find.text('Reject'));
    await tester.pump();

    expect(find.text('Allow analytics'), findsNothing);
    expect(
      store.read(PreferenceKey.consent.storageKey),
      ConsentTier.none.storageKey,
    );
  });

  testWidgets('allow stores a grant with no small-screen overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryPreferenceStore();
    await tester.pumpWidget(_harness(store));

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Allow analytics'));
    await tester.tap(find.text('Allow analytics'));
    await tester.pump();

    expect(
      store.read(PreferenceKey.consent.storageKey),
      ConsentTier.session.storageKey,
    );
    expect(tester.takeException(), isNull);
  });
}
