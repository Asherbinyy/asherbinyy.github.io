import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

void main() {
  testWidgets('every route resolves to its own placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PlaceholderScreen));
    final router = GoRouter.of(context);

    for (final route in AppRoute.values) {
      router.go(
        route.path
            .replaceAll(':slug', 'fixture')
            .replaceAll(':campaign', 'fixture'),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<PlaceholderScreen>(find.byType(PlaceholderScreen)).route,
        route,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('global chrome frames every route except the static two', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(PlaceholderScreen)));

    for (final route in AppRoute.values) {
      router.go(
        route.path
            .replaceAll(':slug', 'fixture')
            .replaceAll(':campaign', 'fixture'),
      );
      await tester.pumpAndSettle();

      final expected = route.hasGlobalChrome ? findsOneWidget : findsNothing;
      expect(find.byType(ChromeScaffold), expected, reason: route.name);
      expect(find.byType(AppHeader), expected, reason: route.name);
      expect(find.byType(AppFooter), expected, reason: route.name);
    }
  });

  test('the static routes are the only unframed ones', () {
    final unframed = AppRoute.values
        .where((route) => !route.hasGlobalChrome)
        .toSet();

    expect(unframed, {AppRoute.cv, AppRoute.brief});
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('$mode renders a themed route in $locale', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: NocturneApp(themeMode: mode, locale: locale),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(PlaceholderScreen));
        final expected = mode == ThemeMode.dark
            ? nocturneTokens
            : daybreakTokens;

        expect(context.tokens, expected);
        expect(Theme.of(context).scaffoldBackgroundColor, expected.void_);
        expect(
          Directionality.of(context),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        // The placeholder body itself still carries no invented copy; the only
        // text on screen belongs to the chrome.
        expect(
          find.descendant(
            of: find.byType(PlaceholderScreen),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
