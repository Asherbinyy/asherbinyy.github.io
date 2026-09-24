import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_maker.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/content_gallery.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/station/presentation/widgets/reach_row.dart';
import 'package:nocturne/features/work/presentation/widgets/store_links.dart';

/// One shipped application, as a visual card.
///
/// The screen spec argued for a ledger over a card grid, and its reason was
/// specific: cards would put "twelve identical rounded rectangles on screen"
/// and lose the fact that these are shipped products with store links.
///
/// Both halves of that objection are answered here rather than ignored. The
/// artwork is the application's own screens, fanned like a hand of cards --
/// or, for the few with none to show, `StationCard`, seeded from the id so no
/// two are alike. And the store links stay as their own explicit, separately
/// focusable controls rather than being folded into the card's tap target, so
/// what the page is *for* is still the most actionable thing on it.
///
/// The owner asked for the cards to answer the pointer, the press and the
/// open: the fan spreads under the pointer, gives under the press, and the
/// front screen comes forward as the page opens.
class WorkCard extends StatelessWidget {
  /// [origin] carries the country and coordinates when the content records one.
  const WorkCard({
    required this.app,
    required this.domainLabel,
    required this.origin,
    this.maker,
    super.key,
  });

  /// The application this card stands for.
  final ShippedApp app;

  /// Localised domain name.
  final String domainLabel;

  /// Where the work happened, when the content records it.
  final AppOrigin? origin;

  /// Who it was built at or for, when the content records it.
  final AppMaker? maker;

  /// The narrowest this card is worth drawing, and what the grid sizes
  /// columns from.
  ///
  /// It used to be the card's *fixed* width, which is why the Treasury sat
  /// left of centre on a phone: a 280px card in a 295px column leaves fifteen
  /// pixels, all of them on the right. The card now takes the width it is
  /// given and this only decides how many fit.
  static const double width = 280;

  /// The artwork's height: tall enough for a phone screen to be a screen.
  static const double artHeight = Tokens.workArtHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final metric = app.metric;
    final role = app.role?.resolve(context.channel);
    final maker = this.maker;

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
        _OpenDetail(app: app, domainLabel: domainLabel, origin: origin),
        SizedBox(height: tokens.space16),
        Text(app.name, style: type.heading),
        if (maker != null) ...[
          SizedBox(height: tokens.space4),
          MakerLine(maker: maker),
        ],
        ContentGallery(entries: app.media, label: app.name),
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

/// Where an application was made: the country's flag and the company's
/// name, or "Personal project".
class MakerLine extends StatelessWidget {
  /// Draws [maker].
  const MakerLine({required this.maker, this.style, super.key});

  /// Who made it.
  final AppMaker maker;

  /// The text style; the meta style when null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (maker) {
      MadeAt(:final name, :final country, :final isFreelance) => [
        if (country != null) ?ReachRow.flagOf(country),
        if (isFreelance) l10n.careerFreelance else name,
      ].join('  '),
      MadeForSelf() => l10n.workPersonalProject,
    };
    return Text(
      text,
      style:
          style ?? context.type.meta.copyWith(color: context.tokens.textMuted),
    );
  }
}

/// The artwork, turned into the door to `/work/<id>`.
///
/// Under the pointer the fan spreads, under a press it gives, and on the
/// click the front screen comes forward for a moment before the page opens,
/// so the open reads as that screen being picked up rather than as a cut.
/// Under reduced motion it simply opens.
class _OpenDetail extends StatefulWidget {
  const _OpenDetail({
    required this.app,
    required this.domainLabel,
    required this.origin,
  });

  final ShippedApp app;
  final String domainLabel;
  final AppOrigin? origin;

  @override
  State<_OpenDetail> createState() => _OpenDetailState();
}

class _OpenDetailState extends State<_OpenDetail> {
  final WidgetStatesController _states = WidgetStatesController();
  bool _isOpening = false;

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _open() {
    void go() => context.goNamed(
      AppRoute.caseStudy.name,
      pathParameters: {'slug': widget.app.id},
    );
    if (ReducedMotion.of(context)) {
      go();
      return;
    }
    setState(() => _isOpening = true);
    unawaited(
      Future<void>.delayed(Tokens.workOpenLead, () {
        if (mounted) go();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final app = widget.app;
    return Semantics(
      button: true,
      label: context.l10n.workOpenApp(app.name),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final states = _states.value;
          final isRaised =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused);
          final isPressed = states.contains(WidgetState.pressed);
          final quick = ReducedMotion.duration(context, Motion.quick);
          return FocusRing(
            isFocused: states.contains(WidgetState.focused),
            child: AnimatedScale(
              scale: isPressed ? Tokens.workPressScale : 1,
              duration: quick,
              curve: MotionCurves.emphasized,
              child: AnimatedContainer(
                duration: quick,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.cardRadius),
                  boxShadow: isRaised || _isOpening
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
                  onTap: _open,
                  statesController: _states,
                  borderRadius: BorderRadius.circular(Tokens.cardRadius),
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  mouseCursor: context.platform.isPointer
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  child: ExcludeSemantics(
                    child: app.shots.isEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Tokens.cardRadius,
                            ),
                            child: StationCard(
                              seedId: app.id,
                              name: '',
                              height: WorkCard.artHeight,
                              domainLabel: widget.domainLabel,
                              country: widget.origin?.country,
                              latitude: widget.origin?.latitude,
                              longitude: widget.origin?.longitude,
                            ),
                          )
                        : ShotFan(
                            app: app,
                            height: WorkCard.artHeight,
                            spread: isRaised ? 1 : 0,
                            lift: _isOpening ? 1 : 0,
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

/// An application's screens, fanned like a hand of cards over the ground its
/// seed draws.
///
/// Three at most: the first in front, the next two either side of it and a
/// little behind. [spread] opens the hand -- the pointer over it -- and
/// [lift] brings the front screen forward, which is the card being opened.
class ShotFan extends StatelessWidget {
  /// Fans [app]'s first screens in a box [height] tall.
  const ShotFan({
    required this.app,
    required this.height,
    this.spread = 0,
    this.lift = 0,
    super.key,
  });

  /// The application whose screens these are.
  final ShippedApp app;

  /// The artwork's height.
  final double height;

  /// How far the hand is open, 0 to 1.
  final double spread;

  /// How far the front screen has come forward, 0 to 1.
  final double lift;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shots = app.shots.take(3).toList();
    final duration = ReducedMotion.duration(context, Motion.standard);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.cardRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The seed's own drawing, dimmed, so each app's ground is still
            // its own even when its screens are in front of it.
            Positioned.fill(
              child: Opacity(
                opacity: Tokens.workFanGroundAlpha,
                child: StationCard(seedId: app.id, name: '', height: height),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: spread),
              duration: duration,
              curve: MotionCurves.emphasized,
              builder: (context, open, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: lift),
                duration: duration,
                curve: MotionCurves.emphasized,
                builder: (context, forward, _) => Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Back to front: the sides first, the first screen last.
                    for (final index in [
                      for (var i = shots.length - 1; i >= 0; i--) i,
                    ])
                      _FannedShot(
                        path: shots[index],
                        height: height * Tokens.workShotHeight,
                        // -1, 1, 0: left, right, front. Mirrored in Arabic
                        // so the second screen is on the reading side.
                        side: switch (index) {
                          0 => 0,
                          1 => isRtl ? 1 : -1,
                          _ => isRtl ? -1 : 1,
                        },
                        open: open,
                        forward: index == 0 ? forward : 0,
                        edge: tokens.hairlineStrong,
                        shadow: tokens.void_,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One screen in the fan: a phone-shaped frame, turned and placed by [side].
class _FannedShot extends StatelessWidget {
  const _FannedShot({
    required this.path,
    required this.height,
    required this.side,
    required this.open,
    required this.forward,
    required this.edge,
    required this.shadow,
  });

  final String path;
  final double height;

  /// -1 left, 0 front, 1 right.
  final int side;
  final double open;
  final double forward;
  final Color edge;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    final width = height * Tokens.workShotAspect;
    final radius = BorderRadius.circular(width * Tokens.workShotRadius);
    final offset =
        side * width * (Tokens.workFanOffset + open * Tokens.workFanOpen);
    final turn = side * (Tokens.workFanTurn + open * Tokens.workFanTurnOpen);
    final rise = side == 0
        ? -open * Tokens.workFanRise - forward * Tokens.workFanRise * 2
        : open * Tokens.workFanRise * 0.5 + height * Tokens.workFanDrop;
    return Transform.translate(
      offset: Offset(offset, rise),
      child: Transform.rotate(
        angle: turn,
        child: Transform.scale(
          scale:
              (side == 0 ? 1 : Tokens.workFanBackScale) +
              forward * Tokens.workFanForwardScale,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: edge),
              boxShadow: [
                BoxShadow(
                  color: shadow.withValues(alpha: Tokens.workShotShadowAlpha),
                  blurRadius: Tokens.workShotShadowBlur,
                  offset: const Offset(0, Tokens.workShotShadowDrop),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Image(
                image: contentImage(context, path),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                // A missing file is a content mistake, not a crash: the frame
                // stays, empty, and the rest of the fan still reads.
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
