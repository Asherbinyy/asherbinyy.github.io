import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// The climb, playing itself: the door to the courtyard shows the game
/// rather than describing it.
///
/// A practice run (falling is survivable, so it never ends) steered by the
/// same simple climber the test vectors use: aim for the lowest ledge above
/// from the ground, jump on landing, hold while rising. It runs only while it
/// can be seen, and under reduced motion it is the first frame, still.
class LiveClimb extends StatefulWidget {
  /// Draws the climb at [height].
  const LiveClimb({required this.height, super.key});

  /// How tall the window onto the shaft is.
  final double height;

  @override
  State<LiveClimb> createState() => _LiveClimbState();
}

class _LiveClimbState extends State<LiveClimb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final GlobalKey _key = GlobalKey(debugLabel: 'live-climb');
  AscentWorld _world = _fresh();
  Duration _last = Duration.zero;
  double _debt = 0;
  double _time = 0;
  bool _leaping = false;
  int? _target;
  ScrollController? _scroll;
  bool _isOnScreen = false;

  static AscentWorld _fresh() => AscentWorld.seeded(
    best: 0,
    isPractice: true,
    seed: Tokens.courtyardStillSeed,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = ChromeScrollScope.maybeOf(context)?.controller;
    if (scroll != _scroll) {
      _scroll?.removeListener(_check);
      _scroll = scroll?..addListener(_check);
    }
    _update();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_check);
    _ticker.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject();
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box is! RenderBox || !box.hasSize || viewport == null) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final onScreen = top + box.size.height > 0 && top < viewport.size.height;
    if (onScreen == _isOnScreen) return;
    _isOnScreen = onScreen;
    _update();
  }

  void _update() {
    final shouldRun = _isOnScreen && !ReducedMotion.of(context);
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    _time += dt;
    _debt += dt;
    var world = _world;
    while (_debt >= AscentContract.tickSeconds) {
      _debt -= AscentContract.tickSeconds;
      world = _step(world);
    }
    // A long way up, start again from the floor, so the loop stays near the
    // part of the shaft that reads best at this size.
    if (world.altitude > Tokens.liveClimbRestart) {
      world = _fresh();
      _target = null;
    }
    setState(() => _world = world);
  }

  AscentWorld _step(AscentWorld world) {
    if (world.isGrounded) {
      _target = null;
      for (final ledge in world.ledges) {
        if (!ledge.isBroken && ledge.y > world.climberY + 0.3) {
          _target = ledge.id;
          break;
        }
      }
    }
    var targetX = 0.5;
    for (final ledge in world.ledges) {
      if (ledge.id == _target) targetX = ledge.x;
    }
    final offset = targetX - world.climberX;
    final steer = offset.abs() < 0.01
        ? 0.0
        : offset < 0
        ? -1.0
        : 1.0;
    _leaping = world.isGrounded || (_leaping && world.velocity > 0);
    return world.step(
      dt: AscentContract.tickSeconds,
      steer: steer,
      isLeaping: _leaping,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: ClipRRect(
        key: _key,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: AscentPainter(
                world: _world,
                entrance: 1,
                time: _time,
                stone: tokens.instrument,
                cracked: tokens.instrumentDim,
                gold: tokens.beacon,
                glow: tokens.beaconGlow,
                wall: tokens.hairline,
                chamber: tokens.surfaceRaised,
                pier: tokens.void_,
                strokeWidth: tokens.hairlineWidth,
                isReducedMotion: ReducedMotion.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
