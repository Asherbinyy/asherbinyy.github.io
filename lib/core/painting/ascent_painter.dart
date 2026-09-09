import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:nocturne/core/painting/ornament_paths.dart';
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
    required this.entrance,
    required this.stone,
    required this.cracked,
    required this.gold,
    required this.glow,
    required this.wall,
    required this.strokeWidth,
    required this.isReducedMotion,
  });

  /// The world to draw.
  final AscentWorld world;

  /// The opening, 0 to 1: the shaft lighting up as a run begins.
  final double entrance;

  /// Dressed stone.
  final Color stone;

  /// Weathered stone, and anything about to give way.
  final Color cracked;

  /// The climber, and the register bands.
  final Color gold;

  /// The brighter gold the scarab's sun carries.
  final Color glow;

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

    // The opening: light travels up the shaft as a run begins, so the game
    // arrives rather than appearing. Drawn last, over everything, and gone by
    // the time the first ledge matters.
    if (entrance >= 1) return;
    final swept = size.height * (1 - entrance) * 1.2;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height - swept + 0.5),
        Paint()..color = glow.withValues(alpha: (1 - entrance) * 0.16),
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height - swept, size.width, swept),
        Paint()..color = wall.withValues(alpha: 0.92),
      )
      ..drawLine(
        Offset(0, size.height - swept),
        Offset(size.width, size.height - swept),
        Paint()
          ..color = glow
          ..strokeWidth = strokeWidth * 2,
      );
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
      final ornament = Ornament.values[index.abs() % Ornament.values.length];
      final path = Path();
      final origin = Offset(size.width * 0.08, y + box * 0.6);
      for (final stroke in OrnamentPaths.strokes(ornament, box)) {
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

  /// The climber: a scarab carrying the sun up the shaft.
  ///
  /// Khepri rolls the sun from horizon to horizon, which is the same thing the
  /// player is doing, so the character was already in the motif library rather
  /// than needing inventing. It reads at 20 pixels because it is a silhouette
  /// with one bright disc: the disc is what the eye tracks and the body is
  /// what makes it a creature rather than a dot.
  void _paintClimber(Canvas canvas, Size size, double y) {
    final scale = math.max(strokeWidth * 3, size.width * 0.030);
    final centre = Offset(world.climberX * size.width, y - scale);
    final rising = world.velocity > 0;

    final body = Paint()..color = stone;
    final ink = Paint()
      ..color = wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Six legs, swept back when rising and braced when falling, which is the
    // whole animation and costs six lines.
    final sweep = rising ? 0.55 : -0.2;
    for (final side in [-1, 1]) {
      for (var i = 0; i < 3; i++) {
        final origin = centre.translate(
          side * scale * 0.5,
          (i - 1) * scale * 0.34,
        );
        canvas.drawLine(
          origin,
          origin.translate(side * scale * 0.85, scale * (0.42 + sweep * 0.4)),
          Paint()
            ..color = stone
            ..strokeWidth = strokeWidth * 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // The shell: an oval with the central seam a scarab's elytra have.
    final shell = Rect.fromCenter(
      center: centre,
      width: scale * 1.45,
      height: scale * 1.75,
    );
    canvas
      ..drawOval(shell, body)
      ..drawOval(shell, ink)
      ..drawLine(shell.topCenter, shell.bottomCenter, ink)
      // The head plate, notched, at the leading edge.
      ..drawArc(
        Rect.fromCenter(
          center: centre.translate(0, -scale * 0.82),
          width: scale * 1.15,
          height: scale * 0.8,
        ),
        math.pi,
        math.pi,
        true,
        body,
      );

    // The sun it carries. The one filled bright thing on screen, and the
    // reason the player never loses track of where they are.
    final sun = centre.translate(0, -scale * 1.55);
    if (isReducedMotion) {
      canvas.drawCircle(sun, scale * 0.62, Paint()..color = glow);
      return;
    }

    // A short wake below, so upward travel is legible at speed.
    canvas
      ..drawCircle(sun, scale * 0.62, Paint()..color = glow)
      ..drawLine(
        centre.translate(0, scale),
        centre.translate(0, scale * 2.4),
        Paint()
          ..color = gold.withValues(alpha: 0.3)
          ..strokeWidth = strokeWidth * 2
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(AscentPainter oldDelegate) =>
      !identical(oldDelegate.world, world) ||
      oldDelegate.entrance != entrance ||
      oldDelegate.stone != stone ||
      oldDelegate.gold != gold ||
      oldDelegate.wall != wall ||
      oldDelegate.isReducedMotion != isReducedMotion;
}
