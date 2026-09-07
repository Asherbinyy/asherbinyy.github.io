import 'package:nocturne/core/painting/ankh_geometry.dart';

/// The Egyptian uniliteral signs this site draws.
///
/// A closed set. `12-MOTIF-LIBRARY.md` §2 permits exactly one piece of writing
/// on this site — the owner's name in a cartouche — and forbids inventing
/// glyphs or generating glyph strings as texture. These five signs spell that
/// name and nothing else is drawable.
///
/// Each is a real sign from Gardiner's list, drawn in a simplified geometric
/// form rather than traced from a carving: the same reduction a logotype makes
/// of a letterform. They are ornament with provenance, never a claim to be
/// epigraphy, and the Latin name is always present beside them.
enum EgyptianGlyph {
  /// N37, a pool. The sound š, as in *Sh*erbini.
  pool,

  /// D21, a mouth. The sound r.
  mouth,

  /// D58, a lower leg and foot. The sound b.
  foot,

  /// M17, a flowering reed. The sound i.
  reed,

  /// N35, a ripple of water. The sound n.
  water,
}

/// Vector forms for [EgyptianGlyph], as stroked polylines.
///
/// Same shape of API as the ankh geometry, and for the same reason: polylines
/// in a unit box, so one definition serves the painter and any build-time
/// generator without a Flutter import between them.
///
/// Every glyph is drawn inside a square box, on the assumption it will be
/// stroked. Proportions are set for legibility at small sizes, where a
/// hieroglyph's interior detail is the first thing to fill in: the pool gets
/// four interior strokes rather than the eight a carving would show, and the
/// water gets three crests rather than five.
abstract final class GlyphPaths {
  /// The name the cartouche spells, as its signs in reading order.
  ///
  /// š–r–b–i–n–i. The reed appears twice, which is correct: Egyptian wrote
  /// foreign names phonetically and repeated a sign wherever the sound
  /// repeated.
  static const List<EgyptianGlyph> sherbini = [
    EgyptianGlyph.pool,
    EgyptianGlyph.mouth,
    EgyptianGlyph.foot,
    EgyptianGlyph.reed,
    EgyptianGlyph.water,
    EgyptianGlyph.reed,
  ];

  /// The strokes of one sign, in a [size] square.
  static List<List<MarkPoint>> strokes(EgyptianGlyph glyph, double size) =>
      switch (glyph) {
        EgyptianGlyph.pool => _pool(size),
        EgyptianGlyph.mouth => _mouth(size),
        EgyptianGlyph.foot => _foot(size),
        EgyptianGlyph.reed => _reed(size),
        EgyptianGlyph.water => _water(size),
      };

  /// N37: a rectangular pool, hatched.
  ///
  /// Wider than tall and sitting on the baseline, which is how it is set in a
  /// line of signs.
  static List<List<MarkPoint>> _pool(double size) {
    final left = size * 0.06;
    final right = size * 0.94;
    final top = size * 0.34;
    final bottom = size * 0.66;

    return [
      [
        (x: left, y: top),
        (x: right, y: top),
        (x: right, y: bottom),
        (x: left, y: bottom),
        (x: left, y: top),
      ],
      // Interior hatching, four strokes. A carving shows more; at the sizes
      // this is drawn, more fills in and the sign reads as a solid bar.
      for (var i = 1; i <= 4; i++)
        [
          (x: left + (right - left) * i / 5, y: top),
          (x: left + (right - left) * i / 5, y: bottom),
        ],
    ];
  }

  /// D21: a mouth, as a horizontal lens.
  static List<List<MarkPoint>> _mouth(double size) {
    final left = size * 0.04;
    final right = size * 0.96;
    final centreY = size * 0.5;
    final rise = size * 0.17;

    return [
      [
        (x: left, y: centreY),
        ..._arc(left, right, centreY, -rise),
        (x: right, y: centreY),
        ..._arc(right, left, centreY, rise),
        (x: left, y: centreY),
      ],
    ];
  }

  /// D58: a lower leg and foot, striding right.
  static List<List<MarkPoint>> _foot(double size) {
    final shin = size * 0.36;
    final top = size * 0.08;
    final sole = size * 0.86;

    return [
      [(x: shin, y: top), (x: shin, y: sole), (x: size * 0.92, y: sole)],
      // The heel: a short return under the shin, which is what stops the sign
      // reading as a plain right angle.
      [(x: shin, y: sole), (x: size * 0.12, y: sole)],
    ];
  }

  /// M17: a flowering reed.
  static List<List<MarkPoint>> _reed(double size) {
    final stem = size * 0.5;

    return [
      [(x: stem, y: size * 0.2), (x: stem, y: size * 0.9)],
      // The flower: two short strokes opening from the top of the stem.
      [(x: stem, y: size * 0.24), (x: size * 0.2, y: size * 0.08)],
      [(x: stem, y: size * 0.24), (x: size * 0.8, y: size * 0.08)],
    ];
  }

  /// N35: a ripple of water.
  static List<List<MarkPoint>> _water(double size) {
    final left = size * 0.04;
    final right = size * 0.96;
    final centreY = size * 0.5;
    final rise = size * 0.11;
    const crests = 3;
    final step = (right - left) / (crests * 2);

    final points = <MarkPoint>[(x: left, y: centreY)];
    for (var i = 0; i < crests * 2; i++) {
      points.add((
        x: left + step * (i + 1),
        y: centreY + (i.isEven ? -rise : rise),
      ));
    }
    return [points];
  }

  /// Points along a shallow arc from one x to another, bowing by [rise].
  static List<MarkPoint> _arc(
    double fromX,
    double toX,
    double baseY,
    double rise,
  ) {
    const segments = 10;
    return [
      for (var i = 1; i < segments; i++)
        () {
          final t = i / segments;
          return (
            x: fromX + (toX - fromX) * t,
            // A parabola rather than a circular arc: it is one expression, it
            // meets the baseline exactly at both ends, and at these sizes the
            // difference is invisible.
            y: baseY + rise * 4 * t * (1 - t),
          );
        }(),
    ];
  }
}
