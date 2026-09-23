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
    this.torch,
    this.torchStrength = 0,
    this.restAlpha = 1,
  });

  /// How much of the wall shows where no torch is held, 0 to 1.
  ///
  /// One on a phone, where the wall is a strip of its own. Lower on a wider
  /// screen, where it is the pattern behind the whole page and the copy sits
  /// over it: the stone, its joints and its resting signs fade to this, and
  /// the torch still brings a sign all the way up to gold -- so the carving is
  /// faint behind the reading and bright wherever the viewer holds the light.
  final double restAlpha;

  /// Where the viewer is holding the light, in this painter's own pixels.
  ///
  /// Null on touch, and whenever the pointer is off the wall. A hand holding a
  /// torch is the whole conceit of this column: with a pointer, the light is
  /// the pointer. Without one there is nothing to follow, so the wall lights
  /// itself instead -- see [_signPaint].
  final Offset? torch;

  /// How far the light has come up, 0 to 1.
  ///
  /// Separate from [torch] so the wall fades rather than snapping. Moving the
  /// pointer off the column used to cut the gold out in one frame, which read
  /// as a bug; the flame now dies down and the stone comes back.
  final double torchStrength;

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

    // Clipped to the column. A course that begins just above the viewport is
    // still drawn -- its lower half is visible -- and a canvas does not clip
    // itself, so on a phone the top of that sign was painted over the
    // navigation above the content. It is a wall, not a decal: it ends where
    // its own box does.
    canvas.clipRect(Offset.zero & size);

    final bounds = Offset.zero & size;

    // Behind the page, the whole resting wall goes into one layer at
    // [restAlpha]. Fading each colour instead compounded: every sign is three
    // overlapping passes of the same shape, so a 0.3 body over a 0.3 shadow
    // over a 0.3 highlight came out at twice the strength asked for.
    final isFaded = restAlpha < 1;
    if (isFaded) {
      canvas.saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(0, 0, 0, restAlpha),
      );
    }

    // The unlit pass. Everything is on the wall whether or not the torch is
    // near it -- a wall does not stop existing in the dark, and a viewer who
    // has scrolled past should still see the inscription they left behind.
    _masonry(canvas, size, from: from, to: to);
    _signs(canvas, size, from: from, to: to, withTorch: !isFaded);

    if (coherence > 0) {
      // The lit pass, masked to the torch. Drawn as a layer so the gradient
      // erases it at the edges rather than being drawn on top of it: a bright
      // pool painted over dim signs reads as a spotlight decal, this reads as
      // light falling on carved stone.
      canvas.saveLayer(bounds, Paint());
      _signs(canvas, size, from: from, to: to, lit: true, withTorch: !isFaded);
      canvas
        ..drawRect(
          bounds,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = _torch(size),
        )
        ..restore();
    }

    if (!isFaded) return;
    canvas.restore();

    // And the hand's light over the top, at full strength: the carving stays
    // faint behind the reading and comes up gold wherever the pointer holds
    // the flame.
    if (torch != null && torchStrength > 0) {
      _signs(canvas, size, from: from, to: to, torchOnly: true);
    }
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
    bool withTorch = true,
    bool torchOnly = false,
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

        final path = SignPaths.of(sign, box);
        final dx = column * width + (width - box) / 2;
        final dy = top + (cell - box) / 2;
        final centre = Offset(dx + box / 2, dy + box / 2);

        if (torchOnly) {
          // Only what the hand is lighting, as gold over the faded wall.
          final reached = _reached(centre);
          if (reached <= 0) continue;
          canvas
            ..save()
            ..translate(dx, dy)
            ..drawPath(
              path,
              Paint()
                ..color = peakColour.withValues(alpha: peakColour.a * reached)
                ..maskFilter = _bloom(reached),
            )
            ..restore();
          continue;
        }

        canvas
          ..save()
          ..translate(dx, dy);
        _carveSign(
          canvas,
          path,
          _signPaint(
            gilded: gilded,
            row: row,
            lit: lit,
            centre: centre,
            withTorch: withTorch,
          ),
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
    required Offset centre,
    bool withTorch = true,
  }) {
    // How much of the torch this block is getting. Zero when the light is
    // elsewhere or absent, which is every block on a phone -- and zero here
    // when the torch is drawn in a pass of its own over a faded wall.
    final reached = withTorch ? _reached(centre) : 0.0;

    // The base state. One block in five is gilded and breathes on its own, so
    // a wall nobody is touching -- a phone, or a pointer somewhere else -- is
    // still alive. The rest are stone.
    final Color base;
    if (gilded) {
      final travel = phase * 2 * math.pi - row * Tokens.wallShimmerStagger;
      final breath = (math.sin(travel) + 1) / 2;
      base = Color.lerp(carveLight, peakColour, breath)!;
    } else {
      base = lit ? lockedColour : restColour;
    }

    if (reached <= 0) return Paint()..color = base;

    // Under the light everything turns to gold, gilded or not: the owner asked
    // for the wall to change colour where the torch is and come back when it
    // leaves, which is what a flame does to a gilded relief.
    return Paint()
      ..color = Color.lerp(base, peakColour, reached)!
      ..maskFilter = _bloom(reached);
  }

  /// How much of the hand's torch a block centred at [centre] is getting.
  double _reached(Offset centre) {
    final held = torch;
    if (held == null || torchStrength <= 0) return 0;
    final distance = (held - centre).distance;
    final falloff = (1 - distance / Tokens.wallTorchReach).clamp(0.0, 1.0);
    // Eased rather than squared. Squaring kept the pool's whole strength in
    // the last few pixels, so a block a hand's width from the flame barely
    // moved and the wall read as tinted instead of lit; this holds the
    // middle of the range up and still falls to nothing at the edge.
    return falloff * falloff * (3 - 2 * falloff) * torchStrength;
  }

  /// The glow of a sign lit past the bloom threshold.
  MaskFilter? _bloom(double reached) => reached > Tokens.wallShimmerBloomAt
      ? MaskFilter.blur(
          BlurStyle.solid,
          (reached - Tokens.wallShimmerBloomAt) * Tokens.wallShimmerBloom,
        )
      : null;

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
      oldDelegate.torch != torch ||
      oldDelegate.torchStrength != torchStrength ||
      oldDelegate.restAlpha != restAlpha ||
      !identical(oldDelegate.bursts, bursts);
}
