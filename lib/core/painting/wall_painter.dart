import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/sign_paths.dart';
import 'package:nocturne/core/painting/station_seed.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';

/// The wall: the career as an inscription, revealed by torchlight.
///
/// The signature element from milestone 5, replacing the telemetry trace.
/// `00-PROJECT-BRIEF.md` §3: the career is cut into a dark wall in registers,
/// and scrolling moves a torch down it. Scroll fast and the light smears and
/// the signs stay unreadable; slow down and a register resolves.
///
/// **Only the paint is new.** The velocity engine, the coherence model and the
/// measured burst anchors are the trace's, unchanged — which is what made this
/// a re-skin rather than a rewrite, and why the scroll behaviour the owner
/// liked survives intact. `coherence` still means what it meant: 0 is a
/// smeared, unreadable wall and 1 is a resolved one.
class WallPainter extends CustomPainter {
  /// [scrollOffset] and [viewportHeight] describe what is currently on screen;
  /// [wallHeight] is the whole wall's length in the same pixels.
  const WallPainter({
    required this.bursts,
    required this.phase,
    required this.coherence,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.wallHeight,
    required this.restColour,
    required this.lockedColour,
    required this.peakColour,
    required this.strokeWidth,
    required this.stoneColour,
    required this.carveShadow,
    required this.carveLight,
  });

  /// The masonry behind the inscription.
  ///
  /// A temple wall is built of blocks, and drawing signs on an empty column
  /// was most of why this read as a wireframe diagram rather than as stone.
  final Color stoneColour;

  /// The dark side of a cut.
  ///
  /// Carving is legible because of its edges, not its line. One flat stroke is
  /// a drawing of an inscription; a dark edge below it and a lit edge above
  /// it is a groove, and the difference costs two more passes of the same
  /// path.
  final Color carveShadow;

  /// The lit side of a cut, where the torch catches the upper lip.
  final Color carveLight;

  /// Career bursts, already laid out and anchored to rendered sections.
  final List<TraceBurst> bursts;

  /// Torch breathing, 0..1 of a cycle. The wall is never quite still.
  final double phase;

  /// How resolved the inscription is, 0..1.
  final double coherence;

  /// Current scroll position in pixels.
  final double scrollOffset;

  /// Visible height in pixels.
  final double viewportHeight;

  /// The whole wall's length in pixels.
  final double wallHeight;

  /// Unlit stone.
  final Color restColour;

  /// Stone under the torch.
  final Color lockedColour;

  /// The register mark at a burst's own line.
  final Color peakColour;

  /// Incised line weight.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || wallHeight <= 0) return;

    // Off-screen entirely: nothing to draw, and the register loop would run
    // for a stretch nobody is looking at.
    final visibleTop = scrollOffset;
    final visibleBottom = scrollOffset + viewportHeight;
    if (visibleBottom <= 0 || visibleTop >= wallHeight) return;

    final from = visibleTop.clamp(0.0, wallHeight);
    final to = visibleBottom.clamp(0.0, wallHeight);
    if (to <= from) return;

    // The unlit pass. Everything is on the wall whether or not the torch is
    // near it -- a wall does not stop existing in the dark, and a viewer who
    // has scrolled past should still see the inscription they left behind.
    _masonry(canvas, size, from: from, to: to);
    _signs(canvas, size, from: from, to: to);

    if (coherence <= 0) return;

    // The lit pass, masked to the torch. Drawn as a layer so the gradient
    // erases it at the edges rather than being drawn on top of it: a bright
    // pool painted over dim signs reads as a spotlight decal, this reads as
    // light falling on carved stone.
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    _signs(canvas, size, from: from, to: to, lit: true);
    canvas
      ..drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = _torch(size),
      )
      ..restore();
  }

  /// One sign to a block, most cut in stone and a few gilded.
  ///
  /// This replaced a run of long horizontal rules with signs strung along
  /// them. The owner's objection was the rules: they ran the width of the
  /// column, which is not how a wall is laid out, and read as ruled paper. A
  /// temple wall is registers of blocks, and each block carries its sign.
  ///
  /// The gilded ones catch a highlight that travels down the wall, so the gold
  /// reads as leaf under a moving light rather than as a second colour.
  void _signs(
    Canvas canvas,
    Size size, {
    required double from,
    required double to,
    bool lit = false,
  }) {
    const cell = Tokens.wallCourseHeight;
    const block = Tokens.wallBlockWidth;
    final columns = math.max(1, (size.width / block).floor());
    final width = size.width / columns;
    final box = math.min(width, cell) * Tokens.wallSignFill;
    if (box <= 0) return;

    final firstRow = (from / cell).floor();
    final lastRow = (to / cell).ceil();

    for (var row = firstRow; row <= lastRow; row++) {
      final top = row * cell - scrollOffset;
      if (top > size.height || top + cell < 0) continue;

      for (var column = 0; column < columns; column++) {
        // Seeded on the block's own coordinates, so the wall is the same wall
        // every time it is painted and does not reshuffle as it is scrolled
        // back up.
        final seed = StationSeed('sign.$column.$row');
        final sign = signOrder[seed.nextInt(signOrder.length)];
        final gilded = seed.nextInt(Tokens.wallGildedInOne) == 0;
        if (lit && !gilded) continue;

        final path = SignPaths.of(sign, box);
        final dx = column * width + (width - box) / 2;
        final dy = top + (cell - box) / 2;

        canvas
          ..save()
          ..translate(dx, dy);
        _carveSign(
          canvas,
          path,
          _signPaint(gilded: gilded, row: row, lit: lit),
          box,
        );
        canvas.restore();
      }
    }
  }

  /// How one sign is filled.
  ///
  /// Stone signs are flat. Gilded ones brighten and dim as a highlight passes
  /// down the wall: the wave is a function of the block's row as well as the
  /// phase, so neighbouring courses light slightly out of step and the column
  /// does not pulse all at once like a bulb.
  Paint _signPaint({
    required bool gilded,
    required int row,
    required bool lit,
  }) {
    if (!gilded) {
      return Paint()..color = lit ? lockedColour : restColour;
    }
    final travel = phase * 2 * math.pi - row * Tokens.wallShimmerStagger;
    final shimmer = (math.sin(travel) + 1) / 2;
    return Paint()
      ..color = Color.lerp(carveLight, peakColour, shimmer)!
      // A soft bloom at the peak of the wave, so it reads as something
      // catching light rather than as a colour change.
      ..maskFilter = shimmer > Tokens.wallShimmerBloomAt
          ? MaskFilter.blur(
              BlurStyle.solid,
              (shimmer - Tokens.wallShimmerBloomAt) * Tokens.wallShimmerBloom,
            )
          : null;
  }

  /// The torch's falloff over the visible wall.
  ///
  /// The pool tightens as the reading settles and spreads as it is lost, so a
  /// fast scroll washes the wall in weak light rather than lighting a smaller
  /// part of it brightly. [phase] breathes the radius a little, which is what
  /// keeps a settled wall from looking like a static image.
  ui.Shader _torch(Size size) {
    final breath = 1 + math.sin(phase * 2 * math.pi) * Tokens.wallTorchBreath;
    final radius =
        ui.lerpDouble(
          Tokens.wallTorchSpread,
          Tokens.wallTorchFocus,
          coherence,
        )! *
        breath;

    return RadialGradient(
      radius: radius,
      colors: [
        Color.fromRGBO(0, 0, 0, coherence),
        const Color.fromRGBO(0, 0, 0, 0),
      ],
      stops: const [0, 1],
    ).createShader(Offset.zero & size);
  }

  /// Draws a silhouette as something cut into stone rather than stuck on it.
  ///
  /// Three passes of the same shape: the shadow the groove throws below it,
  /// the lit lip above it, then the body. Offsets are a fraction of the sign,
  /// so a cut stays one cut whether the block is wide or narrow.
  void _carveSign(Canvas canvas, Path path, Paint body, double box) {
    final relief = box * Tokens.wallSignRelief;
    canvas
      ..save()
      ..translate(relief, relief)
      ..drawPath(path, Paint()..color = carveShadow)
      ..restore()
      ..save()
      ..translate(-relief, -relief)
      ..drawPath(path, Paint()..color = carveLight)
      ..restore()
      ..drawPath(path, body);
  }

  /// The blocks the wall is built from.
  ///
  /// Courses with staggered joints, which is how masonry is laid and why a
  /// grid of squares would read as tile instead. Faint: this is the surface
  /// the inscription is cut into, not a pattern competing with it.
  void _masonry(
    Canvas canvas,
    Size size, {
    required double from,
    required double to,
  }) {
    const course = Tokens.wallCourseHeight;
    final paint = Paint()
      ..color = stoneColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final first = (from / course).floor() * course;
    for (var y = first; y <= to + course; y += course) {
      final dy = y - scrollOffset;
      if (dy < -course || dy > size.height + course) continue;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);

      // Every other course is offset by half a block, so the vertical joints
      // break rather than running the height of the wall.
      final index = (y / course).round();
      final shift = index.isEven ? 0.0 : Tokens.wallBlockWidth / 2;
      for (var x = shift; x < size.width; x += Tokens.wallBlockWidth) {
        canvas.drawLine(Offset(x, dy), Offset(x, dy + course), paint);
      }
    }
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.coherence != coherence ||
      oldDelegate.scrollOffset != scrollOffset ||
      oldDelegate.viewportHeight != viewportHeight ||
      oldDelegate.wallHeight != wallHeight ||
      oldDelegate.restColour != restColour ||
      oldDelegate.lockedColour != lockedColour ||
      oldDelegate.peakColour != peakColour ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.stoneColour != stoneColour ||
      oldDelegate.carveShadow != carveShadow ||
      oldDelegate.carveLight != carveLight ||
      !identical(oldDelegate.bursts, bursts);
}
