import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

/// The itinerary: every career stop, and a way to get to one directly.
///
/// The career below is long, and the only way to reach the stop a viewer
/// actually came for was to scroll past every other one. This is the index for
/// it, and it also fills the ground the owner marked as empty in the
/// bottom-left of Home.
///
/// It is drawn as a line of stations rather than a list of links because the
/// site already calls these stops, draws them as cartouches on the atlas, and
/// runs a wall of carved stone down the other side of the page. A column of
/// underlined text here would belong to a different site.
class CareerStops extends StatelessWidget {
  /// [roles] arrive most recent first; this widget does not reorder them.
  const CareerStops({
    required this.roles,
    required this.anchorRegistry,
    super.key,
  });

  /// The stops, in the order the career sequence prints them.
  ///
  /// No locale: a stop is named by its company, or by where it was, and the
  /// content carries both as plain strings. The title, which is the only
  /// translated field on a role, belongs to the entry rather than the index.
  final List<CareerRole> roles;

  /// Supplies the keys the career entries are mounted under.
  final TraceAnchorRegistry anchorRegistry;

  @override
  Widget build(BuildContext context) {
    if (roles.length < 2) return const SizedBox.shrink();
    final tokens = context.tokens;
    final type = context.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: tokens.space16,
              height: tokens.hairlineWidth * 2,
              child: ColoredBox(color: tokens.beacon),
            ),
            SizedBox(width: tokens.space8),
            Text(
              context.l10n.stationStops,
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
        SizedBox(height: tokens.space16),
        // Across, not down. As a column of thin rows it read as a stray
        // sidebar -- the owner called it a thin random column -- and it left
        // the width it was supposed to be filling empty. As cards it is a row
        // of places, which is what it is.
        //
        // The full width of the page, in even rows. It was capped to the
        // copy's measure while the wall owned the trailing part of the page;
        // the wall is the background now, and the owner asked for every
        // section to share one width, edges lined up top to bottom.
        EvenGrid(
          minTileWidth: Tokens.stopCardMinWidth,
          spacing: tokens.space12,
          stretch: true,
          children: [
            for (final role in roles)
              _Stop(role: role, anchorRegistry: anchorRegistry),
          ],
        ),
      ],
    );
  }
}

class _Stop extends StatefulWidget {
  const _Stop({required this.role, required this.anchorRegistry});

  final CareerRole role;
  final TraceAnchorRegistry anchorRegistry;

  @override
  State<_Stop> createState() => _StopState();
}

class _StopState extends State<_Stop> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  /// The name this stop is known by, which is not the same field on every role.
  ///
  /// Five of the six roles carry no company, so the sequence below falls back
  /// to the city. This must say the same thing the entry it scrolls to says,
  /// or the viewer arrives somewhere that does not look like what he clicked.
  String get _name {
    final company = widget.role.company;
    if (company != null) return company;
    return '${widget.role.city}, ${widget.role.country}';
  }

  /// Just the year. The entry prints the full period; repeating it here would
  /// make the index as wide as the thing it indexes.
  String get _year => widget.role.start.split('-').first;

  void _goThere() {
    final target = widget.anchorRegistry.keyFor(widget.role.id).currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: ReducedMotion.duration(context, Motion.considered),
      curve: Curves.easeInOutCubic,
      // Not flush to the top: the page has a fixed chrome above it, and a stop
      // that lands under it looks like nothing happened.
      alignment: 0.12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    return Semantics(
      button: true,
      label: context.l10n.stationStopGoTo(_name),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);

          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: _goThere,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                curve: MotionCurves.emphasized,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space16,
                  vertical: tokens.space12,
                ),
                decoration: BoxDecoration(
                  color: isLit ? tokens.surfaceRaised : tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isLit ? tokens.beacon : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The cartouche, which is how this site marks a stop
                    // everywhere else it draws one.
                    CustomPaint(
                      size: const Size(
                        Tokens.stopRailWidth,
                        Tokens.stopNodeRadius * 3,
                      ),
                      painter: _StopMarkPainter(
                        rest: tokens.instrumentDim,
                        lit: tokens.beacon,
                        strokeWidth: tokens.hairlineWidth,
                        isLit: isLit,
                      ),
                    ),
                    SizedBox(width: tokens.space12),
                    // Bounded, so a long name shortens instead of pushing the
                    // card off a phone. "University of Salford" does not fit
                    // a 312px column and the card must not try to make it.
                    // Flexible as well, because on a phone the column is
                    // narrower again once the wall has its own edge.
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Tokens.stopCardTextWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: ReducedMotion.duration(
                                context,
                                Motion.quick,
                              ),
                              style: type.telemetryS.copyWith(
                                color: isLit ? tokens.beacon : tokens.textMuted,
                              ),
                              child: Text(_year),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: ReducedMotion.duration(
                                context,
                                Motion.quick,
                              ),
                              style: type.body.copyWith(
                                color: isLit
                                    ? tokens.textPrimary
                                    : tokens.textSecondary,
                              ),
                              child: Text(
                                _name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The cartouche on a stop card.
class _StopMarkPainter extends CustomPainter {
  const _StopMarkPainter({
    required this.rest,
    required this.lit,
    required this.strokeWidth,
    required this.isLit,
  });

  final Color rest;
  final Color lit;
  final double strokeWidth;
  final bool isLit;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);

    // Enclosed, like the stations on the atlas: filled gold when this is the
    // one the viewer is pointing at, a hairline ring otherwise.
    final loop = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: centre,
        width: Tokens.stopNodeRadius * 2 * Tokens.stationCartoucheRatio,
        height: Tokens.stopNodeRadius * 2,
      ),
      const Radius.circular(Tokens.stopNodeRadius),
    );
    canvas.drawRRect(
      loop,
      Paint()
        ..color = isLit ? lit : rest
        ..style = isLit ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // The tie bar closes the cartouche. Only when lit, for the same reason the
    // atlas only draws it on the selected stop: at this size it is noise.
    if (!isLit) return;
    canvas.drawLine(
      Offset(loop.right, centre.dy - Tokens.stopNodeRadius * 0.6),
      Offset(loop.right, centre.dy + Tokens.stopNodeRadius * 0.6),
      Paint()
        ..color = lit
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StopMarkPainter oldDelegate) =>
      oldDelegate.isLit != isLit ||
      oldDelegate.rest != rest ||
      oldDelegate.lit != lit;
}
