import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/app_mark.dart';
import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/app_rail.dart';
import 'package:nocturne/app/chrome/chrome_control.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/features/station/presentation/station_screen.dart';
import 'package:nocturne/features/work/presentation/work_screen.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';

void main() {
  group('breakpoints', () {
    for (final breakpoint in ChromeBreakpoint.values) {
      testWidgets('renders at ${breakpoint.name}', (tester) async {
        await pumpChrome(tester, breakpoint: breakpoint);

        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.byType(AppFooter), findsOneWidget);
        expect(find.byType(AppNav), findsOneWidget);
        // The header is not sticky-shrinking; it is this height everywhere.
        expect(
          tester.getSize(find.byType(AppHeader)).height,
          Tokens.headerHeight,
        );
        expect(
          tester.getSize(find.byType(AppFooter)).height,
          Tokens.footerHeight,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('the rail is present only above 1024px at '
          '${breakpoint.name}', (tester) async {
        await pumpChrome(tester, breakpoint: breakpoint);

        expect(
          find.byType(AppRail),
          breakpoint.hasRail ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('the rail keeps its specified width', (tester) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.large);

      expect(tester.getSize(find.byType(AppRail)).width, Tokens.railWidth);
    });

    testWidgets('no route link is lost on a phone-width browser', (
      tester,
    ) async {
      await pumpChrome(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        capabilities: touchBrowser,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // The rail collapses below 1024px, but navigation must not vanish with
      // it — a phone browser is a primary target.
      for (final destination in NavDestination.values) {
        expect(
          find.text(destination.label(l10n)),
          findsOneWidget,
          reason: destination.name,
        );
      }
    });
  });

  group('toggles', () {
    testWidgets('the theme control switches artifact and persists', (
      tester,
    ) async {
      final container = await pumpChrome(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.bySemanticsLabel(l10n.themeSwitchToDaybreak));
      await pumpFrames(tester);

      expect(container.read(themeControllerProvider), AppTheme.daybreak);
      expect(
        container
            .read(preferenceStoreProvider)
            .read(PreferenceKey.theme.storageKey),
        AppTheme.daybreak.storageKey,
      );
      expect(
        tester.element(find.byType(ChromeScaffold)).tokens,
        daybreakTokens,
      );
    });

    testWidgets('the language control flips channel and direction', (
      tester,
    ) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.expanded);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.bySemanticsLabel(l10n.languageSwitchToArabic));
      await pumpFrames(tester);
      final active = tester.element(find.byType(ChromeScaffold));

      expect(active.l10n.localeName, 'ar');
      expect(Directionality.of(active), TextDirection.rtl);
    });

    testWidgets('Recruiter Mode removes the rail', (tester) async {
      final container = await pumpChrome(
        tester,
        breakpoint: ChromeBreakpoint.large,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
      expect(find.byType(AppRail), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.recruiterModeOff));
      await pumpFrames(tester);

      expect(container.read(recruiterModeProvider), isTrue);
      expect(find.byType(AppRail), findsNothing);
    });

    testWidgets('a restored preference is applied on the first frame', (
      tester,
    ) async {
      await pumpChrome(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        preferences: {
          PreferenceKey.theme.storageKey: AppTheme.daybreak.storageKey,
          PreferenceKey.language.storageKey: 'ar',
        },
      );
      final active = tester.element(find.byType(ChromeScaffold));

      expect(active.tokens, daybreakTokens);
      expect(Directionality.of(active), TextDirection.rtl);
    });
  });

  group('accessibility', () {
    testWidgets('every chrome control carries a semantic label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.expanded);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      for (final label in [
        l10n.markLink,
        l10n.recruiterModeOff,
        l10n.languageSwitchToArabic,
        l10n.themeSwitchToDaybreak,
        l10n.footerConsent,
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }

      semantics.dispose();
    });

    testWidgets('controls meet the touch target on a touch browser', (
      tester,
    ) async {
      await pumpChrome(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        capabilities: touchBrowser,
      );

      for (final element in find.byType(ChromeControl).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.height, greaterThanOrEqualTo(Tokens.touchTarget));
        expect(size.width, greaterThanOrEqualTo(Tokens.touchTarget));
      }
    });

    testWidgets('tab traversal reaches the mark, the links and the controls', (
      tester,
    ) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.large);

      const expected = [AppMark, AppNav, ChromeControl, AppFooter];
      final reached = <Type>{};
      for (var press = 0; press < 24; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump(Tokens.quick);
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused == null) continue;
        if (focused.findAncestorWidgetOfExactType<AppMark>() != null) {
          reached.add(AppMark);
        }
        if (focused.findAncestorWidgetOfExactType<AppNav>() != null) {
          reached.add(AppNav);
        }
        if (focused.findAncestorWidgetOfExactType<ChromeControl>() != null) {
          reached.add(ChromeControl);
        }
        if (focused.findAncestorWidgetOfExactType<AppFooter>() != null) {
          reached.add(AppFooter);
        }
      }

      expect(reached, containsAll(expected));
    });
  });

  group('routing', () {
    testWidgets('a route link navigates and marks itself active', (
      tester,
    ) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.large);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.navWork));
      await pumpFrames(tester);

      expect(find.byType(WorkScreen), findsOneWidget);
      expect(find.byType(StationScreen), findsNothing);
    });

    testWidgets('the mark returns to the station', (tester) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.large);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.navAbout));
      await pumpFrames(tester);
      await tester.tap(find.byType(AppMark));
      await pumpFrames(tester);

      // The station route renders the real screen, not a placeholder.
      expect(find.byType(StationScreen), findsOneWidget);
    });
  });
}
