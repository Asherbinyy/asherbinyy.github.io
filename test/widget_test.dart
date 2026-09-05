import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

void main() {
  testWidgets('every brief route resolves to its own empty placeholder', (
    tester,
  ) async {
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
      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('$mode renders an empty themed route in $locale', (
        tester,
      ) async {
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
        expect(find.byType(Text), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
