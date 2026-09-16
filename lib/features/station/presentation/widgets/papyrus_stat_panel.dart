import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/papyrus_painter.dart';
import 'package:nocturne/core/painting/papyrus_roll_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/telemetry_value.dart';

/// A figure on a sheet of papyrus that rolls up when you click it.
///
/// Only the first two figures get this, by the owner's instruction: the years
/// and the degree. It is not a treatment for every card on the site, and
/// applying it to the education or career panels was the thing he turned down.
///
/// The behaviour he asked for, exactly: **rolled closed on a click, open again
/// when the pointer leaves, or on a second click.** The pointer-exit rule is
/// what keeps it from being a trap — a card you closed and cannot reopen
/// because the control you would click is now rolled up inside it.
///
/// Touch has no pointer to leave, so there the second tap is the whole story.
/// With reduced motion the roll is instant rather than absent: the state is
/// information, and removing it would remove the card's only interaction.
class PapyrusStatPanel extends StatefulWidget {
  /// [locale] resolves the label's channel without a `BuildContext` lookup.
  const PapyrusStatPanel({required this.stat, required this.locale, super.key});

  /// The owner-supplied value and label.
  final ProfileStat stat;

  /// Active content channel.
  final AppLocale locale;

  /// Both cards are this size.
  ///
  /// The owner's complaint was that they did not match — one grew to its text
  /// and the other did not. A sheet of papyrus is a sheet of papyrus, and a
  /// roll needs a known height to wind into anyway.
  static const double width = 200;

  /// Tall enough for the numeral and two lines of label at large text sizes.
  ///
  /// Arabic sets taller than English at the same scale, and the label wraps to
  /// two lines there, so a height that fitted the English card overflowed the
  /// Arabic one by eight pixels. Sized for the taller of the two rather than
  /// for the one that happened to be tested first.
  static const double height = 124;

  /// Reed count for a card rather than for a map.
  ///
  /// The sheet painter is built for the atlas, where 34 fibres across a wide
  /// panel read as a weave. At 200px the same count reads as millimetre graph
  /// paper, which is the opposite of the material.
  static const int fibresAcross = 13;

  /// The cross-laid layer.
  static const int fibresDown = 8;

  @override
  State<PapyrusStatPanel> createState() => _PapyrusStatPanelState();
}

class _PapyrusStatPanelState extends State<PapyrusStatPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 520),
  );
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _roll.dispose();
    _states.dispose();
    super.dispose();
  }

  bool get _closed => _roll.value > 0.5;

  /// Rolls the sheet up. Hovering does this now, not clicking.
  ///
  /// The owner asked for the roll to happen under the pointer and to come
  /// back when it leaves: a sheet on a table lifts as a hand passes over it.
  /// Tapping still works, because a phone has no hover.
  void _close() {
    if (_closed) return;
    if (ReducedMotion.of(context)) {
      _roll.value = 1;
      return;
    }
    unawaited(_roll.animateTo(1, curve: Curves.easeInOut));
  }

  void _toggle() {
    if (ReducedMotion.of(context)) {
      _roll.value = _closed ? 0 : 1;
      return;
    }
    // Unrolling is the heavier half: a sheet springs open rather than being
    // wound, so it gets the easing that overshoots slightly and settles.
    if (_closed) {
      unawaited(_roll.animateBack(0, curve: Curves.easeOutBack));
    } else {
      unawaited(_roll.animateTo(1, curve: Curves.easeInOut));
    }
  }

  void _open() {
    if (!_closed) return;
    if (ReducedMotion.of(context)) {
      _roll.value = 0;
      return;
    }
    unawaited(_roll.animateBack(0, curve: Curves.easeOutBack));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = widget.stat.label.resolve(widget.locale);

    return Semantics(
      button: true,
      label: '${widget.stat.value}. $label',
      hint: context.l10n.heroStatRollHint,
      onTap: _toggle,
      child: ExcludeSemantics(
        child: MouseRegion(
          // The whole interaction on a pointer: the sheet winds up as the hand
          // arrives and unwinds as it leaves. There is nothing to click and
          // nothing to click back.
          onEnter: (_) => _close(),
          onExit: (_) => _open(),
          cursor: context.platform.isPointer
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: ListenableBuilder(
            listenable: _states,
            builder: (context, child) => FocusRing(
              isFocused: _states.value.contains(WidgetState.focused),
              child: InkWell(
                onTap: _toggle,
                statesController: _states,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: child,
              ),
            ),
            // Width comes from the grid, not from here. Insisting on 200px
            // inside a 350px phone column is what left these sitting against
            // the left edge with the slack all on one side.
            child: SizedBox(
              width: double.infinity,
              height: PapyrusStatPanel.height,
              child: AnimatedBuilder(
                animation: _roll,
                builder: (context, _) {
                  final rolled = _roll.value.clamp(0.0, 1.0);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // The sheet shortens with the roll. Painting it full
                      // height and putting the cylinder over it left a roll
                      // sitting on top of a sheet that was still all there.
                      ClipRect(
                        clipper: _ExposedSheet(rolled),
                        child: CustomPaint(
                          painter: PapyrusPainter(
                            sheet: tokens.surfaceRaised,
                            fibre: tokens.hairline,
                            edge: tokens.hairlineStrong,
                            hairlineWidth: tokens.hairlineWidth,
                            fibresAcross: PapyrusStatPanel.fibresAcross,
                            fibresDown: PapyrusStatPanel.fibresDown,
                          ),
                        ),
                      ),
                      // The writing goes away with the sheet it is written on.
                      ClipRect(
                        clipper: _ExposedSheet(rolled),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.space16,
                            vertical: tokens.space12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TelemetryNumeral(value: widget.stat.value),
                              // Flexible as well as sized: a text scale this
                              // was not measured against should shorten the
                              // label, not paint over the edge of the sheet.
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.meta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: PapyrusRollPainter(
                          roll: rolled,
                          sheet: tokens.surfaceRaised,
                          fibre: tokens.hairline,
                          shadow: tokens.surface,
                          hairlineWidth: tokens.hairlineWidth,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How much of the sheet is still flat, and therefore still readable.
class _ExposedSheet extends CustomClipper<Rect> {
  const _ExposedSheet(this.roll);

  final double roll;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * (1 - roll));

  @override
  bool shouldReclip(_ExposedSheet old) => old.roll != roll;
}
