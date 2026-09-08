import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/glyph_paths.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// Draws the shaft of the obelisk, and the climb up it.
///
/// One painter for the whole game. `13-GAME-DESIGN.md` rules out an engine
/// package, and at this scale nothing is needed: the world is a list of boxes
/// and a point, and drawing it is a few dozen canvas calls.
class AscentPainter extends CustomPainter {
  /// Paints [world] in the palette it is handed.
  const AscentPainter({
    required this.world,
    required this.stone,
    required this.cracked,
    required this.gold,
    required this.wall,
    required this.strokeWidth,
    required this.isReducedMotion,
  });

  /// The world to draw.
  final AscentWorld world;

  /// Dressed stone.
  final Color stone;

  /// Weathered stone, and anything about to give way.
  final Color cracked;

  /// The climber, and the register bands.
  final Color gold;

  /// The shaft wall behind everything.
  final Color wall;

  /// Incised line weight.
  final double strokeWidth;

  /// Whether parallax and drift are suppressed.
  final bool isReducedMotion;

  /// How much of the frame sits below the climber.
  static const double _climberHeight = 0.62;

  /// Metres of shaft visible at once.
  static const double _visibleMetres = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final metresToPixels = size.height / _visibleMetres;
    // The camera holds the climber at a fixed height and moves the world, so
    // the ascent reads as travel rather than as a shrinking figure.
    final camera = world.climberY - _visibleMetres * (1 - _climberHeight);

    double screenY(double metres) =>
        size.height - (metres - camera) * metresToPixels;

    _paintWall(canvas, size, camera, metresToPixels, screenY);

    // Register bands: the altitude at which a fact is uncovered. Drawn behind
    // the ledges so a band never hides a foothold.
    final bands = Paint()
      ..color = gold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final firstBand =
        (camera / AscentWorld.registerGap).floor() * AscentWorld.registerGap;
    for (
      var metres = firstBand;
      metres < camera + _visibleMetres;
      metres += AscentWorld.registerGap
    ) {
      if (metres <= 0) continue;
      final y = screenY(metres);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bands);
    }

    for (final ledge in world.ledges) {
      final y = screenY(ledge.y);
      if (y < -size.height || y > size.height * 2) continue;
      _paintLedge(canvas, size, ledge, y);
    }

    _paintClimber(canvas, size, screenY(world.climberY));
  }

  /// The shaft wall: courses of stone, with inscription on some of them.
  void _paintWall(
    Canvas canvas,
    Size size,
    double camera,
    double metresToPixels,
    double Function(double) screenY,
  ) {
    final course = Paint()
      ..color = wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const courseMetres = 3.2;
    final first = (camera / courseMetres).floor() * courseMetres;
    for (
      var metres = first;
      metres < camera + _visibleMetres + courseMetres;
      metres += courseMetres
    ) {
      final y = screenY(metres);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), course);

      // A vertical joint, offset course to course, so the wall reads as
      // masonry rather than as ruled paper.
      final index = (metres / courseMetres).round();
      final offset = index.isEven ? 0.33 : 0.66;
      canvas.drawLine(
        Offset(size.width * offset, y),
        Offset(size.width * offset, y + courseMetres * metresToPixels),
        course,
      );

      // Inscription on every third course. Sparse on purpose: this is the
      // background of a game, and a wall of signs would compete with the
      // ledges the player actually has to read.
      if (index % 3 != 0) continue;
      final box = math.min(
        size.width * 0.05,
        courseMetres * metresToPixels / 3,
      );
      if (box <= 0) continue;
      final glyph =
          EgyptianGlyph.values[index.abs() % EgyptianGlyph.values.length];
      final path = Path();
      final origin = Offset(size.width * 0.08, y + box * 0.6);
      for (final stroke in GlyphPaths.strokes(glyph, box)) {
        path.moveTo(origin.dx + stroke.first.x, origin.dy + stroke.first.y);
        for (final point in stroke.skip(1)) {
          path.lineTo(origin.dx + point.x, origin.dy + point.y);
        }
      }
      canvas.drawPath(path, course);
    }
  }

  void _paintLedge(Canvas canvas, Size size, Ledge ledge, double y) {
    if (ledge.isBroken) return;

    final left = (ledge.x - ledge.width / 2) * size.width;
    final width = ledge.width * size.width;
    final height = math.max(strokeWidth * 3, size.height * 0.014);
    final rect = Rect.fromLTWH(left, y - height / 2, width, height);

    final colour = ledge.kind == LedgeKind.cracked ? cracked : stone;
    canvas
      ..drawRect(rect, Paint()..color = colour.withValues(alpha: 0.18))
      ..drawRect(
        rect,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );

    // A scarab ledge carries its sun, which is also the tell that it moves.
    if (ledge.kind != LedgeKind.scarab) return;
    canvas.drawCircle(
      rect.centerRight.translate(-height, 0),
      height * 0.6,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  void _paintClimber(Canvas canvas, Size size, double y) {
    final radius = math.max(strokeWidth * 3, size.width * 0.022);
    final centre = Offset(world.climberX * size.width, y - radius);

    // The climber is the sun being carried up. Filled, because it is the one
    // thing the player must never lose track of.
    canvas.drawCircle(centre, radius, Paint()..color = gold);

    if (isReducedMotion) return;
    // A short wake below, so upward travel is legible at speed.
    canvas.drawLine(
      centre,
      centre.translate(0, radius * 2.2),
      Paint()
        ..color = gold.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth * 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(AscentPainter oldDelegate) =>
      !identical(oldDelegate.world, world) ||
      oldDelegate.stone != stone ||
      oldDelegate.gold != gold ||
      oldDelegate.wall != wall ||
      oldDelegate.isReducedMotion != isReducedMotion;
}
