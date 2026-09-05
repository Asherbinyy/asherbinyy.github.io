import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/core/platform/preference_store.dart';

import '../support/chrome_harness.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API, so these use the
// SDK comparator like the other goldens in this directory. See worklog 05.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      final suffix = '${mode.name}_$language';

      testWidgets('chrome with the rail in $suffix', (tester) async {
        await pumpChrome(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          themeMode: mode,
          locale: Locale(language),
        );

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile('goldens/chrome_railed_$suffix.png'),
        );
      });

      testWidgets('chrome with the rail collapsed in $suffix', (tester) async {
        await pumpChrome(
          tester,
          breakpoint: ChromeBreakpoint.compact,
          capabilities: touchBrowser,
          themeMode: mode,
          locale: Locale(language),
        );

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile('goldens/chrome_compact_$suffix.png'),
        );
      });
    }
  }

  testWidgets('chrome in Recruiter Mode has no rail', (tester) async {
    await pumpChrome(
      tester,
      breakpoint: ChromeBreakpoint.expanded,
      preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
    );

    await expectLater(
      find.byType(NocturneApp),
      matchesGoldenFile('goldens/chrome_recruiter_dark_en.png'),
    );
  });
}
