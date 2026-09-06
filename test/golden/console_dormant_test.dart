@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/features/console/presentation/console_screen.dart';

import '../support/chrome_harness.dart';
import '../support/pump.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API. Keep the same
// screenshot coverage with the SDK comparator until the package is compatible.
//
// This covered a route whose body was still a reserved placeholder, so the
// chrome was the only thing on screen. Milestone 2 built the last of those, so
// there is no placeholder route left inside the chrome to photograph.
//
// It now covers the console route instead, which keeps exactly the same
// coverage this was for — both themes crossed with both directions, over a
// deliberately sparse body.
//
// This build collects nothing, so the route shows its dormant notice rather
// than the token gate. That is deliberately what gets photographed: a golden
// is worth most when it shows what a visitor actually sees.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      testWidgets('the console at rest in ${mode.name} $language', (
        tester,
      ) async {
        await pumpChrome(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          themeMode: mode,
          locale: Locale(language),
        );
        GoRouter.of(tester.element(find.byType(ChromeScaffold)))
            .goNamed(AppRoute.console.name);
        await pumpFrames(tester);
        // Re-acquire after navigating: the previous route's element is gone.
        final context = tester.element(find.byType(ChromeScaffold));

        expect(context.l10n.localeName, language);
        expect(
          Directionality.of(context),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.byType(ConsoleScreen), findsOneWidget);

        await expectLater(
          find.byType(NocturneApp),
          matchesGoldenFile(
            'goldens/console_dormant_${mode.name}_$language.png',
          ),
        );
      });
    }
  }
}
