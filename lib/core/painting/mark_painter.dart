import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_wave.dart';

/// The mark: one waveform burst, frozen at its peak.
///
/// Design-system section 12 requires the mark to be a frame lifted from the
/// trace's own curve rather than designed independently, so that the two can
/// never drift. It samples [CarrierWave.burstEnvelope] directly — a single
/// positive lobe on a flat baseline, two curves, which is what keeps it legible
/// down to 16px where a busier shape collapses into noise.
///
/// Task 1.6b exports `assets/brand/mark.svg` and the favicon set from this same
/// function rather than tracing this painter by hand.
class MarkPainter extends CustomPainter {
  /// [strokeWidth] normally comes from [strokeFor] so the mark keeps its
  /// specified weight at whatever size it is drawn.
  const MarkPainter({required this.colour, required this.strokeWidth});

  /// The specified stroke, scaled from the mark's native square.
  ///
  /// Section 12 fixes it at 2px on a 32px mark; the header draws it at 24px,
  /// and the favicon set at four more sizes, all from this one ratio.
  static double strokeFor(double size) =>
      size / Tokens.markNativeSize * Tokens.markStroke;

  /// The mark is the one place amber appears with no content around it.
  final Color colour;

  /// Stroke width at the rendered size.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final amplitude = size.height - strokeWidth;
    final baseline = size.height - strokeWidth / 2;
    final samples = size.width.ceil();
    final path = Path();

    // The window spans the burst plus the flat carrier either side of it, so
    // the mark reads as a burst on a line rather than as a bare hill.
    const span = Tokens.carrierBurstWidth * Tokens.markCurveSigmas * 2;
    const start = 0.5 - span / 2;

    for (var i = 0; i <= samples; i++) {
      final fraction = i / samples;
      final lobe = CarrierWave.burstEnvelope(
        position: start + fraction * span,
        centre: 0.5,
      );
      final point = Offset(fraction * size.width, baseline - lobe * amplitude);
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
  bool shouldRepaint(MarkPainter oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.strokeWidth != strokeWidth;
}
