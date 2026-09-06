import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';

/// Builds the browser tab title for a route.
///
/// Design-system section 12: the name comes first only on the two entry points
/// a stranger lands on, so a stack of open tabs is scannable — a recruiter with
/// `/work`, `/about` and a case study open sees what each one is without
/// hovering. `/console` omits the name because it is not a public surface.
///
/// The switch is exhaustive on purpose: adding a route must fail to compile
/// here rather than silently inherit someone else's title.
String routeTitle({
  required AppRoute route,
  required AppLocalizations l10n,
  required String name,
}) => switch (route) {
  AppRoute.station => '$name — ${l10n.tabRole}',
  AppRoute.brief => '$name — ${l10n.navBrief}',
  AppRoute.console => l10n.navConsole,
  AppRoute.signal => '${l10n.navSignal} — $name',
  AppRoute.work => '${l10n.navWork} — $name',
  // Case studies land in Milestone 2. Until a study supplies its own name, the
  // section name is the honest reading rather than an invented one.
  AppRoute.caseStudy => '${l10n.navWork} — $name',
  AppRoute.writing => '${l10n.navWriting} — $name',
  AppRoute.about => '${l10n.navAbout} — $name',
  AppRoute.privacy => '${l10n.navPrivacy} — $name',
  AppRoute.howItWasBuilt => '${l10n.navHowItWasBuilt} — $name',
  AppRoute.cv => '$name — ${l10n.navCv}',
  // A campaign link redirects to the station, so it carries its title.
  AppRoute.campaign => '$name — ${l10n.tabRole}',
};

/// Applies the route's title to the browser tab.
///
/// `Title` writes through `SystemChrome`, which on web sets `document.title`,
/// and it rebuilds per route — so the tab updates on client-side navigation
/// rather than only on a hard reload, which is the common Flutter Web miss.
class RouteTitle extends ConsumerWidget {
  /// Wraps one route's content.
  const RouteTitle({required this.route, required this.child, super.key});

  /// The route being displayed.
  final AppRoute route;

  /// Routed content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final name = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady(:final data) => data.name.resolve(locale),
      ContentFallback(:final profile) => profile.name.resolve(locale),
      _ => null,
    };

    return Title(
      // Until identity resolves, the shell's own static title stands. Inventing
      // a placeholder name would be worse than the correct one arriving late.
      title: name == null
          ? ''
          : routeTitle(route: route, l10n: context.l10n, name: name),
      color: context.tokens.void_,
      child: child,
    );
  }
}
