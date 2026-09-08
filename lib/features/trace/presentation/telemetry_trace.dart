import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/wall_painter.dart';
import 'package:nocturne/features/trace/domain/trace_controller.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';
import 'package:nocturne/features/trace/presentation/trace_burst_label.dart';
import 'package:nocturne/features/trace/presentation/trace_frame.dart';

/// Fixed trace layer driven by scroll, with bursts measured after layout.
///
/// Reduced motion keeps the carrier static while following the page offset.
class TelemetryTrace extends ConsumerStatefulWidget {
  /// [controller] is the page scroll the trace reads.
  const TelemetryTrace({
    required this.controller,
    required this.bursts,
    required this.labels,
    required this.anchorRegistry,
    super.key,
  });

  /// The page's scroll controller.
  final ScrollController controller;

  /// Career bursts, already laid out.
  final List<TraceBurst> bursts;

  /// One label per burst, keyed by the burst id.
  final Map<String, TraceLabel> labels;

  /// Resolves the provisional burst geometry against rendered career entries.
  final TraceAnchorRegistry anchorRegistry;

  @override
  ConsumerState<TelemetryTrace> createState() => _TelemetryTraceState();
}

class _TelemetryTraceState extends ConsumerState<TelemetryTrace> {
  /// The idle carrier at the frequency section 5 caps infinite loops to.
  static final Duration _idlePeriod = Duration(
    microseconds: (Duration.microsecondsPerSecond / Tokens.idleTraceFrequency)
        .round(),
  );

  final ValueNotifier<TraceFrame> _frame = ValueNotifier(
    const TraceFrame(offset: 0, velocity: 0, coherence: 1),
  );
  final GlobalKey _traceKey = GlobalKey(debugLabel: 'telemetry-trace');

  Ticker? _ticker;
  double _lastOffset = 0;
  Duration _lastTick = Duration.zero;
  Duration _sinceScroll = Duration.zero;
  bool? _isSettled;
  bool _measurementScheduled = false;
  List<TraceBurst>? _measuredBursts;

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
      _frame.value = TraceFrame(
        offset: widget.controller.hasClients ? widget.controller.offset : 0,
        velocity: 0,
        coherence: 1,
      );
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
    if (_isSettled ?? false) {
      _frame.value = TraceFrame(
        offset: widget.controller.offset,
        velocity: 0,
        coherence: 1,
      );
    }
  }

  /// Pauses the idle carrier when the document is outside the viewport.
  bool get _isOnScreen {
    if (!widget.controller.hasClients) return true;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    if (height <= 0) return true;
    return position.pixels < height &&
        position.pixels + position.viewportDimension > 0;
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (delta <= Duration.zero) return;
    if (!_isOnScreen) return;

    final offset = widget.controller.hasClients
        ? widget.controller.position.pixels
        : 0.0;
    final seconds = delta.inMicroseconds / Duration.microsecondsPerSecond;
    final velocity = (offset - _lastOffset) / seconds;
    _lastOffset = offset;
    _sinceScroll += delta;

    final coherence = TraceGeometry.coherenceFor(velocity);
    _frame.value = TraceFrame(
      offset: offset,
      velocity: velocity,
      coherence: coherence,
      phase: (elapsed.inMicroseconds / _idlePeriod.inMicroseconds) % 1,
    );
    _publish(
      TraceGeometry.stateFor(
        velocity: velocity,
        sinceLastScroll: _sinceScroll,
        nearestBurstDistance: _nearestBurst(offset)?.distance,
      ),
    );
  }

  /// Uses provisional positions only until the career's first layout finishes.
  List<TraceBurst> _anchoredBursts() {
    final measured = _measuredBursts;
    if (measured != null) return measured;
    if (!widget.controller.hasClients) return widget.bursts;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    if (height <= 0) return widget.bursts;
    return TraceGeometry.withinRange(
      widget.bursts,
      start: position.viewportDimension / height,
    );
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted || !widget.controller.hasClients) return;
      final traceContext = _traceKey.currentContext;
      if (traceContext == null) return;
      final position = widget.controller.position;
      // Both sibling layers must finish layout before their coordinates agree,
      // including after text reflow or a viewport resize.
      final measured = widget.anchorRegistry.resolve(
        bursts: widget.bursts,
        traceContext: traceContext,
        scrollOffset: position.pixels,
        traceHeight: position.maxScrollExtent + position.viewportDimension,
      );
      if (measured == null || listEquals(measured, _measuredBursts)) return;
      _measuredBursts = measured;
      final frame = _frame.value;
      _frame.value = TraceFrame(
        offset: position.pixels,
        velocity: frame.velocity,
        coherence: frame.coherence,
        phase: frame.phase,
      );
    });
  }

  /// Distance from the viewport centre using the last completed layout.
  ({String id, double distance})? _nearestBurst(double offset) {
    if (!widget.controller.hasClients) return null;
    final position = widget.controller.position;
    final height = position.maxScrollExtent + position.viewportDimension;
    final centre = offset + position.viewportDimension / 2;
    ({String id, double distance})? nearest;
    for (final burst in _anchoredBursts()) {
      final distance = (burst.anchor * height - centre).abs();
      if (nearest == null || distance < nearest.distance) {
        nearest = (id: burst.id, distance: distance);
      }
    }
    return nearest;
  }

  String? _lockedBurstId(double offset) {
    final nearest = _nearestBurst(offset);
    return nearest != null && nearest.distance <= Tokens.traceLockDistance
        ? nearest.id
        : null;
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

  /// How wide the wall may be without touching the content column.
  double _columnWidth(
    BuildContext context,
    double available, {
    required bool isCompact,
  }) {
    if (isCompact) return available * Tokens.traceColumnFractionCompact;
    final reserved =
        context.platform.gutter +
        context.type.measureFor(context.type.body) +
        Tokens.space48;
    final remaining = available - reserved;
    final floor = available * Tokens.traceColumnFractionMinimum;
    final ceiling = available * Tokens.traceColumnFraction;
    return math.min(ceiling, math.max(floor, remaining));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSettled = ReducedMotion.of(context);
    final isCompact = context.platform.viewport == ViewportClass.compact;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          // The wall runs down the trailing part of the page, and must never
          // reach the content column. A fixed fraction cannot promise that:
          // at 1024px the trailing 66 per cent began at x=348 while the hero
          // text ran to x=636, so register rules and signs were drawn straight
          // through the copy. The owner reported it as overlapping content and
          // he was right.
          //
          // So it is computed instead. The wall takes whatever is left after
          // the gutter, the body measure and a clear gap, and never less than
          // a minimum -- below which it would be a sliver rather than a wall,
          // and on a phone it keeps its own narrow strip because a phone's
          // text column has no measure to clear.
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            key: _traceKey,
            width: _columnWidth(
              context,
              constraints.maxWidth,
              isCompact: isCompact,
            ),
            height: constraints.maxHeight,
            child: ValueListenableBuilder<TraceFrame>(
              valueListenable: _frame,
              builder: (context, frame, _) {
                final position = widget.controller.hasClients
                    ? widget.controller.position
                    : null;
                final traceHeight = position == null
                    ? constraints.maxHeight
                    : position.maxScrollExtent + position.viewportDimension;
                _scheduleMeasurement();
                final bursts = _anchoredBursts();
                final lockedBurstId = _lockedBurstId(frame.offset);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: WallPainter(
                          bursts: bursts,
                          phase: frame.phase,
                          coherence: isSettled ? 1 : frame.coherence,
                          scrollOffset: frame.offset,
                          viewportHeight: constraints.maxHeight,
                          wallHeight: traceHeight,
                          restColour: tokens.instrumentDim,
                          lockedColour: tokens.instrument,
                          peakColour: tokens.beacon,
                          strokeWidth: tokens.hairlineWidth,
                        ),
                      ),
                    ),
                    // No labels on a phone. They are a readout drawn inside
                    // the trace column, which only has room for them beside a
                    // measure-limited text column; on a narrow strip they wrap
                    // over the copy, which is what the owner reported as the
                    // trace and its titles overlapping the text.
                    //
                    // Nothing is lost by dropping them: each label repeats the
                    // company, dates and country that the career entry it is
                    // anchored to already prints, in full, a few pixels away.
                    if (!isCompact)
                      for (final burst in bursts)
                        TraceBurstLabel(
                          label: widget.labels[burst.id],
                          top:
                              burst.anchor * traceHeight -
                              frame.offset -
                              Tokens.space48,
                          // Under reduced motion every label stays visible,
                          // because there is no lock state to reveal them.
                          isVisible: isSettled || lockedBurstId == burst.id,
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
