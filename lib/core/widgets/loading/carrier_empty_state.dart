import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/painting/carrier_painter.dart';

/// The carrier at rest, plus one line saying what to do next.
///
/// Section 11 gives every empty state this shape: a settled waveform and a line
/// of direction, never "no results found" on its own. The carrier does not
/// animate here — nothing is in progress — so this is a still frame of the same
/// curve the loader draws, and it needs no reduced-motion branch.
///
/// [direction] is supplied by the caller because only the screen knows what the
/// viewer should change; it must come from ARB like any other copy.
class CarrierEmptyState extends StatelessWidget {
  /// [direction] is the single line of guidance shown under the carrier.
  const CarrierEmptyState({required this.direction, super.key});

  /// What the viewer can do, in the active locale.
  final String direction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: CustomPaint(
            size: Size(tokens.loaderWidth, tokens.loaderHeight),
            painter: CarrierPainter(
              phase: Tokens.zero,
              colour: tokens.instrumentDim,
              strokeWidth: tokens.hairlineWidth,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
        SizedBox(height: tokens.space12),
        Text(direction, style: context.type.body),
      ],
    );
  }
}
