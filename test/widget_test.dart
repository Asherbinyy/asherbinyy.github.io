import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/features/console/presentation/console_screen.dart';
import 'package:nocturne/features/about/presentation/about_screen.dart';
import 'package:nocturne/features/courtyard/presentation/courtyard_screen.dart';
import 'package:nocturne/features/signal/presentation/signal_screen.dart';
import 'package:nocturne/features/station/presentation/station_screen.dart';
import 'package:nocturne/features/work/presentation/case_study_screen.dart';
import 'package:nocturne/features/work/presentation/work_screen.dart';
import 'package:nocturne/features/writing/presentation/writing_screen.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

import 'support/pump.dart';

void main() {
  testWidgets('every route resolves to its own screen', (tester) async {
    // Routes that have a real screen; the rest are still reserved placeholders.
    final built = <AppRoute, Type>{
      AppRoute.home: StationScreen,
      AppRoute.journey: SignalScreen,
      AppRoute.work: WorkScreen,
      AppRoute.caseStudy: CaseStudyScreen,
      AppRoute.writing: WritingScreen,
      AppRoute.about: AboutScreen,
      AppRoute.courtyard: CourtyardScreen,
      AppRoute.console: ConsoleScreen,
      AppRoute.campaign: StationScreen,
    };

    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await pumpFrames(tester);
    final router = GoRouter.of(tester.element(find.byType(ChromeScaffold)));

    for (final route in AppRoute.values) {
      router.go(
        route.path
            .replaceAll(':slug', 'fixture')
            .replaceAll(':campaign', 'fixture'),
      );
      await pumpFrames(tester);

      final screen = built[route];
      if (screen != null) {
        expect(find.byType(screen), findsOneWidget, reason: route.name);
      } else {
        expect(
          tester
              .widget<PlaceholderScreen>(find.byType(PlaceholderScreen))
              .route,
          route,
          reason: route.name,
        );
      }
      expect(tester.takeException(), isNull, reason: route.name);
    }
  });

  testWidgets('global chrome frames every route except the static two', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await pumpFrames(tester);
    final router = GoRouter.of(tester.element(find.byType(ChromeScaffold)));

    for (final route in AppRoute.values) {
      router.go(
        route.path
            .replaceAll(':slug', 'fixture')
            .replaceAll(':campaign', 'fixture'),
      );
      await pumpFrames(tester);

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

  testWidgets('a campaign entry redirects to the station', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await pumpFrames(tester);
    final router = GoRouter.of(tester.element(find.byType(ChromeScaffold)))
      ..go('/r/graduate-role');
    await pumpFrames(tester);

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.byType(StationScreen), findsOneWidget);
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('$mode renders a themed route in $locale', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: NocturneApp(themeMode: mode, locale: locale),
          ),
        );
        await pumpFrames(tester);
        final context = tester.element(find.byType(ChromeScaffold));
        final expected = mode == ThemeMode.dark
            ? nocturneTokens
            : daybreakTokens;

        expect(context.tokens, expected);
        expect(Theme.of(context).scaffoldBackgroundColor, expected.void_);
        expect(
          Directionality.of(context),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
