import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/station_seed.dart';

/// The sheet the atlas is drawn on.
///
/// `12-MOTIF-LIBRARY.md` §1 item 9 specifies a papyrus ground for `/signal`
/// and it was never built, so the map rendered as pale wireframe on the page's
/// own background and read as a technical diagram rather than as a drawn
/// document.
///
/// **The sheet is texture and edge, not a colour.** The obvious way to make a
/// dark page look like papyrus is to put a cream rectangle on it, and
/// `01-DESIGN-SYSTEM.md` forbids that outright: four pigments, each with one
/// job, and no fifth hue introduced for any reason. So this takes
/// `surfaceRaised`, which is already the palette's raised surface, and does
/// the work with fibre and a deckled edge instead.
///
/// That turns out to be the better answer rather than the compromise. The
/// light palette's raised surface is already a warm cream, so the same code
/// draws stone-blue by lamplight in Kemet and actual papyrus in Deshret,
/// without a token that only one theme can use.
class PapyrusPainter extends CustomPainter {
  /// Paints a sheet in the palette it is handed.
  const PapyrusPainter({
    required this.sheet,
    required this.fibre,
    required this.edge,
    required this.hairlineWidth,
  });

  /// The body of the sheet.
  final Color sheet;

  /// The laid fibres, drawn over it.
  final Color fibre;

  /// The torn border.
  final Color edge;

  /// Incised line weight.
  final double hairlineWidth;

  /// Fibres across the sheet, each way.
  ///
  /// Papyrus is two layers of split reed laid at right angles, so the texture
  /// is a weave rather than a grain and both directions are needed. Counted
  /// rather than spaced, so the weave keeps its proportions at any size
  /// instead of getting denser as the map gets wider.
  static const int _fibresAcross = 34;
  static const int _fibresDown = 22;

  /// How far the torn edge wanders, as a fraction of the shorter side.
  static const double _deckle = 0.014;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final sheetPath = _sheetPath(size);
    canvas
      ..save()
      ..clipPath(sheetPath)
      ..drawPath(sheetPath, Paint()..color = sheet);

    _paintFibres(canvas, size);

    canvas
      ..restore()
      // The tear is drawn after the clip is lifted, so the line sits on the
      // boundary rather than being halved by it.
      ..drawPath(
        sheetPath,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = hairlineWidth,
      );
  }

  /// The sheet outline: a rectangle whose edges have been torn, not cut.
  ///
  /// Deterministic, because a deckle that reshuffles on every repaint would
  /// read as the page flickering. The seed is fixed rather than derived from
  /// the size, so resizing the window moves the tear smoothly instead of
  /// dealing a new one at every pixel.
  Path _sheetPath(Size size) {
    final random = StationSeed('papyrus');
    final wander = size.shortestSide * _deckle;
    final path = Path();

    // Walked as four edges of eight steps. Enough that the tear reads as
    // fibrous at a glance and few enough that it is still a straight edge.
    const steps = 8;
    var started = false;
    void walk(Offset from, Offset to, Offset inward) {
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final base = Offset.lerp(from, to, t)!;
        // The corners are pinned: a tear that wanders at the corner opens a
        // gap between two edges that are supposed to meet.
        final amount = (i == 0 || i == steps)
            ? 0.0
            : random.nextRange(0, wander);
        final point = base + inward * amount;
        if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
    }

    final topLeft = Offset(wander, wander);
    final topRight = Offset(size.width - wander, wander);
    final bottomRight = Offset(size.width - wander, size.height - wander);
    final bottomLeft = Offset(wander, size.height - wander);

    walk(topLeft, topRight, const Offset(0, 1));
    walk(topRight, bottomRight, const Offset(-1, 0));
    walk(bottomRight, bottomLeft, const Offset(0, -1));
    walk(bottomLeft, topLeft, const Offset(1, 0));
    path.close();
    return path;
  }

  /// The weave: split reed laid one way, then the other.
  void _paintFibres(Canvas canvas, Size size) {
    final random = StationSeed('papyrus.fibre');
    final paint = Paint()
      ..color = fibre
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < _fibresAcross; i++) {
      final x = size.width * i / _fibresAcross;
      // Varied weight and opacity, because a weave of identical lines is a
      // grid and reads as graph paper, which is the thing being replaced.
      paint
        ..strokeWidth = hairlineWidth * random.nextRange(0.6, 1.6)
        ..color = fibre.withValues(alpha: random.nextRange(0.25, 1) * fibre.a);
      canvas.drawLine(
        Offset(x + random.nextRange(-1, 1), 0),
        Offset(x + random.nextRange(-1, 1), size.height),
        paint,
      );
    }

    for (var i = 1; i < _fibresDown; i++) {
      final y = size.height * i / _fibresDown;
      paint
        ..strokeWidth = hairlineWidth * random.nextRange(0.6, 1.6)
        ..color = fibre.withValues(
          // The cross layer sits under the first, so it is drawn fainter.
          alpha: random.nextRange(0.18, 0.7) * fibre.a,
        );
      canvas.drawLine(
        Offset(0, y + random.nextRange(-1, 1)),
        Offset(size.width, y + random.nextRange(-1, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PapyrusPainter oldDelegate) =>
      oldDelegate.sheet != sheet ||
      oldDelegate.fibre != fibre ||
      oldDelegate.edge != edge ||
      oldDelegate.hairlineWidth != hairlineWidth;
}
