import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/glyph_paths.dart';
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
  });

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

  /// Spacing between register rules, in logical pixels.
  static const double _registerSpacing = 132;

  /// How much of a register's width the signs occupy.
  static const double _inscriptionInset = 0.14;

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

    final inset = size.width * _inscriptionInset;
    final runWidth = size.width - inset * 2;
    if (runWidth <= 0) return;

    // The unlit pass. Everything is on the wall whether or not the torch is
    // near it — a wall does not stop existing in the dark, and a viewer who
    // has scrolled past should still see the inscription they left behind.
    final content = _inscription(
      from: from,
      to: to,
      inset: inset,
      runWidth: runWidth,
    );
    canvas.drawPath(content, _stroke(restColour));

    if (coherence <= 0) return;

    // The lit pass, masked to the torch. Drawn as a layer so the gradient
    // erases it at the edges rather than being drawn on top of it: a bright
    // pool painted over dim strokes reads as a spotlight decal, this reads as
    // light falling on carved stone.
    final bounds = Offset.zero & size;
    canvas
      ..saveLayer(bounds, Paint())
      ..drawPath(content, _stroke(lockedColour));

    // Registers under the torch pick up the gold, which is the only chroma the
    // wall itself carries.
    final marks = Paint()..color = peakColour;
    for (final burst in bursts) {
      final y = burst.anchor * wallHeight;
      if (y < from || y > to) continue;
      canvas.drawCircle(
        Offset(inset / 2, y - scrollOffset),
        strokeWidth * 1.6,
        marks,
      );
    }

    canvas
      ..drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = _torch(size),
      )
      ..restore();
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

  Paint _stroke(Color colour) => Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// The visible inscription: register rules, and signs on the burst lines.
  ///
  /// Built for the visible window only. A wall is as long as the page and
  /// sampling all of it would cost frames for stone nobody is looking at.
  Path _inscription({
    required double from,
    required double to,
    required double inset,
    required double runWidth,
  }) {
    final path = Path();

    // Register rules: the horizontal bands a tomb wall is divided into, and
    // the reason the career reads as a sequence rather than a list. Each
    // carries a run of signs, because a wall of bare rules is ruled paper.
    final firstRule = (from / _registerSpacing).floor() * _registerSpacing;
    for (var y = firstRule; y <= to; y += _registerSpacing) {
      if (y < from - _registerSpacing) continue;
      final dy = y - scrollOffset;
      path
        ..moveTo(inset, dy)
        ..lineTo(inset + runWidth, dy);

      // Signs sit on the rule, as they do on a wall. The seed is the rule's
      // own position, so the wall is identical every time it is painted and
      // does not reshuffle as the viewer scrolls back up it.
      _inscribe(
        path: path,
        seed: StationSeed('wall.${y.round()}'),
        left: inset,
        width: runWidth,
        baseline: dy,
        fill: Tokens.wallRestFill,
      );
    }

    // A burst's own line is inscribed more fully. Amplitude decides how much
    // of the run is filled, so a long role carries a denser line than a short
    // one -- the same quantity the trace expressed as height.
    for (final burst in bursts) {
      final y = burst.anchor * wallHeight;
      if (y < from - _registerSpacing || y > to + _registerSpacing) continue;
      _inscribe(
        path: path,
        seed: StationSeed(burst.id),
        left: inset,
        width: runWidth,
        baseline: y - scrollOffset,
        fill: burst.amplitude,
      );
    }

    return path;
  }

  /// Lays a run of signs along one line, filling [fill] of the available run.
  ///
  /// Nothing here spells anything, and the site never offers a translation or
  /// presents these as readable — see `12-MOTIF-LIBRARY.md` §0. The career they
  /// stand beside is rendered as real text a few pixels away.
  void _inscribe({
    required Path path,
    required StationSeed seed,
    required double left,
    required double width,
    required double baseline,
    required double fill,
  }) {
    final box = math.min(Tokens.wallSignPitch * 0.7, _registerSpacing * 0.3);
    final count = math.max(1, (fill * width / Tokens.wallSignPitch).floor());
    final top = baseline - box / 2;

    for (var i = 0; i < count; i++) {
      final x = left + i * Tokens.wallSignPitch;
      if (x + box > left + width) break;
      final glyph =
          EgyptianGlyph.values[seed.nextInt(EgyptianGlyph.values.length)];
      for (final stroke in GlyphPaths.strokes(glyph, box)) {
        path.moveTo(x + stroke.first.x, top + stroke.first.y);
        for (final point in stroke.skip(1)) {
          path.lineTo(x + point.x, top + point.y);
        }
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
      !identical(oldDelegate.bursts, bursts);
}
