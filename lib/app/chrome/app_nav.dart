import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The routes the header links to, in the order the screen spec lists them.
///
/// A subset of [AppRoute] rather than all of it: the case study, campaign,
/// console and static routes are reachable but not navigation destinations.
enum NavDestination {
  /// The front door.
  home(AppRoute.home),

  /// The career map.
  journey(AppRoute.journey),

  /// Shipped applications.
  work(AppRoute.work),

  /// Articles.
  writing(AppRoute.writing),

  /// Background and contact.
  about(AppRoute.about),

  /// The courtyard.
  courtyard(AppRoute.courtyard);

  const NavDestination(this.route);

  /// The route this destination navigates to.
  final AppRoute route;

  /// The viewer-facing name in the active locale.
  String label(AppLocalizations l10n) => switch (this) {
    NavDestination.home => l10n.navHome,
    NavDestination.journey => l10n.navJourney,
    NavDestination.work => l10n.navWork,
    NavDestination.writing => l10n.navWriting,
    NavDestination.about => l10n.navAbout,
    NavDestination.courtyard => l10n.navCourtyard,
  };
}

/// The header's route links.
class AppNav extends StatelessWidget {
  /// [current] is the route being displayed, which renders as active.
  const AppNav({required this.current, super.key});

  /// The active route, or null on a route that is not a destination.
  final AppRoute? current;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final destination in NavDestination.values)
        _NavLink(
          destination: destination,
          isActive: destination.route == current,
        ),
    ],
  );
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.destination, required this.isActive});

  final NavDestination destination;
  final bool isActive;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = widget.destination.label(context.l10n);

    return Semantics(
      link: true,
      // The visible text is excluded below to avoid announcing the label
      // twice, which means this node has to carry it — without this the whole
      // primary navigation announces nothing at all.
      label: label,
      selected: widget.isActive,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isHovered = _states.value.contains(WidgetState.hovered);
          final colour = widget.isActive
              ? tokens.beacon
              : isHovered
              ? tokens.textPrimary
              : tokens.textSecondary;

          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => context.goNamed(widget.destination.route.name),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: tokens.space12,
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: ReducedMotion.duration(context, Motion.quick),
                      style: context.type.bodyS.copyWith(color: colour),
                      child: ExcludeSemantics(child: Text(label)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
