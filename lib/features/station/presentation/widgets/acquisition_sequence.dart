import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/carrier_painter.dart';
import 'package:nocturne/features/station/domain/acquisition_controller.dart';

/// The one non-triggered animation on the site.
///
/// Four beats over 2400ms, from `02-SCREEN-SPECS.md`:
///
/// 1. 0-600ms   grain fades in, one amber tick at centre;
/// 2. 600-1400  the tick becomes a scan line sweeping outward, monochrome;
/// 3. 1400-2000 the line resolves into the trace baseline, the name types in;
/// 4. 2000-2400 the chrome draws in from its edges.
///
/// It exists because Flutter Web has an unavoidable initial payload, and the
/// choice is a blank screen or a designed one. Any input skips it, and under
/// reduced motion it is a 200ms fade straight to the settled state.
///
/// This widget owns beats one and two, which are pure overlay; the settled
/// content underneath fades up across beats three and four, so nothing moves
/// into place and there is no layout shift when the sequence ends.
typedef AcquisitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> contentReveal,
  Animation<double> chromeReveal,
);

/// Orchestrates the first station visit without changing settled layout.
class AcquisitionSequence extends ConsumerStatefulWidget {
  /// [builder] receives distinct beat-three content and beat-four chrome fades.
  const AcquisitionSequence({required this.builder, super.key});

  /// Builds the settled state without changing its layout during acquisition.
  final AcquisitionBuilder builder;

  @override
  ConsumerState<AcquisitionSequence> createState() =>
      _AcquisitionSequenceState();
}

class _AcquisitionSequenceState extends ConsumerState<AcquisitionSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Tokens.acquisition,
  );

  /// Beat one: the amber tick appears.
  late final CurvedAnimation _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      Tokens.zero,
      Tokens.acquisitionBeatOne,
      curve: MotionCurves.emphasized,
    ),
  );

  /// Beat two: the tick sweeps outward to full width.
  late final CurvedAnimation _sweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      Tokens.acquisitionBeatOne,
      Tokens.acquisitionBeatTwo,
      curve: MotionCurves.emphasized,
    ),
  );

  /// Beat three: the baseline and hero content resolve.
  late final CurvedAnimation _contentReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      Tokens.acquisitionBeatTwo,
      Tokens.acquisitionBeatThree,
      curve: MotionCurves.emphasized,
    ),
  );

  /// Beat four: header, rail and footer draw from their edges.
  late final CurvedAnimation _chromeReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      Tokens.acquisitionBeatThree,
      1,
      curve: MotionCurves.emphasized,
    ),
  );

  /// Reduced motion is one 200ms fade with no scan or staged movement.
  late final CurvedAnimation _reducedReveal = CurvedAnimation(
    parent: _controller,
    curve: MotionCurves.emphasized,
  );

  bool _hasStarted = false;
  bool _usesReducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;

    if (ref.read(acquisitionPlayedProvider)) {
      _finish();
      return;
    }
    _usesReducedMotion = ReducedMotion.of(context);
    if (_usesReducedMotion) {
      _controller.duration = Tokens.reducedAcquisition;
    }
    _controller.forward().whenComplete(_finish);
  }

  @override
  void dispose() {
    _tick.dispose();
    _sweep.dispose();
    _contentReveal.dispose();
    _chromeReveal.dispose();
    _reducedReveal.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Ends the sequence, whether it ran to completion or was skipped.
  ///
  /// The provider write is scheduled clear of the current frame. This path is
  /// reached from `didChangeDependencies` when the sequence has already played
  /// or motion is reduced, and Riverpod forbids modifying a provider during
  /// build — doing so throws and takes the whole subtree down with it.
  void _finish() {
    _controller.value = 1;
    if (ref.read(acquisitionPlayedProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(acquisitionPlayedProvider.notifier).markPlayed();
    });
  }

  void _skip() {
    if (_controller.isAnimating) {
      _controller.stop();
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isPlayed = ref.watch(acquisitionPlayedProvider);
    const complete = AlwaysStoppedAnimation<double>(1);
    final content = widget.builder(
      context,
      _usesReducedMotion ? complete : _contentReveal,
      _usesReducedMotion ? complete : _chromeReveal,
    );
    final settled = _usesReducedMotion
        ? FadeTransition(opacity: _reducedReveal, child: content)
        : content;

    return Semantics(
      liveRegion: !isPlayed,
      label: isPlayed ? null : context.l10n.acquisitionLabel,
      child: Focus(
        autofocus: !isPlayed,
        // Any input skips it: a key, a pointer down, or a tap.
        onKeyEvent: (node, event) {
          _skip();
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: (_) => _skip(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              settled,
              if (!isPlayed && !_usesReducedMotion)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _ScanLinePainter(
                        tick: _tick.value,
                        sweep: _sweep.value,
                        settle: _contentReveal.value,
                        beacon: tokens.beacon,
                        instrument: tokens.instrumentDim,
                        hairlineWidth: tokens.hairlineWidth,
                        textDirection: Directionality.of(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Beats one and two: an amber tick that becomes a monochrome scan line.
class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({
    required this.tick,
    required this.sweep,
    required this.settle,
    required this.beacon,
    required this.instrument,
    required this.hairlineWidth,
    required this.textDirection,
  });

  final double tick;
  final double sweep;
  final double settle;
  final Color beacon;
  final Color instrument;
  final double hairlineWidth;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || settle >= 1) return;

    final centre = Offset(size.width / 2, size.height / 2);
    // The tick is amber and alone; as it sweeps it hands over to monochrome,
    // so the one chroma marks the moment of acquisition and nothing after it.
    final colour = Color.lerp(beacon, instrument, sweep) ?? instrument;
    final paint = Paint()
      ..color = colour.withValues(alpha: 1 - settle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairlineWidth * 2
      ..strokeCap = StrokeCap.round;

    // Beat one is a mark at the centre; beat two extends it to the full width.
    final half = (hairlineWidth * 2 * tick) + (size.width / 2 * sweep);
    if (half <= 0) return;

    canvas.drawLine(
      Offset(centre.dx - half, centre.dy),
      Offset(centre.dx + half, centre.dy),
      paint,
    );

    // Beat three: the flat line resolves into the carrier the trace is built
    // from, so the sequence hands directly to the page's own waveform.
    if (sweep < 1 || settle <= 0) return;
    CarrierPainter(
      phase: 0,
      colour: colour.withValues(alpha: 1 - settle),
      strokeWidth: hairlineWidth * 2,
      textDirection: textDirection,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.tick != tick ||
      oldDelegate.sweep != sweep ||
      oldDelegate.settle != settle ||
      oldDelegate.beacon != beacon ||
      oldDelegate.instrument != instrument ||
      oldDelegate.textDirection != textDirection;
}
