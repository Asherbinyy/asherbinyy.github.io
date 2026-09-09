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
    required this.chamber,
    required this.pier,
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

  /// The lit ground inside the shaft.
  ///
  /// The play area is the brightest surface in the frame, and it has to be:
  /// the first pass filled the piers instead and the eye went straight to the
  /// scenery rather than to the column the player is climbing.
  final Color chamber;

  /// The rock the shaft is cut through, either side of it.
  final Color pier;

  /// Incised line weight.
  final double strokeWidth;

  /// Whether parallax and drift are suppressed.
  final bool isReducedMotion;

  /// How much of the frame sits below the climber.
  static const double _climberHeight = 0.62;

  /// Metres of shaft visible at once.
  ///
  /// Lower than it was. The camera used to hold 26 metres, which on a wide
  /// monitor put nine hairline ledges in an otherwise empty field and read as
  /// nothing at all. Everything is nearer now, which is most of what "denser"
  /// means here: the ledge count per screen barely changes, the sense of being
  /// inside a shaft rather than looking at a diagram changes completely.
  static const double _visibleMetres = 20;

  /// The playable column, centred in whatever frame it is given.
  ///
  /// This is the fix for the game not looking like the one it is modelled on.
  /// Ice Tower is a **narrow tower**: two walls close enough that the player
  /// is always near one, and everything outside them is scenery. This painter
  /// used the entire surface as the playfield, so on a desktop the climber had
  /// 1440 pixels of blank to drift through and the walls were two faint lines
  /// with nothing behind them.
  ///
  /// The frame is still filled edge to edge -- the owner asked for that and it
  /// was a real complaint -- but it is filled with the temple the shaft is cut
  /// through, not with more playfield.
  ///
  /// A phone gets the whole width, because at 390 points there is no room for
  /// scenery and a shaft narrower than the frame would be a box inside a box,
  /// which is the other thing he objected to.
  ///
  /// The pier is what grows, from nothing, rather than the shaft being capped.
  /// Capping it is the obvious way round and it is wrong: a cap crosses over
  /// at some width and leaves a band just past it where each pier is ten
  /// pixels of masonry, which looks like a border someone forgot to remove.
  /// Growing the pier from zero means the scenery either does not exist or is
  /// wide enough to be scenery, with nothing in between.
  static Rect shaftOf(Size size) {
    // Clamped rather than floored at zero, so the rock can never eat the
    // column it is supposed to be framing however the frame is shaped.
    // `clamp` widens to num across an int bound, and every use below is
    // double, so it is narrowed back here rather than at four call sites.
    final pier = ((size.width - _pierFrom) * _pierRate)
        .clamp(0, size.width * 0.36)
        .toDouble();
    final width = size.width - pier * 2;
    return Rect.fromLTWH(pier, 0, width, size.height);
  }

  /// The frame width at which rock starts to appear either side, in logical
  /// pixels. Above the largest phone, so no phone ever sees a pier.
  static const double _pierFrom = 460;

  /// How much of each further pixel of frame goes to the rock rather than the
  /// shaft. At a 1440 desktop this leaves a 618-pixel column.
  static const double _pierRate = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final shaft = shaftOf(size);
    final metresToPixels = size.height / _visibleMetres;
    // The camera holds the climber at a fixed height and moves the world, so
    // the ascent reads as travel rather than as a shrinking figure.
    final camera = world.climberY - _visibleMetres * (1 - _climberHeight);

    double screenY(double metres) =>
        size.height - (metres - camera) * metresToPixels;

    _paintPiers(canvas, size, shaft, camera, metresToPixels, screenY);
    _paintShaftWall(canvas, shaft, camera, metresToPixels, screenY);

    // Register bands: the altitude at which a fact is uncovered. Drawn behind
    // the ledges so a band never hides a foothold, and clipped to the shaft so
    // they read as marks cut into its wall rather than as ruled rows across
    // the whole screen.
    final bands = Paint()
      ..color = gold.withValues(alpha: 0.3)
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
      canvas.drawLine(Offset(shaft.left, y), Offset(shaft.right, y), bands);
    }

    for (final ledge in world.ledges) {
      final y = screenY(ledge.y);
      if (y < -size.height || y > size.height * 2) continue;
      _paintLedge(canvas, shaft, ledge, y);
    }

    _paintClimber(canvas, shaft, screenY(world.climberY));

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

  /// The masonry either side of the shaft, and the dark beyond it.
  ///
  /// Everything here is scenery: nothing in it is collidable and nothing in it
  /// moves with the player except the courses scrolling past, which is the
  /// only cue that the piers are stone the climber is passing rather than a
  /// border drawn on the screen.
  void _paintPiers(
    Canvas canvas,
    Size size,
    Rect shaft,
    double camera,
    double metresToPixels,
    double Function(double) screenY,
  ) {
    final piers = [
      Rect.fromLTRB(0, 0, shaft.left, size.height),
      Rect.fromLTRB(shaft.right, 0, size.width, size.height),
    ];
    // A phone has no pier: the shaft is the frame.
    if (piers.every((pier) => pier.width <= 0)) return;

    final face = Paint()..color = pier;
    final course = Paint()
      ..color = stone.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final face_ in piers) {
      if (face_.width <= 0) continue;
      canvas
        ..save()
        ..clipRect(face_)
        ..drawRect(face_, face);

      // Shorter courses than the shaft's own, so the rock outside reads as
      // smaller stone further away.
      const courseMetres = 1.6;
      final first = (camera / courseMetres).floor() * courseMetres;
      for (
        var metres = first;
        metres < camera + _visibleMetres + courseMetres;
        metres += courseMetres
      ) {
        final y = screenY(metres);
        canvas.drawLine(Offset(face_.left, y), Offset(face_.right, y), course);

        // Joints at a fixed block size rather than a fraction of the pier,
        // because a pier is as wide as the monitor leaves it: at a third of
        // its width the blocks came out 175 pixels across and read as panels
        // rather than as masonry. Staggered by course index rather than
        // randomised, because a wall that reshuffles as it scrolls is worse
        // than a regular one.
        final index = (metres / courseMetres).round();
        final block = courseMetres * metresToPixels * 1.5;
        final shift = index.isEven ? 0.0 : block / 2;
        for (var x = face_.left + shift; x < face_.right; x += block) {
          if (x <= face_.left) continue;
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + courseMetres * metresToPixels),
            course,
          );
        }
      }
      canvas.restore();
    }

    // The shaft's own edges, brighter than anything in the piers, because they
    // are the two lines the player is actually reading against.
    final edge = Paint()
      ..color = stone.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth * 2;
    canvas
      ..drawLine(shaft.topLeft, shaft.bottomLeft, edge)
      ..drawLine(shaft.topRight, shaft.bottomRight, edge);
  }

  /// The back of the shaft: courses of stone, with ornament on some of them.
  void _paintShaftWall(
    Canvas canvas,
    Rect shaft,
    double camera,
    double metresToPixels,
    double Function(double) screenY,
  ) {
    canvas
      ..save()
      ..clipRect(shaft)
      // The shaft's own ground, laid before its courses: this is the surface
      // the player reads everything else against.
      ..drawRect(shaft, Paint()..color = chamber);

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
      canvas.drawLine(Offset(shaft.left, y), Offset(shaft.right, y), course);

      // A vertical joint, offset course to course, so the wall reads as
      // masonry rather than as ruled paper.
      final index = (metres / courseMetres).round();
      final offset = index.isEven ? 0.33 : 0.66;
      canvas.drawLine(
        Offset(shaft.left + shaft.width * offset, y),
        Offset(
          shaft.left + shaft.width * offset,
          y + courseMetres * metresToPixels,
        ),
        course,
      );

      // Ornament on every third course. Sparse on purpose: this is the
      // background of a game, and a decorated wall would compete with the
      // ledges the player actually has to read.
      if (index % 3 != 0) continue;
      final box = math.min(
        shaft.width * 0.09,
        courseMetres * metresToPixels / 3,
      );
      if (box <= 0) continue;
      final ornament = Ornament.values[index.abs() % Ornament.values.length];
      final path = Path();
      final origin = Offset(shaft.left + shaft.width * 0.06, y + box * 0.6);
      for (final stroke in OrnamentPaths.strokes(ornament, box)) {
        path.moveTo(origin.dx + stroke.first.x, origin.dy + stroke.first.y);
        for (final point in stroke.skip(1)) {
          path.lineTo(origin.dx + point.x, origin.dy + point.y);
        }
      }
      canvas.drawPath(path, course);
    }
    canvas.restore();
  }

  /// One ledge, as a cut block rather than a rule.
  void _paintLedge(Canvas canvas, Rect shaft, Ledge ledge, double y) {
    if (ledge.isBroken) return;

    final left = shaft.left + (ledge.x - ledge.width / 2) * shaft.width;
    final width = ledge.width * shaft.width;
    // Thick enough to be a thing to land on. The old height was three
    // hairlines, which drew a divider.
    final height = math.max(strokeWidth * 5, shaft.height * 0.019);
    final rect = Rect.fromLTWH(left, y - height / 2, width, height);

    final colour = ledge.kind == LedgeKind.cracked ? cracked : stone;
    canvas
      ..drawRect(rect, Paint()..color = colour.withValues(alpha: 0.3))
      ..drawRect(
        rect,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      )
      // The lit top edge. One line, and it is the whole difference between a
      // block and a rectangle: it says which side the player lands on.
      ..drawLine(
        rect.topLeft,
        rect.topRight,
        Paint()
          ..color = colour
          ..strokeWidth = strokeWidth * 2,
      );

    // Joints, so a wide ledge reads as courses of stone rather than one slab.
    final joints = (width / math.max(height * 2.4, 1)).floor();
    if (joints > 1) {
      final joint = Paint()
        ..color = colour.withValues(alpha: 0.5)
        ..strokeWidth = strokeWidth;
      for (var i = 1; i < joints; i++) {
        final x = left + width * i / joints;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), joint);
      }
    }

    // A cracked ledge shows why it is about to fail.
    if (ledge.kind == LedgeKind.cracked) {
      final split = Paint()
        ..color = cracked
        ..strokeWidth = strokeWidth;
      canvas.drawLine(
        Offset(rect.center.dx - width * 0.06, rect.top),
        Offset(rect.center.dx + width * 0.06, rect.bottom),
        split,
      );
    }

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
  /// than needing inventing.
  ///
  /// Sized off the shaft rather than the frame. Taken from the full width it
  /// rendered at 43 pixels on a desktop with a sun the size of its own body
  /// balanced on top, which read as a balloon on a beetle. The sun now sits
  /// against the head, being pushed, which is the entire point of the figure.
  void _paintClimber(Canvas canvas, Rect shaft, double y) {
    final scale = math.max(strokeWidth * 3, shaft.width * 0.048);
    final centre = Offset(shaft.left + world.climberX * shaft.width, y - scale);
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
    // reason the player never loses track of where they are. Overlapping the
    // head rather than floating above it.
    final sun = centre.translate(0, -scale * 1.18);
    canvas.drawCircle(sun, scale * 0.52, Paint()..color = glow);
    if (isReducedMotion) return;

    // A short wake below, so upward travel is legible at speed.
    canvas.drawLine(
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
      oldDelegate.chamber != chamber ||
      oldDelegate.pier != pier ||
      oldDelegate.isReducedMotion != isReducedMotion;
}
