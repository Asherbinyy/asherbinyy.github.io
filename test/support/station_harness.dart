import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/core/platform/platform_provider.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/features/station/domain/acquisition_controller.dart';

import 'chrome_harness.dart';
import 'content_readers.dart';
import 'pump.dart';

/// Pumps the app at the station route with content and preferences installed.
Future<ProviderContainer> pumpStation(
  WidgetTester tester, {
  required ChromeBreakpoint breakpoint,
  AssetReader? reader,
  bool hasPlayedSequence = true,
  bool settle = true,
  bool reducedMotion = false,
  PointerCapabilities capabilities = pointerBrowser,
  ThemeMode? themeMode,
  Locale? locale,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(breakpoint.width, breakpoint.height);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      assetReaderProvider.overrideWithValue(reader ?? bundledContent()),
      preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore()),
      platformCapabilitiesProvider.overrideWith(
        () => FixedCapabilities(capabilities),
      ),
    ],
  );
  addTearDown(container.dispose);

  if (hasPlayedSequence) {
    container.read(acquisitionPlayedProvider.notifier).markPlayed();
  }

  // Content loading is real asynchronous I/O, which the test clock does not
  // advance. Warming the providers here means the first build sees resolved
  // content instead of a skeleton whose sweep would never settle.
  await tester.runAsync(() async {
    await container.read(profileProvider.future);
    await container.read(careerProvider.future);
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(breakpoint.width, breakpoint.height),
          disableAnimations: reducedMotion,
        ),
        child: NocturneApp(themeMode: themeMode, locale: locale),
      ),
    ),
  );
  if (settle) {
    await pumpFrames(tester);
  } else {
    await tester.pump();
  }
  return container;
}
