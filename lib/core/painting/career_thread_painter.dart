import 'package:material_ui/material_ui.dart';

/// The thread running down the career, drawn as far as the reader has got.
///
/// A plain connecting line is what every timeline on the web uses, and it says
/// nothing about this site. This is a **kheker frieze** — the bound reed
/// bundles that run along the top of a temple wall — turned on its side and
/// run down the column instead. It is the same vocabulary as the wall, the
/// cartouches and the stop marks, so the career reads as part of the building
/// rather than as a widget dropped into it.
///
/// It draws itself downward with the scroll. The motif is periodic, so the
/// progress is a length along the path rather than a count of anything: the
/// frieze is cut wherever the reader has reached, mid-bundle if that is where
/// they are.
class CareerThreadPainter extends CustomPainter {
  /// Draws [progress] of the frieze, from the top.
  const CareerThreadPainter({
    required this.progress,
    required this.colour,
    required this.accent,
    required this.strokeWidth,
  });

  /// How much of the thread has been drawn, 0 to 1.
  final double progress;

  /// The thread itself.
  final Color colour;

  /// The tie at each bundle, in the site's gold.
  final Color accent;

  /// Stroke weight, from the hairline token.
  final double strokeWidth;

  /// One reed bundle's height. Short enough that a stop of any length carries
  /// several, long enough that the shape is legible at a hairline.
  static const double period = 56;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0) return;

    final drawn = size.height * progress.clamp(0.0, 1.0);
    final centre = size.width / 2;
    final ink = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // The spine. Everything else hangs off it.
    canvas.drawLine(Offset(centre, 0), Offset(centre, drawn), ink);

    final tie = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // One bundle per period: two reeds springing from the spine and bending
    // back to it, bound at the waist.
    final reach = size.width * 0.34;
    for (var y = period / 2; y < drawn; y += period) {
      final top = y - period * 0.28;
      final bottom = y + period * 0.28;
      if (bottom > drawn) break;

      for (final side in [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(centre, top)
            ..quadraticBezierTo(centre + reach * side, y, centre, bottom),
          ink,
        );
      }
      // The binding: a short cross-stroke at the waist, in gold.
      canvas.drawLine(
        Offset(centre - reach * 0.34, y),
        Offset(centre + reach * 0.34, y),
        tie,
      );
    }
  }

  @override
  bool shouldRepaint(CareerThreadPainter old) =>
      old.progress != progress ||
      old.colour != colour ||
      old.accent != accent ||
      old.strokeWidth != strokeWidth;
}
