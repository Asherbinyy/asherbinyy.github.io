import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_wave.dart';

/// Draws the carrier waveform miniature used by the indeterminate loader.
///
/// Section 11 rules out a spinner and specifies this instead: the same curve as
/// the main trace at loader scale, so it costs one polyline and reads as part
/// of the instrument rather than a borrowed widget.
class CarrierPainter extends CustomPainter {
  /// Holds [phase] at rest to render the settled state under reduced motion.
  const CarrierPainter({
    required this.phase,
    required this.colour,
    required this.strokeWidth,
    required this.textDirection,
    this.burstCentre,
  });

  /// Travel through one full cycle, 0..1.
  final double phase;

  /// Where the burst swells, 0..1 across the width.
  ///
  /// Null is the carrier at rest, which is what empty states show: section 6
  /// describes the baseline as a low-amplitude carrier, so a burst parked at
  /// the start edge would misreport a signal that is not there.
  final double? burstCentre;

  /// Stroke colour, always resolved from the active palette by the caller.
  final Color colour;

  /// Stroke width, from the hairline token.
  final double strokeWidth;

  /// Reading direction; the carrier travels start to end, never left to right.
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    // Nothing to draw, and the sample loop would divide by zero.
    if (size.isEmpty) return;

    final amplitude = (size.height - strokeWidth) / 2;
    final centreY = size.height / 2;
    // One sample per logical pixel: the curve is smooth at this scale and the
    // loader is small, so a denser path would cost frames for no visible gain.
    final samples = size.width.ceil();
    final path = Path();

    final centre = burstCentre;
    for (var i = 0; i <= samples; i++) {
      final position = i / samples;
      final value = centre == null
          ? CarrierWave.sample(position: position, phase: phase) *
                Tokens.carrierRestAmplitude
          : CarrierWave.burst(position: position, phase: phase, centre: centre);
      final travelled = textDirection == TextDirection.rtl
          ? 1 - position
          : position;
      final point = Offset(travelled * size.width, centreY - value * amplitude);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CarrierPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.colour != colour ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.burstCentre != burstCentre;
}
