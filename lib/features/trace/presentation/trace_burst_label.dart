import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// What a burst says when the signal locks onto it.
///
/// One field, because one field is what the owner asked the card to carry:
/// where the stop was. The company, the dates and the title are all printed by
/// the career entry the card is anchored to, a few hundred pixels away, and
/// repeating them made the card a second copy of the entry rather than a
/// marker on it.
typedef TraceLabel = ({String id, String location});

/// One burst's readout, shown while the signal is locked onto it.
class TraceBurstLabel extends StatelessWidget {
  /// Places a content readout beside its measured burst.
  const TraceBurstLabel({
    required this.label,
    required this.top,
    required this.isVisible,
    required this.gap,
    super.key,
  });

  /// The role content, when available.
  final TraceLabel? label;

  /// Viewport position of the label.
  final double top;

  /// Whether the signal is locked or reduced motion shows all labels.
  final bool isVisible;

  /// The clear ground between the end of the copy and the first block.
  ///
  /// The card is centred in it. Pushing it just off the wall left the middle
  /// of a wide page empty with a card pressed against the stone; the owner
  /// asked for it in the middle, and the middle is this.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final content = label;
    if (content == null || gap <= 0) return const SizedBox.shrink();
    final tokens = context.tokens;

    // Which way the gap is. The wall is on the trailing edge, so the gap is
    // on its leading side -- the left of it in English, the right of it in
    // Arabic. Getting this from the text direction rather than assuming left
    // keeps the card beside the stone in both.
    final away = Directionality.of(context) == TextDirection.rtl ? 1.0 : -1.0;

    return PositionedDirectional(
      top: top,
      start: 0,
      // The box is exactly the gap, translated off the wall's leading edge, so
      // the card inside it is centred on the clear ground rather than pressed
      // against the stone. It used to sit at the column's own edge *inside*
      // it, drawn over the blocks, which is what the owner marked.
      child: FractionalTranslation(
        translation: Offset(away, 0),
        child: SizedBox(
          width: gap,
          child: Center(
            child: AnimatedOpacity(
              opacity: isVisible ? 1 : 0,
              duration: ReducedMotion.duration(context, Motion.standard),
              curve: MotionCurves.emphasized,
              child: InstrumentPanel(
                fill: tokens.surface,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space16,
                  vertical: tokens.space12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A gold tick, because this card is the live one: it marks
                    // where the reader is on the page rather than describing
                    // anything.
                    SizedBox(
                      width: tokens.space8,
                      height: tokens.hairlineWidth * 2,
                      child: ColoredBox(color: tokens.beacon),
                    ),
                    SizedBox(width: tokens.space8),
                    Flexible(
                      // Two lines before anything is cut. The gap beside the
                      // wall is about 230 pixels at 1440 wide, and on one line
                      // "Manchester, United Kingdom" lost its country to an
                      // ellipsis -- which is the half of a place name a reader
                      // actually needs.
                      child: Text(
                        content.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyS.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
