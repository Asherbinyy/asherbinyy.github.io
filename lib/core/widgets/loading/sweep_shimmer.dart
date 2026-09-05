import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';

/// The site's single shimmer treatment: one scan band crossing a surface.
///
/// Written rather than taken from the `shimmer` package, which section 11 rules
/// out because it ships its own colours, gradient angle and timing, none of
/// which come from `tokens.dart`. Renders [child] untouched when no
/// [SweepScope] is above it or when reduced motion has settled the sweep.
class SweepShimmer extends StatelessWidget {
  /// Wraps the surface being scanned.
  const SweepShimmer({required this.child, super.key});

  /// The surface the band passes over.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sweep = SweepScope.maybeOf(context);
    if (sweep == null) return child;

    final tokens = context.tokens;
    final direction = Directionality.of(context);
    final band = tokens.instrumentDim.withValues(alpha: tokens.sweepOpacity);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: sweep,
                builder: (context, _) => ShaderMask(
                  // The gradient supplies alpha only; dstIn keeps the band
                  // colour exactly where the gradient is opaque.
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) =>
                      _band(sweep.value)
                          .createShader(bounds, textDirection: direction),
                  child: ColoredBox(color: band),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Positions a soft-edged band of the specified width at [progress].
  ///
  /// The band starts fully off the start edge and ends fully off the end edge,
  /// so no partial band is ever parked at either boundary during the pause.
  static LinearGradient _band(double progress) {
    const half = Tokens.sweepWidthFraction / 2;
    final centre = -half + progress * (1 + Tokens.sweepWidthFraction);
    final start = (centre - half).clamp(0.0, 1.0);
    final end = (centre + half).clamp(0.0, 1.0);
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: const [Colors.transparent, Colors.black, Colors.transparent],
      stops: [start, centre.clamp(start, end), end],
    );
  }
}
