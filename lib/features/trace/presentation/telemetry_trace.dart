import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/chrome/pointer_beacon.dart';
import 'package:nocturne/app/theme/tokens.dart';
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
  ///
  /// Held, not drawn, since the wall became the page's background on a wide
  /// screen (2026-09-23): there is no clear ground beside it for a card any
  /// more, and every career card prints its own location. A phone never had
  /// room for them. Kept so the column layout can come back without anyone
  /// reconstructing where each stop was.
  final Map<String, TraceLabel> labels;

  /// Resolves the provisional burst geometry against rendered career entries.
  final TraceAnchorRegistry anchorRegistry;

  /// How much of a compact page's trailing edge the wall occupies.
  ///
  /// On a phone the copy fills the width, so unlike the desk layout it does not
  /// clear the wall by being measure-limited. Without this the trailing
  /// quarter of every line -- the name, the flags, the CV button -- ran under
  /// the carved signs. The page reserves exactly this much, from this one
  /// definition, so the two cannot drift apart.
  static double compactFootprint(double available) =>
      available * Tokens.traceColumnFractionCompact;

  @override
  ConsumerState<TelemetryTrace> createState() => _TelemetryTraceState();
}

class _TelemetryTraceState extends ConsumerState<TelemetryTrace>
    with SingleTickerProviderStateMixin {
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

  /// Where the light is, and where it last was.
  ///
  /// The second outlives the first: when the light leaves the column it has to
  /// die down somewhere, and the place it was last held is the only honest
  /// answer. Snapping the pool to the origin would throw the gold across the
  /// top of the wall on the way out.
  final ValueNotifier<Offset?> _torchAt = ValueNotifier(null);
  ValueNotifier<Offset?>? _beacon;
  bool _isTorchLit = false;
  late final AnimationController _torchFade = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (Tokens.wallTorchFade * Duration.millisecondsPerSecond)
          .round(),
    ),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final beacon = PointerBeacon.notifierOf(context);
    if (beacon != _beacon) {
      _beacon?.removeListener(_onPointer);
      _beacon = beacon?..addListener(_onPointer);
    }

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
    _beacon?.removeListener(_onPointer);
    _torchAt.dispose();
    _torchFade.dispose();
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    _sinceScroll = Duration.zero;
    _aimTouchTorch();
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

  void _publish(TraceState state) {
    final controller = ref.read(traceControllerProvider.notifier);
    if (controller.current == state) return;
    // Scheduled clear of the frame: a ticker callback runs inside the frame
    // pipeline, and Riverpod forbids modifying a provider during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.current = state;
    });
  }

  /// How wide the wall is.
  ///
  /// On a phone, a strip down the trailing edge that the page reserves. On
  /// anything wider, all of it: the owner asked for the wall to stop filling
  /// the right-hand side of a desk screen and to become the pattern behind the
  /// whole page instead, less visible, with the right of the hero given to a
  /// picture. The copy sits on cards, so it no longer needs a column of its
  /// own to stay legible.
  double _columnWidth(double available, {required bool isCompact}) =>
      isCompact ? TelemetryTrace.compactFootprint(available) : available;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSettled = ReducedMotion.of(context);
    final isCompact = context.platform.viewport == ViewportClass.compact;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = _columnWidth(
          constraints.maxWidth,
          isCompact: isCompact,
        );

        return Align(
          // A strip down the trailing edge on a phone; the whole page behind
          // everything else on a wider screen. See [_columnWidth].
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            key: _traceKey,
            width: columnWidth,
            height: constraints.maxHeight,
            child: IgnorePointer(
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

                  final wall = RepaintBoundary(
                    child: AnimatedBuilder(
                      // Both halves of the light: how far it has come
                      // up, and where the hand is holding it.
                      animation: Listenable.merge([_torchFade, _torchAt]),
                      builder: (context, _) => CustomPaint(
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
                          stoneColour: tokens.hairline,
                          carveShadow: tokens.void_,
                          carveLight: tokens.ornamentField,
                          torch: _torchAt.value,
                          torchStrength: _torchFade.value,
                          // Faint behind the page on a wide screen, full
                          // under the torch; full everywhere on a phone,
                          // where the wall keeps a strip of its own.
                          restAlpha: isCompact ? 1 : Tokens.wallPatternOpacity,
                        ),
                      ),
                    ),
                  );
                  return wall;
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// The pointer moved: aim the light, and bring it up or let it die down.
  void _onPointer() {
    if (!mounted) return;
    // Touch has its own light, carried by the scroll, and these two must not
    // both own `_isTorchLit`. They did: the beacon still fires on a touch
    // device -- a browser synthesises mouse events from taps -- and this
    // handler, reading `null` for the hand, concluded the light had left the
    // wall and reversed the flame that `_aimTouchTorch` had just brought up.
    // The torch came on and went straight back off, which measured as a wall
    // 0.5 of a colour channel warmer than a dark one.
    if (!context.platform.isPointer) return;
    final torch = _torchInLocalSpace(_beacon?.value);
    if (torch != null) _torchAt.value = torch;

    final wanted = torch != null;
    if (wanted == _isTorchLit) return;
    _isTorchLit = wanted;
    if (ReducedMotion.of(context)) {
      // No flame under reduced motion: the light is on or it is not.
      _torchFade.value = wanted ? 1 : 0;
      return;
    }
    wanted ? _torchFade.forward() : _torchFade.reverse();
  }

  /// The torch a phone gets: the reading position, instead of a hand.
  ///
  /// The conceit of this column is somebody holding a light up to a wall, and
  /// on a phone nobody is — there is no pointer, so `_onPointer` never fires,
  /// the flame never comes up, and the signs sit at their resting colour for
  /// the whole page. The gilded ones breathe on their own, which is why it did
  /// not read as broken; it read as flat.
  ///
  /// So on touch the light is held at the middle of the viewport and the wall
  /// moves past it, which is the same gesture as carrying a lamp along an
  /// inscription and the only one a phone has. It follows the scroll rather
  /// than the finger deliberately: a finger is on the wall for a few hundred
  /// milliseconds of a flick and gone, and a light that only exists while you
  /// are touching the screen is a light you never see, because your thumb is
  /// over it.
  void _aimTouchTorch() {
    if (!mounted || context.platform.isPointer) return;
    final box = _traceKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    // The middle of the wall's own box, which *is* the middle of the viewport.
    //
    // This layer is painted viewport-sized and fixed, with the scroll offset
    // handed to the painter rather than to the layout -- so its own pixel space
    // starts at the top of the screen and never moves. The first version of
    // this measured the box against the enclosing `Scrollable` instead, which
    // returns null here because there is no scrollable above a fixed layer; it
    // bailed on every call and lit nothing at all. Two screenshots with
    // identical gold counts is what caught it, because the wall's gilded signs
    // breathe on their own and a lit wall and a dark one look much the same
    // until you count the pixels.
    //
    // So the light stands still and the inscription travels past it, which is
    // the gesture this was after in the first place.
    final lit = box.size.height > 0;
    if (lit) {
      _torchAt.value = Offset(box.size.width / 2, box.size.height / 2);
    }

    if (lit == _isTorchLit) return;
    _isTorchLit = lit;
    // Capped rather than full. See `Tokens.wallTorchTouchPeak`: on a phone the
    // wall is behind the reading rather than beside it, so a light held at the
    // reading position lands on the words.
    final peak = context.platform.viewport == ViewportClass.compact
        ? Tokens.wallTorchTouchPeak
        : 1.0;
    if (ReducedMotion.of(context)) {
      _torchFade.value = lit ? peak : 0;
      return;
    }
    lit ? _torchFade.animateTo(peak) : _torchFade.reverse();
  }

  /// Turns a global pointer position into this wall's own pixels.
  ///
  /// Null once it is outside the column, so the light goes out when the
  /// viewer's hand leaves the wall rather than clinging to its edge.
  Offset? _torchInLocalSpace(Offset? global) {
    if (global == null) return null;
    final box = _traceKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    final within =
        local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= box.size.width &&
        local.dy <= box.size.height;
    return within ? local : null;
  }
}
