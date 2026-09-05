@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

import '../support/chrome_harness.dart';
import '../support/pump.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API. Keep the same
// screenshot coverage with the SDK comparator until the package is compatible.
//
// This covers a route whose body is still a reserved placeholder, so the
// chrome is the only thing on screen. The hero has its own goldens, and the
// chrome's breakpoint states have theirs.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      testWidgets('empty ${mode.name} placeholder in $language', (
        tester,
      ) async {
        await pumpChrome(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          themeMode: mode,
          locale: Locale(language),
        );
        GoRouter.of(tester.element(find.byType(ChromeScaffold)))
            .goNamed(AppRoute.about.name);
        await pumpFrames(tester);
        // Re-acquire after navigating: the previous route's element is gone.
        final context = tester.element(find.byType(ChromeScaffold));

        expect(context.l10n.localeName, language);
        expect(
          Directionality.of(context),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.byType(PlaceholderScreen), findsOneWidget);

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile('goldens/placeholder_${mode.name}_$language.png'),
        );
      });
    }
  }
}
