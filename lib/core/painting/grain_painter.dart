import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/station_seed.dart';

/// Static film grain over the page base.
///
/// Design-system section 2: 3% opacity in both themes, rendered once as a tiled
/// texture rather than per frame. This is what stops the dark theme reading as
/// flat default black. It never animates, so it has no reduced-motion path and
/// stays on when motion is disabled.
class GrainPainter extends CustomPainter {
  /// [colour] is the grain speck colour, already resolved from the palette.
  const GrainPainter({required this.colour, required this.opacity});

  /// Speck colour.
  final Color colour;

  /// Speck opacity; the design system fixes this at 3%.
  final double opacity;

  /// The tile is generated from a fixed seed so the texture is identical on
  /// every load and across both themes — grain that reshuffles between frames
  /// would be animation, which section 2 rules out.
  static const String _seed = 'nocturne.grain';

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final seed = StationSeed(_seed);
    final paint = Paint()..color = colour.withValues(alpha: opacity);
    // One tile's worth of specks, repeated across the surface. Generating per
    // pixel would cost more than the effect is worth at 3% opacity.
    final specks = <Offset>[
      for (var i = 0; i < Tokens.grainSpecks; i++)
        Offset(
          seed.nextRange(0, Tokens.grainTile),
          seed.nextRange(0, Tokens.grainTile),
        ),
    ];

    final columns = (size.width / Tokens.grainTile).ceil();
    final rows = (size.height / Tokens.grainTile).ceil();
    for (var column = 0; column < columns; column++) {
      for (var row = 0; row < rows; row++) {
        final origin = Offset(
          column * Tokens.grainTile,
          row * Tokens.grainTile,
        );
        for (final speck in specks) {
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + speck.dx,
              origin.dy + speck.dy,
              Tokens.hairlineWidth,
              Tokens.hairlineWidth,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(GrainPainter oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.opacity != opacity;
}
