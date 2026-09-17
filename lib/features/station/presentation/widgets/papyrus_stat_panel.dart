import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/painting/papyrus_painter.dart';
import 'package:nocturne/core/painting/papyrus_roll_painter.dart';
import 'package:nocturne/core/widgets/telemetry_value.dart';

/// A figure written on a sheet of papyrus.
///
/// Only the first two figures get this, by the owner's instruction: the years
/// and the degree. It is not a treatment for every card on the site, and
/// applying it to the education or career panels was the thing he turned down.
///
/// It used to roll itself up -- closed under the pointer or on a tap, open
/// again when the pointer left. That is gone at his request, and his reason is
/// the right one: these were meant to read as two sheets of papyrus, and a
/// sheet that spends most of its time wound into a cylinder does not. The
/// painters that draw the roll are still here and still correct; nothing
/// drives them.
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
  /// Held at zero: a sheet, fully unrolled.
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 520),
  );

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = widget.stat.label.resolve(widget.locale);

    // A sheet, and it stays one.
    //
    // This used to wind itself up as the pointer arrived and unwind as it
    // left, and tapping did the same. The owner's objection is that the two of
    // these were meant to read as papyrus and did not -- and the rolling is
    // why: the thing being shown spent most of its time being a cylinder. So
    // there is no hover, no tap, no hint and no button. It is a number written
    // on papyrus, which is all it was ever meant to be.
    //
    // The roll stays at zero rather than being torn out. `PapyrusPainter`,
    // `PapyrusRollPainter` and `_ExposedSheet` all take a roll amount and are
    // all still correct; reinstating the treatment means driving the
    // controller again and nothing else.
    return Semantics(
      label: '${widget.stat.value}. $label',
      child: ExcludeSemantics(
        // Width comes from the grid, not from here.
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
                          // Flexible as well as sized: a text scale this was
                          // not measured against should shorten the label, not
                          // paint over the edge of the sheet.
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
