import 'dart:math' as math;

import 'package:nocturne/core/painting/ankh_geometry.dart';

/// The decorative motifs this site scatters as pattern.
///
/// A closed set, and deliberately **not writing**. The site used to fill its
/// backgrounds, cards, wall and game shaft by picking at random from the
/// Egyptian uniliteral signs — the phonetic alphabet — and drawing the result.
/// Those are letters. Chosen at random and set in a row they spell nothing, in
/// the same way a wall of random Latin characters spells nothing, and anyone
/// who reads them sees that immediately. `12-MOTIF-LIBRARY.md` §2 had forbidden
/// exactly this in writing, and four painters did it anyway.
///
/// These are the alternative: bands and fillers taken from Egyptian
/// architectural decoration rather than from the writing system. A kheker
/// frieze, a block border, a running spiral, a rosette and a lotus band are
/// ornament in the record itself, on ceilings and wall crestings, carrying no
/// sound and forming no word. Repeating them says nothing because there is
/// nothing there to say.
enum Ornament {
  /// The bundled-reed cresting that runs along the top of a wall.
  kheker,

  /// A chequered band, the standard border under a cornice.
  blockBorder,

  /// A running spiral, from painted ceiling patterns.
  coil,

  /// A many-petalled flower, from ceilings and broad collars.
  rosette,

  /// A lotus bud on its stem, the common frieze filler.
  lotus,
}

/// Vector forms for [Ornament], as stroked polylines.
///
/// Same shape of API as the glyph and ankh geometry it replaces, so the
/// painters that draw it needed a one-line change: polylines in a unit box,
/// with no Flutter import, so one definition serves every painter and any
/// build-time generator.
///
/// Every motif is drawn inside a square box on the assumption it will be
/// stroked, and each is reduced to the fewest strokes that still read at the
/// sizes these are drawn: a background tile puts them at a few tens of pixels,
/// where interior detail fills in and turns any shape into a blot.
abstract final class OrnamentPaths {
  /// The strokes of one motif, in a [size] square.
  static List<List<MarkPoint>> strokes(Ornament ornament, double size) =>
      switch (ornament) {
        Ornament.kheker => _kheker(size),
        Ornament.blockBorder => _blockBorder(size),
        Ornament.coil => _coil(size),
        Ornament.rosette => _rosette(size),
        Ornament.lotus => _lotus(size),
      };

  /// A kheker: a bound bundle of reeds, splayed at the top.
  ///
  /// The waist bands are the binding, and they are what stops this reading as
  /// a plant. Two of them, because at a background tile's size three merge
  /// into a block.
  static List<List<MarkPoint>> _kheker(double size) {
    final centre = size * 0.5;

    return [
      [(x: centre, y: size * 0.40), (x: centre, y: size * 0.96)],
      for (final y in [0.44, 0.53])
        [(x: size * 0.28, y: size * y), (x: size * 0.72, y: size * y)],
      // The splay: three fronds opening from the top of the bundle.
      [(x: centre, y: size * 0.40), (x: size * 0.16, y: size * 0.08)],
      [(x: centre, y: size * 0.40), (x: centre, y: size * 0.02)],
      [(x: centre, y: size * 0.40), (x: size * 0.84, y: size * 0.08)],
    ];
  }

  /// A block border: a banded chequer, two courses deep.
  ///
  /// Two rows rather than one, which is the whole difference between this and
  /// a hatched rectangle. A single row of dividers is the pool sign, and this
  /// set exists precisely so that nothing here is a sign.
  static List<List<MarkPoint>> _blockBorder(double size) {
    final left = size * 0.06;
    final right = size * 0.94;
    final top = size * 0.28;
    final bottom = size * 0.72;
    final middle = (top + bottom) / 2;

    return [
      [
        (x: left, y: top),
        (x: right, y: top),
        (x: right, y: bottom),
        (x: left, y: bottom),
        (x: left, y: top),
      ],
      [(x: left, y: middle), (x: right, y: middle)],
      for (var i = 1; i <= 2; i++)
        [
          (x: left + (right - left) * i / 3, y: top),
          (x: left + (right - left) * i / 3, y: bottom),
        ],
    ];
  }

  /// A running spiral, drawn as one open coil.
  ///
  /// An Archimedean spiral rather than a circular one: the gap between turns
  /// stays even, which is what a painted coil border does and what a circular
  /// approximation visibly fails to do.
  static List<List<MarkPoint>> _coil(double size) {
    const turns = 1.75;
    const segments = 26;
    final centre = size * 0.5;
    final inner = size * 0.06;
    final outer = size * 0.42;

    return [
      [
        for (var i = 0; i <= segments; i++)
          () {
            final t = i / segments;
            final angle = t * turns * 2 * math.pi;
            final radius = inner + (outer - inner) * t;
            return (
              x: centre + math.cos(angle) * radius,
              y: centre + math.sin(angle) * radius,
            );
          }(),
      ],
    ];
  }

  /// A rosette: a ring of petals around an open centre.
  ///
  /// Eight petals, as short radial strokes rather than outlined shapes. An
  /// outlined petal at this scale is two strokes a pixel apart and renders as
  /// one thick one, so the outline costs draw calls and buys nothing.
  static List<List<MarkPoint>> _rosette(double size) {
    const petals = 8;
    const segments = 12;
    final centre = size * 0.5;
    final hub = size * 0.11;
    final tip = size * 0.44;

    return [
      [
        for (var i = 0; i <= segments; i++)
          () {
            final angle = i / segments * 2 * math.pi;
            return (
              x: centre + math.cos(angle) * hub,
              y: centre + math.sin(angle) * hub,
            );
          }(),
      ],
      for (var i = 0; i < petals; i++)
        () {
          final angle = i / petals * 2 * math.pi;
          return [
            (
              x: centre + math.cos(angle) * hub * 1.3,
              y: centre + math.sin(angle) * hub * 1.3,
            ),
            (
              x: centre + math.cos(angle) * tip,
              y: centre + math.sin(angle) * tip,
            ),
          ];
        }(),
    ];
  }

  /// A lotus bud on its stem, with two sepals.
  static List<List<MarkPoint>> _lotus(double size) {
    final centre = size * 0.5;
    final shoulder = size * 0.52;

    return [
      [(x: centre, y: shoulder), (x: centre, y: size * 0.98)],
      // The bud, as a closed teardrop: up one side to the point and down the
      // other.
      [
        (x: centre, y: shoulder),
        (x: size * 0.26, y: size * 0.34),
        (x: size * 0.40, y: size * 0.06),
        (x: centre, y: size * 0.02),
        (x: size * 0.60, y: size * 0.06),
        (x: size * 0.74, y: size * 0.34),
        (x: centre, y: shoulder),
      ],
      // Sepals, one either side of the stem where the bud sits on it.
      [(x: centre, y: shoulder), (x: size * 0.18, y: size * 0.44)],
      [(x: centre, y: shoulder), (x: size * 0.82, y: size * 0.44)],
    ];
  }
}
