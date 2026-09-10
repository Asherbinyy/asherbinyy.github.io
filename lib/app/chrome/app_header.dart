import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_mark.dart';
import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/chrome_control.dart';
import 'package:nocturne/app/chrome/theme_brazier.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/analytics/interactions.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// The 64px header: mark, route links, and the three controls.
///
/// Deliberately not sticky-shrinking. The screen spec calls a shrinking header
/// a generic tell and notes it would fight the rail, so this stays 64px and
/// does not animate on scroll.
class AppHeader extends ConsumerWidget {
  /// [current] is the route being displayed.
  const AppHeader({required this.current, super.key});

  /// Active route, for the nav's selected state.
  final AppRoute? current;

  /// Whether the route links fit in the header beside the three controls.
  ///
  /// Below the expanded breakpoint they do not, so `ChromeScaffold` gives them
  /// their own row. The screen spec draws the desktop header and says only
  /// that the *rail* collapses below 1024px; dropping the links entirely would
  /// leave a phone browser with no navigation at all, and phone browsers are a
  /// primary target.
  static bool hasInlineNav(BuildContext context) =>
      context.platform.viewport.index >= ViewportClass.expanded.index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final theme = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final isRecruiterMode = ref.watch(recruiterModeProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.void_,
        border: Border(
          bottom: BorderSide(
            color: tokens.hairline,
            width: tokens.hairlineWidth,
          ),
        ),
      ),
      child: SizedBox(
        height: tokens.headerHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.platform.gutter,
          ),
          child: Row(
            children: [
              AppMark(semanticLabel: l10n.markLink),
              const Spacer(),
              if (AppHeader.hasInlineNav(context) && !isRecruiterMode)
                AppNav(current: current),
              SizedBox(width: tokens.space16),
              ChromeControl(
                label: l10n.recruiterModeGlyph,
                semanticLabel: isRecruiterMode
                    ? l10n.recruiterModeOn
                    : l10n.recruiterModeOff,
                isActive: isRecruiterMode,
                onPressed: ref.read(recruiterModeProvider.notifier).toggle,
              ),
              ChromeControl(
                label: locale.languageCode.toUpperCase(),
                semanticLabel: locale == AppLocale.english
                    ? l10n.languageSwitchToArabic
                    : l10n.languageSwitchToEnglish,
                isActive: false,
                onPressed: () {
                  ref.read(localeControllerProvider.notifier).toggle();
                  ref.recordInteraction(
                    AnalyticsEvent.languageChanged,
                    route: current?.path ?? AppRoute.home.path,
                    inputMode: context.platform.inputMode,
                  );
                },
              ),
              ChromeControl(
                label: l10n.themeGlyph,
                semanticLabel: theme == AppTheme.nocturne
                    ? l10n.themeSwitchToDaybreak
                    : l10n.themeSwitchToNocturne,
                isActive: theme == AppTheme.daybreak,
                // A brazier rather than the half-filled circle every site
                // uses: a temple is lit by fire, so day and night here is a
                // bowl of it catching or being put out.
                face: (context, colour) => ThemeBrazier(
                  isLit: theme == AppTheme.daybreak,
                  colour: colour,
                ),
                onPressed: () {
                  ref.read(themeControllerProvider.notifier).toggle();
                  ref.recordInteraction(
                    AnalyticsEvent.themeChanged,
                    route: current?.path ?? AppRoute.home.path,
                    inputMode: context.platform.inputMode,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
