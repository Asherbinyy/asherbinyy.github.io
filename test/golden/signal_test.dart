@Tags(['golden'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/signal/presentation/widgets/propagation_map.dart';

import '../support/chrome_harness.dart';
import '../support/pump.dart';
import '../support/station_harness.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API; the SDK
// comparator is the recorded workaround. See worklog 05.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      testWidgets('the propagation map in ${mode.name}_$language', (
        tester,
      ) async {
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          themeMode: mode,
          locale: Locale(language),
          initialRoute: AppRoute.journey,
          reducedMotion: true,
        );

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile('goldens/signal_${mode.name}_$language.png'),
        );
      });
    }
  }

  testWidgets('a selected station opens its transmission', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.expanded,
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
      initialRoute: AppRoute.journey,
      reducedMotion: true,
    );

    await tester.tap(find.byType(PropagationMap));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFrames(tester);

    await expectLater(
      find.byType(NocturneApp),
      matchesGoldenFile('goldens/signal_selected_dark_en.png'),
    );
  });
}
