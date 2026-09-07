import 'dart:math' as math;

/// The ankh, as stroked polylines in a square box.
///
/// The mark of the site from milestone 5. `12-MOTIF-LIBRARY.md` #4: the ankh
/// is life, and it replaces the waveform burst that stood for the mark while
/// the concept was signal telemetry.
///
/// Geometry lives here, once, because two things draw it and they must not
/// drift: `MarkPainter` renders it in the app, and `tool/generate_mark.dart`
/// emits `assets/brand/mark.svg` and the favicon set from the same strokes.
/// The previous mark had its curve written out twice — once in the painter and
/// once in the generator — and nothing would have caught the two disagreeing.
///
/// Returned as separate strokes rather than one path because an ankh is three
/// gestures: a loop, a crossbar and a stem. Joining them would draw a line
/// between the crossbar and the loop that is not part of the sign.
///
/// Deliberately free of any Flutter import. `tool/generate_mark.dart` is a
/// plain Dart script — it avoids `tokens.dart` precisely because that reaches
/// `material_ui` — so the shared geometry has to be reachable from a script
/// with no Flutter binding. Points are records rather than `Offset` for that
/// reason alone.
///
/// **Proportions are fixed here and nowhere else.** They were chosen for
/// legibility at 16px, where the loop is the first thing to collapse: it is
/// deliberately wider and shorter than a drawn-by-eye ankh so that its counter
/// survives at a favicon's size.
abstract final class AnkhGeometry {
  /// Centre of the loop, as a fraction of the box height.
  static const double _loopCentreY = 0.28;

  /// Loop width radius, as a fraction of the box.
  static const double _loopRadiusX = 0.155;

  /// Loop height radius, as a fraction of the box.
  static const double _loopRadiusY = 0.20;

  /// The crossbar's height, as a fraction of the box.
  static const double _crossbarY = 0.56;

  /// The crossbar's half-width, as a fraction of the box.
  static const double _crossbarHalfWidth = 0.34;

  /// How many segments approximate the loop.
  ///
  /// Forty-eight is smooth at 512px — the largest icon generated — and the
  /// rasteriser measures distance to the polyline, so more segments cost only
  /// generation time, never quality at small sizes.
  static const int _loopSegments = 48;

  /// The three strokes of the sign, in a [size] square inset by [strokeWidth].
  static List<List<MarkPoint>> strokes({
    required double size,
    required double strokeWidth,
  }) {
    final inset = strokeWidth / 2;
    final centreX = size / 2;
    final loopCentreY = size * _loopCentreY;
    final radiusX = size * _loopRadiusX;
    final radiusY = size * _loopRadiusY;
    final crossbarY = size * _crossbarY;
    final halfWidth = size * _crossbarHalfWidth;

    final loop = <MarkPoint>[
      for (var i = 0; i <= _loopSegments; i++)
        () {
          final angle = i / _loopSegments * 2 * math.pi;
          return (
            x: centreX + math.sin(angle) * radiusX,
            y: loopCentreY - math.cos(angle) * radiusY,
          );
        }(),
    ];

    return [
      loop,
      // The crossbar, then the stem from the loop's foot to the base. The stem
      // starts where the loop closes so the two read as one continuous sign
      // rather than a circle resting on a cross.
      [
        (x: centreX - halfWidth, y: crossbarY),
        (x: centreX + halfWidth, y: crossbarY),
      ],
      [(x: centreX, y: loopCentreY + radiusY), (x: centreX, y: size - inset)],
    ];
  }
}

/// A point on the mark, in the target box's pixel coordinates.
typedef MarkPoint = ({double x, double y});
