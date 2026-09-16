import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/work/presentation/widgets/store_links.dart';

/// One shipped application, as a visual card.
///
/// The screen spec argued for a ledger over a card grid, and its reason was
/// specific: cards would put "twelve identical rounded rectangles on screen"
/// and lose the fact that these are shipped products with store links.
///
/// Both halves of that objection are answered here rather than ignored. The
/// artwork is `StationCard`, which is seeded from the application id and draws
/// the propagation map's own node vocabulary — so no two cards are alike, and
/// an application with a recorded country places its node where the country
/// is. And the store links stay as their own explicit, separately focusable
/// controls rather than being folded into the card's tap target, so what the
/// page is *for* is still the most actionable thing on it.
///
/// There is deliberately no decorative hover on the card body. The design
/// system says motion answers actions, and a card that lights up without
/// offering anything to press is motion answering nothing. The interaction
/// lives where the actions are: each store link hovers, takes focus and shows
/// a focus ring.
class WorkCard extends StatelessWidget {
  /// [origin] carries the country and coordinates when the content records one.
  const WorkCard({
    required this.app,
    required this.domainLabel,
    required this.origin,
    super.key,
  });

  /// The application this card stands for.
  final ShippedApp app;

  /// Localised domain name.
  final String domainLabel;

  /// Where the work happened, when the content records it.
  final AppOrigin? origin;

  /// The narrowest this card is worth drawing, and what the grid sizes
  /// columns from.
  ///
  /// It used to be the card's *fixed* width, which is why the Treasury sat
  /// left of centre on a phone: a 280px card in a 295px column leaves fifteen
  /// pixels, all of them on the right. The card now takes the width it is
  /// given and this only decides how many fit.
  static const double width = 280;

  /// The artwork's height. Above `StationCard`'s derived labelling threshold,
  /// so the card carries the application's name itself at display-m rather
  /// than repeating it underneath.
  static const double artHeight = 160;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final metric = app.metric;
    final role = app.role?.resolve(context.channel);

    // No LayoutBuilder here on purpose: the grid wraps each row in an
    // IntrinsicHeight so every card in it shares a baseline, and a
    // LayoutBuilder cannot answer an intrinsic-height query. The card fills
    // the width it is handed instead of measuring it.
    // The artwork is the way in to the application's own page. The whole card
    // is not the target: the store links at the bottom are their own
    // destinations, and swallowing them into one big tap would mean a reader
    // who wanted the App Store got a case study instead.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Fills the height its row was given, so the store links below can
      // be pushed to a common baseline instead of floating wherever the
      // role text happens to end.
      children: [
        _OpenDetail(
          app: app,
          child: StationCard(
            seedId: app.id,
            name: app.name,
            height: artHeight,
            domainLabel: domainLabel,
            country: origin?.country,
            latitude: origin?.latitude,
            longitude: origin?.longitude,
          ),
        ),
        if (role != null) ...[
          SizedBox(height: tokens.space12),
          Text(role, style: type.bodyS.copyWith(color: tokens.textSecondary)),
        ],
        if (metric != null) ...[
          SizedBox(height: tokens.space8),
          // The strongest single string a card can carry, so it gets the
          // instrument treatment rather than another line of prose.
          Text(
            metric,
            style: type.telemetry.copyWith(color: tokens.instrument),
          ),
        ],
        // Whatever height is left over goes here, above the links, so the
        // one actionable row on the card is level across the whole grid.
        const Spacer(),
        SizedBox(height: tokens.space12),
        StoreLinks(app: app),
      ],
    );
  }
}

/// The artwork, turned into the door to `/work/<id>`.
///
/// It lifts a little under the pointer, which is the only motion here: the
/// owner asked for a transition, and the one worth having is the one that says
/// "this is a thing you can open" *before* it is clicked. The route change
/// itself is the app's own, so a shared page transition would fight the router
/// rather than help it.
class _OpenDetail extends StatefulWidget {
  const _OpenDetail({required this.app, required this.child});

  final ShippedApp app;
  final Widget child;

  @override
  State<_OpenDetail> createState() => _OpenDetailState();
}

class _OpenDetailState extends State<_OpenDetail> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: context.l10n.workOpenApp(widget.app.name),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, child) {
          final isRaised =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: AnimatedSlide(
              offset: isRaised ? const Offset(0, -0.012) : Offset.zero,
              duration: ReducedMotion.duration(context, Motion.quick),
              curve: MotionCurves.emphasized,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.cardRadius),
                  boxShadow: isRaised
                      ? [
                          BoxShadow(
                            color: tokens.beacon.withValues(
                              alpha: Tokens.contactGlowAlpha,
                            ),
                            blurRadius: Tokens.contactGlowBlur,
                          ),
                        ]
                      : null,
                ),
                child: InkWell(
                  onTap: () => context.goNamed(
                    AppRoute.caseStudy.name,
                    pathParameters: {'slug': widget.app.id},
                  ),
                  statesController: _states,
                  borderRadius: BorderRadius.circular(Tokens.cardRadius),
                  hoverColor: Colors.transparent,
                  mouseCursor: context.platform.isPointer
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  child: ExcludeSemantics(child: child),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
