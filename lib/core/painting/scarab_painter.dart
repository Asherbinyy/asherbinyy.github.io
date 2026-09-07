import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The indeterminate loader: Khepri rolling the sun.
///
/// `12-MOTIF-LIBRARY.md` #7. Section 11 rules out a spinner, and this replaces
/// the carrier waveform that stood in while the concept was signal — the last
/// visible piece of it on the site.
///
/// **The beetle is not drawn.** The loader is 32x12 logical pixels, and a
/// scarab at that size is mud rather than a sign; motif rule 2 is that flat
/// pigment and incised line beat detail that collapses. What is drawn is the
/// disc it rolls, on the ground it rolls along, turning as it travels — which
/// is the part that reads at this size and the part that means *becoming*.
class ScarabPainter extends CustomPainter {
  /// Holds [phase] at rest to render the settled state under reduced motion.
  const ScarabPainter({
    required this.phase,
    required this.colour,
    required this.strokeWidth,
    required this.textDirection,
  });

  /// Travel through one full crossing, 0..1.
  final double phase;

  /// Stroke colour, always resolved from the active palette by the caller.
  final Color colour;

  /// Stroke width, from the hairline token.
  final double strokeWidth;

  /// Reading direction; the sun travels start to end, never left to right.
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final radius = (size.height - strokeWidth) / 2;
    if (radius <= 0) return;

    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final ground = size.height - strokeWidth / 2;
    canvas.drawLine(Offset(0, ground), Offset(size.width, ground), paint);

    // Start to end, which is right to left in Arabic. The horizon it crosses
    // is the reader's, not the canvas's.
    final travel = size.width - radius * 2;
    final along = radius + travel * phase;
    final centreX = textDirection == TextDirection.rtl
        ? size.width - along
        : along;
    final centre = Offset(centreX, ground - radius);

    canvas.drawCircle(centre, radius, paint);

    // One spoke, turning at the rate a disc of this radius would actually turn
    // over the distance travelled. Without it the disc slides rather than
    // rolls, and sliding is not what the sign is about.
    if (radius <= strokeWidth) return;
    final turns = radius == 0 ? 0.0 : travel * phase / (2 * math.pi * radius);
    final angle =
        turns * 2 * math.pi * (textDirection == TextDirection.rtl ? -1 : 1);
    canvas.drawLine(
      centre,
      centre + Offset(math.cos(angle), math.sin(angle)) * radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(ScarabPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.colour != colour ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.textDirection != textDirection;
}
