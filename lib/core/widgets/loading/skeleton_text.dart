import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/loading/sweep_shimmer.dart';

/// Hairline rules standing in for lines of text.
///
/// Section 11: text skeletons are rules at the line positions at 60% of the
/// measure, never full-width blocks, which read as a solid slab. Taking the
/// real [style] keeps each line box the exact height the text will occupy, so
/// swapping in the content shifts nothing.
class SkeletonText extends StatelessWidget {
  /// [lines] and [style] must match the content being awaited.
  const SkeletonText({
    required this.lines,
    required this.style,
    this.measureFraction = Tokens.skeletonTextFraction,
    super.key,
  });

  /// Number of text lines represented.
  final int lines;

  /// Style of the text this stands in for; supplies the line height.
  final TextStyle style;

  /// Rule width as a fraction of the measure.
  final double measureFraction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fontSize = style.fontSize ?? tokens.bodySize;
    final lineHeight = fontSize * (style.height ?? tokens.bodyHeight);

    return ExcludeSemantics(
      child: SweepShimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var line = 0; line < lines; line++)
              SizedBox(
                height: lineHeight,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: measureFraction,
                    child: SizedBox(
                      height: tokens.hairlineWidth,
                      child: ColoredBox(color: tokens.hairline),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
