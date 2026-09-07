import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/glyph_paths.dart';

/// A cartouche: the owner's name enclosed, in the signs a scribe would use.
///
/// `12-MOTIF-LIBRARY.md` #1 and §2. The cartouche is the one place this site
/// spells anything in glyphs, and it spells one name.
///
/// The signs are the Egyptian uniliteral alphabet — the phonetic set scribes
/// themselves used for foreign names. Ptolemaic cartouches spell *Ptolemy* and
/// *Cleopatra* this way, so transliterating a modern name with them is the
/// historically correct practice rather than a pastiche of one.
///
/// **This is not a generator.** It draws [GlyphPaths.sherbini] and there is no
/// parameter for other text, deliberately: a cartouche that accepts a string
/// is a machine for producing plausible-looking nonsense, and this site's
/// whole argument is that nothing on it is invented.
class CartouchePainter extends CustomPainter {
  /// [strokeWidth] should come from the type scale around it, so the sign
  /// weight matches the name set beside it.
  const CartouchePainter({
    required this.colour,
    required this.glyphColour,
    required this.strokeWidth,
  });

  /// The enclosing loop and its tie bar.
  final Color colour;

  /// The signs inside. Usually a step quieter than the loop, so the shape
  /// reads first and the detail second.
  final Color glyphColour;

  /// Stroke width for both.
  final double strokeWidth;

  /// The signs this cartouche encloses.
  static const List<EgyptianGlyph> glyphs = GlyphPaths.sherbini;

  /// Aspect ratio the cartouche wants, given its six signs.
  ///
  /// Declared so a caller can size a box before the painter runs, which is
  /// what stops the name treatment shifting the header on first paint.
  static const double aspectRatio = 4.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colour;

    final inset = strokeWidth / 2;
    final height = size.height - strokeWidth;
    final radius = height / 2;
    // The tie bar closes the loop at the trailing end. On a royal cartouche it
    // is the knot in the rope; here it is what stops the shape reading as a
    // pill button.
    final barX = size.width - inset - strokeWidth * 1.5;

    final loop = RRect.fromLTRBR(
      inset,
      inset,
      barX,
      inset + height,
      Radius.circular(radius),
    );
    canvas
      ..drawRRect(loop, paint)
      // Short, so it reads as tangent to the loop rather than as a bar
      // floating beside it. A longer line only touches the curve at its
      // midpoint and the gap at either end is what makes it look detached.
      ..drawLine(
        Offset(barX, inset + height * 0.3),
        Offset(barX, inset + height * 0.7),
        paint,
      );

    // The signs, evenly spaced and centred in the loop's straight section.
    // The rounded ends cannot hold a glyph, so the usable run is the loop
    // minus one radius at each end; centring within that is what stops the
    // row drifting toward the tie bar.
    final runStart = inset + radius * 0.7;
    final runEnd = barX - radius * 0.7;
    final cell = (runEnd - runStart) / glyphs.length;
    final glyphBox = math.min(cell * 0.86, height * 0.66);
    final baseline = inset + (height - glyphBox) / 2;
    final glyphPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glyphColour;

    final path = Path();
    for (var i = 0; i < glyphs.length; i++) {
      final originX = runStart + cell * i + (cell - glyphBox) / 2;
      for (final stroke in GlyphPaths.strokes(glyphs[i], glyphBox)) {
        path.moveTo(originX + stroke.first.x, baseline + stroke.first.y);
        for (final point in stroke.skip(1)) {
          path.lineTo(originX + point.x, baseline + point.y);
        }
      }
    }
    canvas.drawPath(path, glyphPaint);
  }

  @override
  bool shouldRepaint(CartouchePainter oldDelegate) =>
      oldDelegate.colour != colour ||
      oldDelegate.glyphColour != glyphColour ||
      oldDelegate.strokeWidth != strokeWidth;
}
