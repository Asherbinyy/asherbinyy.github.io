import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/papyrus_painter.dart';

/// A papyrus sheet caught part way through being rolled up.
///
/// The owner asked for the two figures on the home page to behave like a real
/// scroll: rolled closed on a click, open again when the pointer leaves or on
/// a second click. Not a card that fades, and not every card on the site —
/// these two.
///
/// The geometry is the whole illusion, so it is worth saying what it is. The
/// bottom edge lifts and winds upward, so what stays flat is the **top** of the
/// sheet and the cylinder travels up the card as it closes. Below the cylinder
/// there is nothing left to see. At full roll the cylinder has reached the top
/// and the sheet is wound into it.
///
/// Three things do the convincing, and all three are cheap:
///
/// 1. **The cylinder thickens.** A roll with one turn on it is thinner than a
///    roll with ten. Radius grows with the amount wound on, so the shape
///    changes as it travels rather than sliding up at a fixed size.
/// 2. **It is lit from above.** A dark underside, a light band a third of the
///    way down, and a darker line where the sheet enters the roll. Without the
///    gradient a cylinder reads as a flat bar.
/// 3. **The sheet bends into it.** A short shadow above the roll, so the flat
///    part appears to curve away rather than meeting the cylinder at a corner.
///
/// The sheet itself is [PapyrusPainter]'s job; this draws only the roll and
/// the shading around it, over the top of it.
class PapyrusRollPainter extends CustomPainter {
  /// Paints the roll at [roll], where 0 is flat and 1 is fully wound.
  const PapyrusRollPainter({
    required this.roll,
    required this.sheet,
    required this.fibre,
    required this.shadow,
    required this.hairlineWidth,
  });

  /// How far the sheet has been wound up, 0 to 1.
  final double roll;

  /// The body of the sheet, which is also the lit face of the cylinder.
  final Color sheet;

  /// The laid fibres, reused for the wound turns.
  final Color fibre;

  /// Cast shadow and the cylinder's underside.
  final Color shadow;

  /// Incised line weight.
  final double hairlineWidth;

  /// How thick the finished roll is, against the card's height.
  ///
  /// A roll of a short sheet is a thin one. Tying this to height rather than
  /// choosing a number keeps the proportion right on both cards and at any
  /// text scale.
  static const double _maxRadiusFraction = 0.22;

  /// How far the bend above the roll reaches, in radii.
  static const double _bendReach = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || roll <= 0) return;

    final maxRadius = size.height * _maxRadiusFraction;
    // Square-rooted: the first turn adds most of the thickness, the tenth adds
    // very little, which is how winding actually behaves.
    final radius = maxRadius * math.sqrt(roll.clamp(0, 1));
    final exposed = size.height * (1 - roll);

    _paintBend(canvas, size, exposed, radius);
    _paintCylinder(canvas, size, exposed, radius);
  }

  /// The sheet curving away as it enters the roll.
  void _paintBend(Canvas canvas, Size size, double exposed, double radius) {
    final reach = radius * _bendReach;
    if (reach <= 0) return;
    final top = math.max(0, exposed - reach).toDouble();
    final rect = Rect.fromLTRB(0, top, size.width, exposed);
    if (rect.isEmpty) return;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shadow.withValues(alpha: 0), shadow.withValues(alpha: 0.55)],
        ).createShader(rect),
    );
  }

  /// The roll itself.
  void _paintCylinder(Canvas canvas, Size size, double exposed, double radius) {
    if (radius <= 0) return;
    final rect = Rect.fromLTRB(
      -hairlineWidth,
      exposed - radius,
      size.width + hairlineWidth,
      exposed + radius,
    );
    final rounded = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Under the roll, so it sits on the card rather than floating over it.
    canvas
      ..drawRRect(
        rounded.shift(Offset(0, radius * 0.22)),
        Paint()
          ..color = shadow.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
      )
      ..drawRRect(
        rounded,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(sheet, shadow, 0.45)!,
              Color.lerp(sheet, shadow, 0.05)!,
              sheet,
              Color.lerp(sheet, shadow, 0.62)!,
            ],
            stops: const [0, 0.28, 0.42, 1],
          ).createShader(rect),
      );

    // A couple of wound turns, so the cylinder reads as sheet rather than
    // dowel. Drawn only once there is room for them to be distinct.
    if (radius > hairlineWidth * 6) {
      final turns = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hairlineWidth
        ..color = fibre.withValues(alpha: 0.7);
      for (final at in const [0.34, 0.62]) {
        final y = rect.top + rect.height * at;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), turns);
      }
    }

    // The cut end of the roll, catching the light.
    canvas.drawLine(
      Offset(rect.left, exposed - radius * 0.34),
      Offset(rect.right, exposed - radius * 0.34),
      Paint()
        ..strokeWidth = hairlineWidth
        ..color = sheet,
    );
  }

  @override
  bool shouldRepaint(PapyrusRollPainter old) =>
      old.roll != roll ||
      old.sheet != sheet ||
      old.fibre != fibre ||
      old.shadow != shadow;
}
