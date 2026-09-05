import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/trace_painter.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/trace/domain/trace_controller.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';

/// What a burst says when the signal locks onto it.
typedef TraceLabel = ({String id, String title, String meta});

/// The telemetry trace: the site's signature element.
///
/// Section 6: one painted path driven by a single controller and the scroll
/// offset, degrading toward noise as scroll velocity rises and resolving under
/// lock. It runs behind the content column rather than inside the scroll view,
/// so the painter knows the visible window and can sample only that.
///
/// Under reduced motion it renders static at rest amplitude with every burst
/// label visible and no state machine at all, which is the settled state the
/// design system requires rather than a disabled animation.
class TelemetryTrace extends ConsumerStatefulWidget {
  /// [controller] is the page scroll the trace reads.
  const TelemetryTrace({
    required this.controller,
    required this.bursts,
    required this.labels,
    super.key,
  });

  /// The page's scroll controller.
  final ScrollController controller;

  /// Career bursts, already laid out.
  final List<TraceBurst> bursts;

  /// One label per burst, keyed by the burst id.
  final Map<String, TraceLabel> labels;

  @override
  ConsumerState<TelemetryTrace> createState() => _TelemetryTraceState();
}

class _TelemetryTraceState extends ConsumerState<TelemetryTrace> {
  /// The idle carrier at the frequency section 5 caps infinite loops to.
  static final Duration _idlePeriod = Duration(
    microseconds: (Duration.microsecondsPerSecond / Tokens.idleTraceFrequency)
        .round(),
  );

  final ValueNotifier<_TraceFrame> _frame = ValueNotifier(
    const _TraceFrame(offset: 0, velocity: 0, coherence: 1),
  );

  Ticker? _ticker;
  double _lastOffset = 0;
  Duration _lastTick = Duration.zero;
  Duration _sinceScroll = Duration.zero;
  bool? _isSettled;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settled = ReducedMotion.of(context);
    if (settled == _isSettled) return;
    _isSettled = settled;
    _ticker?.dispose();
    _ticker = null;
    if (settled) {
      // No state machine under reduced motion: the trace is simply at rest.
      _frame.value = const _TraceFrame(offset: 0, velocity: 0, coherence: 1);
      _publish(TraceState.standby);
      return;
    }
    _ticker = Ticker(_onTick)..start();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    _sinceScroll = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (delta <= Duration.zero) return;

    final offset = widget.controller.hasClients
        ? widget.controller.position.pixels
        : 0.0;
    final seconds = delta.inMicroseconds / Duration.microsecondsPerSecond;
    final velocity = (offset - _lastOffset) / seconds;
    _lastOffset = offset;
    _sinceScroll += delta;

    final coherence = TraceGeometry.coherenceFor(velocity);
    _frame.value = _TraceFrame(
      offset: offset,
      velocity: velocity,
      coherence: coherence,
      phase: (elapsed.inMicroseconds / _idlePeriod.inMicroseconds) % 1,
    );
    _publish(
      TraceGeometry.stateFor(
        velocity: velocity,
        sinceLastScroll: _sinceScroll,
        nearestBurstDistance: _nearestBurstDistance(offset),
      ),
    );
  }

  /// The bursts, confined to the trace below the hero.
  ///
  /// The career sequence starts one screen down, so the bursts do too — a
  /// burst under the hero would lock the page onto a role nobody can see yet.
  List<TraceBurst> get _anchoredBursts {
    if (!widget.controller.hasClients) return widget.bursts;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    if (height <= 0) return widget.bursts;
    return TraceGeometry.withinRange(
      widget.bursts,
      start: position.viewportDimension / height,
    );
  }

  /// Distance in pixels from the viewport centre to the nearest burst.
  double? _nearestBurstDistance(double offset) {
    if (widget.bursts.isEmpty || !widget.controller.hasClients) return null;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    final centre = offset + position.viewportDimension / 2;
    double? nearest;
    for (final burst in _anchoredBursts) {
      final distance = (burst.anchor * height - centre).abs();
      if (nearest == null || distance < nearest) nearest = distance;
    }
    return nearest;
  }

  String? _lockedBurstId(double offset) {
    if (!widget.controller.hasClients) return null;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    final centre = offset + position.viewportDimension / 2;
    String? id;
    var nearest = double.infinity;
    for (final burst in _anchoredBursts) {
      final distance = (burst.anchor * height - centre).abs();
      if (distance < nearest) {
        nearest = distance;
        id = burst.id;
      }
    }
    return nearest <= Tokens.traceLockDistance ? id : null;
  }

  void _publish(TraceState state) {
    final controller = ref.read(traceControllerProvider.notifier);
    if (controller.current == state) return;
    // Scheduled clear of the frame: a ticker callback runs inside the frame
    // pipeline, and Riverpod forbids modifying a provider during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.current = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSettled = ReducedMotion.of(context);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          // Section 6 runs the trace down the trailing two-thirds of the page,
          // leaving the content column's own measure clear.
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: constraints.maxWidth * Tokens.traceColumnFraction,
            height: constraints.maxHeight,
            child: ValueListenableBuilder<_TraceFrame>(
              valueListenable: _frame,
              builder: (context, frame, _) {
                final position = widget.controller.hasClients
                    ? widget.controller.position
                    : null;
                final traceHeight = position == null
                    ? constraints.maxHeight
                    : position.maxScrollExtent + position.viewportDimension;
                final bursts = _anchoredBursts;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: TracePainter(
                          bursts: bursts,
                          phase: frame.phase,
                          coherence: isSettled ? 1 : frame.coherence,
                          scrollOffset: frame.offset,
                          viewportHeight: constraints.maxHeight,
                          traceHeight: traceHeight,
                          restColour: tokens.instrumentDim,
                          lockedColour: tokens.instrument,
                          peakColour: tokens.beaconGlow,
                          strokeWidth: tokens.hairlineWidth,
                        ),
                      ),
                    ),
                    for (final burst in bursts)
                      _BurstLabel(
                        label: widget.labels[burst.id],
                        top:
                            burst.anchor * traceHeight -
                            frame.offset -
                            Tokens.space48,
                        // Under reduced motion every label stays visible,
                        // because there is no lock state to reveal them.
                        isVisible:
                            isSettled ||
                            _lockedBurstId(frame.offset) == burst.id,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One burst's readout, shown while the signal is locked onto it.
class _BurstLabel extends StatelessWidget {
  const _BurstLabel({
    required this.label,
    required this.top,
    required this.isVisible,
  });

  final TraceLabel? label;
  final double top;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final content = label;
    if (content == null) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Positioned(
      top: top,
      left: 0,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: ReducedMotion.duration(context, Motion.standard),
        curve: MotionCurves.emphasized,
        child: InstrumentPanel(
          fill: tokens.surface,
          padding: EdgeInsets.all(tokens.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: context.type.bodyS.copyWith(color: tokens.beacon),
              ),
              Text(content.meta, style: context.type.telemetryS),
            ],
          ),
        ),
      ),
    );
  }
}

/// One frame's worth of trace state, published without rebuilding the page.
@immutable
class _TraceFrame {
  const _TraceFrame({
    required this.offset,
    required this.velocity,
    required this.coherence,
    this.phase = 0,
  });

  final double offset;
  final double velocity;
  final double coherence;
  final double phase;
}
