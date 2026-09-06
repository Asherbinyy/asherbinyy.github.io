import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/carrier_painter.dart';

/// The indeterminate loader, and the carrier-at-rest used by empty states.
///
/// Section 11 rules out a spinner outright — it is the most generic element
/// available and would undo the rest of the system. This is a 32x12 miniature
/// of the telemetry trace instead, drawn by the same curve function.
class CarrierLoader extends StatefulWidget {
  /// [label] overrides the announced text where a region names what it awaits.
  const CarrierLoader({this.label, super.key});

  /// Screen-reader announcement; defaults to the generic loading string.
  final String? label;

  @override
  State<CarrierLoader> createState() => _CarrierLoaderState();
}

class _CarrierLoaderState extends State<CarrierLoader>
    with SingleTickerProviderStateMixin {
  /// One oscillation at the specified frequency, derived from the token rather
  /// than restating the period as a second value that could drift from it.
  static final Duration _period = Duration(
    microseconds: (Duration.microsecondsPerSecond / Tokens.loaderFrequency)
        .round(),
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  bool? _isSettled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settled = ReducedMotion.of(context);
    if (settled == _isSettled) return;
    _isSettled = settled;
    if (settled) {
      // The carrier still reads as a waveform at rest, so the state remains
      // perceivable without motion as section 11 requires.
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final direction = Directionality.of(context);
    return Semantics(
      liveRegion: true,
      label: widget.label ?? context.l10n.loading,
      child: SizedBox(
        width: tokens.loaderWidth,
        height: tokens.loaderHeight,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size(tokens.loaderWidth, tokens.loaderHeight),
              painter: CarrierPainter(
                phase: _controller.value,
                // The burst travels with the phase, so the loader reads as a
                // signal passing through rather than a looping squiggle.
                burstCentre: _controller.value,
                colour: tokens.instrumentDim,
                strokeWidth: tokens.hairlineWidth,
                textDirection: direction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
