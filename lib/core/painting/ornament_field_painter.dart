import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/ornament_paths.dart';
import 'package:nocturne/core/painting/station_seed.dart';

/// A field of inscription behind a page.
///
/// `12-MOTIF-LIBRARY.md` #16 and §4: every route carries a background of
/// low-contrast signs, and it is the single largest performance risk in the
/// redesign. A viewport of glyph paths rebuilt every frame would cost more
/// than the wall and the atlas together.
///
/// So one tile is recorded to a [ui.Picture] once, keyed by the values that
/// change it, and replayed across the surface. Replaying a picture is a
/// display-list copy; rebuilding the paths is not.
///
/// **Nothing in this field is writing.** It used to be: the tile picked at
/// random from the Egyptian uniliteral signs, which are letters, and scattered
/// them. The defence written here was that a grid reads as ornament where a
/// line would read as a sentence, and that was wrong. Random letters are
/// random letters at any spacing, and a reader who knows the signs sees
/// nonsense laid out as decoration.
///
/// It draws [Ornament] now: kheker cresting, block borders, coils, rosettes
/// and lotus buds, which are decoration in the record rather than language.
/// Repeating them says nothing because there is nothing there to say.
class OrnamentFieldPainter extends CustomPainter {
  /// [seed] varies the arrangement per route so navigation is legible at a
  /// glance; [colour] and [opacity] come from the palette.
  OrnamentFieldPainter({
    required this.seed,
    required this.colour,
    required this.opacity,
    required this.hairlineWidth,
  });

  /// Distinguishes one route's field from another's.
  final String seed;

  /// Sign colour, before [opacity].
  final Color colour;

  /// Field opacity. The design system fixes this at 4%, one step above the
  /// texture beneath it so the two read as separate layers rather than mud.
  final double opacity;

  /// Stroke weight for the signs.
  final double hairlineWidth;

  /// Tile edge in logical pixels.
  static const double tile = 168;

  /// Signs per tile edge.
  static const int _perEdge = 2;

  /// Cached tiles, one per distinct field.
  ///
  /// Static because the same field is painted on every scroll frame and often
  /// on more than one layer at once; rebuilding it per painter instance would
  /// defeat the point of recording it at all.
  static final Map<String, ui.Picture> _tiles = {};

  /// Clears the cache. For tests, which construct many palettes in one run.
  @visibleForTesting
  static void clearCache() => _tiles.clear();

  /// How many distinct fields have been recorded.
  @visibleForTesting
  static int get cacheSize => _tiles.length;

  String get _key => '$seed|${colour.toARGB32()}|$opacity|$hairlineWidth';

  ui.Picture _tilePicture() => _tiles.putIfAbsent(_key, () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = StationSeed(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairlineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colour.withValues(alpha: opacity);

    const cell = tile / _perEdge;
    const glyphBox = cell * 0.46;
    final path = Path();

    for (var row = 0; row < _perEdge; row++) {
      for (var column = 0; column < _perEdge; column++) {
        // The sign is chosen by the seed, its position jittered within its own
        // cell. The jitter is what stops a 2x2 tile reading as a chequerboard
        // once it repeats across a viewport; it is deterministic, so the field
        // is identical on every load.
        final ornament =
            Ornament.values[random.nextInt(Ornament.values.length)];
        final originX =
            column * cell + (cell - glyphBox) / 2 + random.nextRange(-6, 6);
        final originY =
            row * cell + (cell - glyphBox) / 2 + random.nextRange(-6, 6);

        for (final stroke in OrnamentPaths.strokes(ornament, glyphBox)) {
          path.moveTo(originX + stroke.first.x, originY + stroke.first.y);
          for (final point in stroke.skip(1)) {
            path.lineTo(originX + point.x, originY + point.y);
          }
        }
      }
    }
    canvas.drawPath(path, paint);
    return recorder.endRecording();
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final picture = _tilePicture();
    final columns = (size.width / tile).ceil();
    final rows = (size.height / tile).ceil();

    canvas.save();
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        canvas
          ..save()
          ..translate(column * tile, row * tile)
          ..drawPicture(picture)
          ..restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OrnamentFieldPainter oldDelegate) =>
      oldDelegate._key != _key;
}
