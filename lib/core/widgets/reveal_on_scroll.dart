import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// Unrolls its child the first time it comes into view.
///
/// The career is a sequence of stops and the page should read as one: entries
/// arriving as you reach them rather than all of them sitting there already.
/// The motion is a document unrolling — the entry is revealed downward from
/// its top edge while it settles the last few pixels into place — because that
/// is the object this site is made of, and a card sliding in from the side
/// would belong to a different one.
///
/// **Once, and only forward.** Scrolling back up does not roll it away again.
/// A reader who returns to something they have already read should find it
/// where they left it, and an element that animates every time it crosses the
/// fold is a page that will not settle.
///
/// Under reduced motion it is simply there. The content is the point; the
/// unrolling is a flourish, and a flourish is the first thing to go.
class RevealOnScroll extends StatefulWidget {
  /// Reveals [child] when it reaches [revealAt] of the viewport height.
  const RevealOnScroll({
    required this.child,
    this.revealAt = 0.9,
    this.style = RevealStyle.unroll,
    this.delay = Duration.zero,
    super.key,
  });

  /// How the child arrives.
  final RevealStyle style;

  /// How long after reaching the fold it waits before arriving -- so a row of
  /// cards can come in one after another rather than all at once.
  final Duration delay;

  /// What is revealed.
  final Widget child;

  /// How far down the viewport the top edge must reach, as a fraction.
  ///
  /// Slightly less than one, so an entry begins unrolling as it appears rather
  /// than after it has already been in view for a moment.
  final double revealAt;

  /// How far the nearest reveal above [context] has got, 0 to 1, so a part
  /// of a card can finish arriving after the card itself has. Complete where
  /// there is no reveal above it.
  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealScope>()?.reveal ??
      kAlwaysCompleteAnimation;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

/// Hands the reveal's progress down to whatever is being revealed.
class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.reveal, required super.child});

  final Animation<double> reveal;

  @override
  bool updateShouldNotify(_RevealScope oldWidget) =>
      !identical(oldWidget.reveal, reveal);
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: widget.style == RevealStyle.rise
        ? Tokens.revealRise
        : Motion.considered,
  );
  bool _started = false;

  ScrollController? _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    // Anything already on screen at first paint is already revealed. Animating
    // the top of the page on arrival would make the site look like it was
    // still loading when it was not.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _check(immediate: true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The page's own controller, not a `ScrollNotification`.
    //
    // This widget sits *inside* the scroll view, and notifications travel
    // outward from the scrollable, so a listener under it never sees them.
    // `ChromeScrollScope` says so in as many words and I did not read it: the
    // first version listened for notifications, never fired, and left every
    // career entry clipped to nothing. Tests passed; the page was blank.
    final next = ChromeScrollScope.maybeOf(context)?.controller;
    // `_resolved` rather than a null check. On the first pass `_controller` is
    // null and, outside the chrome, so is `next` -- so comparing them skipped
    // the no-scroll fallback entirely and left `/cv` and `/brief` blank. Null
    // is a real answer here, not the absence of one.
    if (_resolved && identical(next, _controller)) return;
    _resolved = true;
    _controller?.removeListener(_check);
    _controller = next;
    if (next == null) {
      // No chrome around this -- `/cv`, `/brief`, a test harness. There is no
      // scroll to wait for, so there is nothing to reveal on.
      _started = true;
      _reveal.value = 1;
      return;
    }
    next.addListener(_check);
  }

  @override
  void dispose() {
    _controller?.removeListener(_check);
    _reveal.dispose();
    super.dispose();
  }

  void _check({bool immediate = false}) {
    if (_started || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;

    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    if (top > viewport.size.height * widget.revealAt) return;

    _started = true;
    if (immediate || ReducedMotion.of(context)) {
      _reveal.value = 1;
    } else if (widget.delay == Duration.zero) {
      _reveal.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _reveal.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) {
        final value = MotionCurves.emphasized.transform(
          _reveal.value.clamp(0.0, 1.0),
        );
        if (widget.style == RevealStyle.rise) {
          // Up from below and in from the trailing side, growing the last
          // few per cent into place: a card arriving, rather than a line of
          // text appearing.
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          final away = 1 - value;
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(
                (isRtl ? -1 : 1) * away * Tokens.revealRiseSlide,
                away * Tokens.revealRiseLift,
              ),
              child: Transform.scale(
                scale: 1 - away * Tokens.revealRiseShrink,
                child: child,
              ),
            ),
          );
        }
        return Opacity(
          // Fades over the first half only. A sheet is opaque before it is
          // fully unrolled; fading for the whole travel makes it a ghost
          // rather than a document.
          opacity: (value * 2).clamp(0.0, 1.0),
          child: ClipRect(clipper: _Unrolled(value), child: child),
        );
      },
      child: _RevealScope(reveal: _reveal, child: widget.child),
    );
  }
}

/// How much of the entry has been unrolled, from the top down.
class _Unrolled extends CustomClipper<Rect> {
  const _Unrolled(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * progress);

  @override
  bool shouldReclip(_Unrolled old) => old.progress != progress;
}

/// How a [RevealOnScroll] child arrives.
enum RevealStyle {
  /// Unrolled from its top edge, like a sheet: text that arrives.
  unroll,

  /// Risen into place from below and the trailing side: a card that arrives.
  rise,
}
