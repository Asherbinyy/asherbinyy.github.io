import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app.dart';

import '../support/chrome_harness.dart';
import '../support/content_readers.dart';
import '../support/station_harness.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API; the SDK
// comparator is the recorded workaround. See worklog 05.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      final suffix = '${mode.name}_$language';

      testWidgets('the settled hero in $suffix', (tester) async {
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          themeMode: mode,
          locale: Locale(language),
        );

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile('goldens/hero_$suffix.png'),
        );
      });
    }
  }

  testWidgets('the hero with the stat panels the content can declare', (
    tester,
  ) async {
    // profile.json carries no stats yet, so this fixture stands in to keep the
    // panels' composition under a golden until the owner supplies the numbers.
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.expanded,
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
      reader: bundledContent(
        overrides: {
          'assets/content/profile.json': asAsset({
            'name': {'en': 'Ahmed Elsherbini'},
            'positioning': {
              'en':
                  'Mobile engineer. 25+ applications shipped across six '
                  'countries.',
            },
            'contact': {'email': 'fixture@example.com'},
            'stats': [
              {
                'value': '25+',
                'label': {'en': 'shipped'},
              },
              {
                'value': '6',
                'label': {'en': 'countries'},
              },
              {
                'value': '4',
                'label': {'en': 'years'},
              },
            ],
          }),
        },
      ),
    );

    await expectLater(
      find.byType(NocturneApp),
      matchesGoldenFile('goldens/hero_stats_dark_en.png'),
    );
  });

  testWidgets('the hero when content and its fallback both fail', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.expanded,
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
      reader: corruptContent,
    );

    await expectLater(
      find.byType(NocturneApp),
      matchesGoldenFile('goldens/hero_unavailable_dark_en.png'),
    );
  });
}
