import 'dart:typed_data';
import 'dart:ui';

/// Recognisable Egyptian signs, as filled silhouettes.
///
/// These are **symbols, not spelling.** `12-MOTIF-LIBRARY.md` §2 forbids
/// scattering the uniliteral alphabet as decoration, and it is right to: those
/// are letters, and a wall of random letters is visible nonsense to anyone who
/// reads them. Nothing here is a letter. An ankh, a scarab, a djed pillar and
/// a wedjat eye are ideograms — life, becoming, stability, protection — each
/// complete on its own, the way a cross or an anchor is. Set one to a block and
/// the wall says nothing it did not mean to.
///
/// Every sign is drawn inside the unit square and closed, so a painter can
/// scale it to a block and fill it. Curves rather than polylines: at the size
/// these are drawn a silhouette has to have a real edge, and the strokes the
/// wall used before read as wireframe.
enum Sign {
  /// Life. The loop, the crossbar and the stem.
  ankh,

  /// Khepri, the beetle: becoming, the morning sun rolled over the horizon.
  scarab,

  /// The pillar of Osiris: stability. Four crossbars on a shaft.
  djed,

  /// The wedjat, the eye of Horus: protection and wholeness.
  eye,

  /// Horus as a falcon, standing.
  falcon,

  /// A seated figure, the determinative for a person.
  seated,

  /// The feather of Maat: truth, and the counterweight of the heart.
  feather,

  /// Ra's disc.
  sun,

  /// Water, three ripples.
  water,

  /// The offering loaf on its mat.
  offering,
}

/// Closed outlines for [Sign], in a unit box.
abstract final class SignPaths {
  /// The silhouette for [sign], scaled to a [size] square.
  static Path of(Sign sign, double size) {
    final path = switch (sign) {
      Sign.ankh => _ankh(),
      Sign.scarab => _scarab(),
      Sign.djed => _djed(),
      Sign.eye => _eye(),
      Sign.falcon => _falcon(),
      Sign.seated => _seated(),
      Sign.feather => _feather(),
      Sign.sun => _sun(),
      Sign.water => _water(),
      Sign.offering => _offering(),
    };
    return path.transform(Matrix4Scale(size).storage);
  }

  /// Life: an oval loop over a crossbar and a stem.
  static Path _ankh() {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      // The loop, and its hole.
      ..addOval(const Rect.fromLTRB(0.33, 0.02, 0.67, 0.36))
      ..addOval(const Rect.fromLTRB(0.40, 0.09, 0.60, 0.29))
      // The crossbar.
      ..addRect(const Rect.fromLTRB(0.12, 0.38, 0.88, 0.48))
      // The stem.
      ..addRect(const Rect.fromLTRB(0.43, 0.38, 0.57, 0.98));
    return path;
  }

  /// The beetle: a domed body, a clypeus, and legs out to the sides.
  static Path _scarab() {
    final path = Path()
      ..addOval(const Rect.fromLTRB(0.26, 0.22, 0.74, 0.92))
      // Head plate.
      ..moveTo(0.34, 0.26)
      ..cubicTo(0.36, 0.10, 0.64, 0.10, 0.66, 0.26)
      ..close()
      // Forelegs.
      ..moveTo(0.28, 0.34)
      ..lineTo(0.06, 0.20)
      ..lineTo(0.10, 0.15)
      ..lineTo(0.32, 0.30)
      ..close()
      ..moveTo(0.72, 0.34)
      ..lineTo(0.94, 0.20)
      ..lineTo(0.90, 0.15)
      ..lineTo(0.68, 0.30)
      ..close()
      // Hind legs.
      ..moveTo(0.28, 0.70)
      ..lineTo(0.08, 0.86)
      ..lineTo(0.12, 0.91)
      ..lineTo(0.32, 0.76)
      ..close()
      ..moveTo(0.72, 0.70)
      ..lineTo(0.92, 0.86)
      ..lineTo(0.88, 0.91)
      ..lineTo(0.68, 0.76)
      ..close();
    return path;
  }

  /// Stability: a shaft under four stacked crossbars.
  static Path _djed() {
    final path = Path()..addRect(const Rect.fromLTRB(0.40, 0.30, 0.60, 0.96));
    for (var i = 0; i < 4; i++) {
      final top = 0.06 + i * 0.065;
      path.addRect(Rect.fromLTRB(0.22, top, 0.78, top + 0.042));
    }
    // The flared base.
    path.addRect(const Rect.fromLTRB(0.32, 0.88, 0.68, 0.96));
    return path;
  }

  /// The wedjat: the eye, its brow, the curl and the teardrop.
  static Path _eye() {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      // Brow.
      ..moveTo(0.14, 0.30)
      ..cubicTo(0.34, 0.12, 0.72, 0.12, 0.92, 0.24)
      ..lineTo(0.90, 0.32)
      ..cubicTo(0.70, 0.22, 0.36, 0.22, 0.18, 0.37)
      ..close()
      // The eye itself.
      ..moveTo(0.12, 0.52)
      ..cubicTo(0.30, 0.34, 0.72, 0.34, 0.92, 0.50)
      ..cubicTo(0.72, 0.66, 0.30, 0.66, 0.12, 0.52)
      ..close()
      // Pupil, cut out.
      ..addOval(const Rect.fromLTRB(0.44, 0.42, 0.60, 0.58))
      // The teardrop under the eye.
      ..moveTo(0.40, 0.62)
      ..lineTo(0.34, 0.92)
      ..lineTo(0.46, 0.90)
      ..lineTo(0.48, 0.62)
      ..close()
      // The curl.
      ..moveTo(0.62, 0.62)
      ..cubicTo(0.86, 0.66, 0.92, 0.86, 0.72, 0.92)
      ..lineTo(0.70, 0.84)
      ..cubicTo(0.82, 0.81, 0.79, 0.72, 0.62, 0.70)
      ..close();
    return path;
  }

  /// Horus standing: head, breast, folded wing, tail and legs.
  static Path _falcon() {
    final path = Path()
      ..moveTo(0.44, 0.06)
      ..cubicTo(0.58, 0.04, 0.64, 0.14, 0.62, 0.22)
      // Beak.
      ..lineTo(0.76, 0.26)
      ..lineTo(0.60, 0.30)
      // Breast down to the feet.
      ..cubicTo(0.60, 0.46, 0.56, 0.60, 0.52, 0.76)
      ..lineTo(0.56, 0.82)
      ..lineTo(0.40, 0.82)
      // Tail sweeping back.
      ..lineTo(0.18, 0.74)
      ..lineTo(0.22, 0.64)
      // Folded wing, back up to the head.
      ..cubicTo(0.30, 0.56, 0.34, 0.36, 0.38, 0.20)
      ..close()
      // Legs.
      ..addRect(const Rect.fromLTRB(0.42, 0.82, 0.47, 0.95))
      ..addRect(const Rect.fromLTRB(0.50, 0.82, 0.55, 0.95))
      // Perch.
      ..addRect(const Rect.fromLTRB(0.30, 0.95, 0.68, 0.99));
    return path;
  }

  /// A seated figure, knees drawn up.
  static Path _seated() {
    final path = Path()
      ..addOval(const Rect.fromLTRB(0.34, 0.06, 0.54, 0.26))
      // Back and thigh.
      ..moveTo(0.34, 0.28)
      ..cubicTo(0.28, 0.44, 0.26, 0.62, 0.26, 0.76)
      ..lineTo(0.74, 0.76)
      ..lineTo(0.74, 0.66)
      ..lineTo(0.46, 0.66)
      ..cubicTo(0.48, 0.52, 0.52, 0.38, 0.54, 0.28)
      ..close()
      // Shin, folded under.
      ..addRect(const Rect.fromLTRB(0.26, 0.78, 0.78, 0.86));
    return path;
  }

  /// Maat's plume.
  static Path _feather() {
    return Path()
      ..moveTo(0.50, 0.02)
      ..cubicTo(0.74, 0.20, 0.76, 0.52, 0.60, 0.78)
      ..lineTo(0.56, 0.98)
      ..lineTo(0.44, 0.98)
      ..lineTo(0.40, 0.78)
      ..cubicTo(0.24, 0.52, 0.26, 0.20, 0.50, 0.02)
      ..close();
  }

  /// Ra: a disc with its ring.
  static Path _sun() {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(const Rect.fromLTRB(0.16, 0.16, 0.84, 0.84))
      ..addOval(const Rect.fromLTRB(0.30, 0.30, 0.70, 0.70));
  }

  /// Water: three ripples.
  static Path _water() {
    final path = Path();
    for (var row = 0; row < 3; row++) {
      final y = 0.24 + row * 0.24;
      path
        ..moveTo(0.08, y)
        ..cubicTo(0.24, y - 0.09, 0.36, y + 0.09, 0.50, y)
        ..cubicTo(0.64, y - 0.09, 0.76, y + 0.09, 0.92, y)
        ..lineTo(0.92, y + 0.07)
        ..cubicTo(0.76, y + 0.16, 0.64, y - 0.02, 0.50, y + 0.07)
        ..cubicTo(0.36, y + 0.16, 0.24, y - 0.02, 0.08, y + 0.07)
        ..close();
    }
    return path;
  }

  /// A loaf on its mat.
  static Path _offering() {
    return Path()
      ..moveTo(0.22, 0.56)
      ..cubicTo(0.22, 0.30, 0.78, 0.30, 0.78, 0.56)
      ..close()
      ..addRect(const Rect.fromLTRB(0.10, 0.60, 0.90, 0.70))
      ..addRect(const Rect.fromLTRB(0.30, 0.70, 0.70, 0.78));
  }
}

/// A scale-only transform, without pulling in `vector_math`.
///
/// `Path.transform` wants a 4x4 column-major matrix and the painting layer has
/// no reason to depend on a maths package to produce one.
final class Matrix4Scale {
  /// Uniform scale by [scale].
  Matrix4Scale(this.scale);

  /// The factor applied to x and y.
  final double scale;

  /// Column-major 4x4, as `Path.transform` expects.
  Float64List get storage => Float64List.fromList(<double>[
    scale, 0, 0, 0, //
    0, scale, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1,
  ]);
}

/// Signs in a fixed order, for seeded selection.
const List<Sign> signOrder = Sign.values;
