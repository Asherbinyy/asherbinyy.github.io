import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_audio.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_controls.dart';
import 'package:nocturne/features/courtyard/game/presentation/game_control.dart';

/// The climb, played full screen.
///
/// It used to be a boxed canvas inside the scrolling page, and that was the
/// cause of three separate complaints rather than one. Space did not leap, it
/// scrolled the document, because a browser gives space to the scroller and the
/// game was sitting in one. The shaft could not use the window, because it was
/// a 520px column in a text layout. And the controls read as page furniture,
/// because that is exactly what they were.
///
/// A game needs the screen. Pushing an opaque route means there is no scroller
/// behind it to steal a key, no measure to respect, and no page chrome to
/// compete with, and it is also simply what every game does.
class AscentStage extends StatefulWidget {
  /// Opens the stage over the current route.
  const AscentStage({super.key});

  /// Pushes the stage, and restores the page scroll position on the way back.
  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Tokens.considered,
      reverseTransitionDuration: Tokens.quick,
      pageBuilder: (context, animation, _) =>
          FadeTransition(opacity: animation, child: const AscentStage()),
    ),
  );

  @override
  State<AscentStage> createState() => _AscentStageState();
}

class _AscentStageState extends State<AscentStage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Tokens.considered,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'ascent-stage');
  final AscentAudio _audio = AscentAudio();

  AscentWorld? _world;
  Duration _last = Duration.zero;
  double _steer = 0;
  bool _leap = false;
  int _bands = 0;

  /// When the last wall kick happened, in seconds since the ticker started.
  ///
  /// Negative infinity rather than zero: zero is a real moment on the clock,
  /// and a run would open with the flourish already playing.
  double _kickedAt = double.negativeInfinity;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Straight into a run. The owner asked for start and restart and a best
    // score, and nothing else: an empty stage with a Play button on it is one
    // press between him and the thing he came for.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _entrance.dispose();
    _focus.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _ticker.isActive) {
      _ticker.stop();
      setState(() {});
    }
  }

  /// Seconds since the ticker started, for the scene's own motion.
  double _elapsed = 0;

  void _onTick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / 1000000;
    final world = _world;
    if (world == null) return;
    final dt = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;
    final step = dt.clamp(0.0, 1 / 30);

    final before = world;
    final next = world.step(dt: step, steer: _steer, isLeaping: _leap);

    if (next.velocity > 0 && before.velocity <= 0) {
      _audio.play(AscentSound.bounce);
    }
    if (next.brokeLedge) _audio.play(AscentSound.breaking);
    if (next.kickedWall) {
      _kickedAt = _elapsed;
      _audio.play(AscentSound.collect);
    }
    if (next.registersPassed > _bands) _audio.play(AscentSound.collect);
    _bands = next.registersPassed;
    if (next.isOver && !before.isOver) {
      _audio.play(AscentSound.fall);
      if (next.metres > _best) _best = next.metres;
      _ticker.stop();
    }

    setState(() => _world = next);
  }

  Future<void> _start() async {
    await _audio.prime();
    _audio.play(AscentSound.start);

    _last = Duration.zero;
    _bands = 0;
    _kickedAt = double.negativeInfinity;
    _steer = 0;
    _leap = false;
    if (!mounted) return;
    setState(() {
      _world = AscentWorld.seeded(
        best: _best,
        isPractice: false,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
    });
    _focus.requestFocus();
    _entrance
      ..reset()
      ..forward();
    _ticker
      ..stop()
      ..start();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is! KeyUpEvent;

    if (key == LogicalKeyboardKey.escape) {
      if (isDown) Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (_left.contains(key)) {
      _steer = isDown ? -1 : 0;
      return KeyEventResult.handled;
    }
    if (_right.contains(key)) {
      _steer = isDown ? 1 : 0;
      return KeyEventResult.handled;
    }
    if (_leapKeys.contains(key)) {
      _leap = isDown;
      return KeyEventResult.handled;
    }
    // Everything else is swallowed too. Nothing on this route wants a key,
    // and letting one through is how space reached the document before.
    return KeyEventResult.handled;
  }

  /// How long the wall-kick flourish lasts, in seconds.
  static const double _kickFlourish = 0.5;

  static final _left = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
  static final _right = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final _leapKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.space,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final world = _world;

    return Scaffold(
      backgroundColor: tokens.void_,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Semantics(
          label: context.l10n.ascentCanvasLabel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (world != null)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _entrance,
                    builder: (context, _) => CustomPaint(
                      painter: AscentPainter(
                        world: world,
                        entrance: _entrance.value,
                        time: _elapsed,
                        // Normalised over the flourish's own lifetime, so the
                        // painter never has to know what a second is.
                        kickAge: ((_elapsed - _kickedAt) / _kickFlourish).clamp(
                          0.0,
                          1.0,
                        ),
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
              _Hud(
                world: world,
                best: _best,
                isMuted: _audio.isMuted,
                onRestart: _start,
                onMute: () => setState(_audio.toggleMute),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              if (world != null && world.isOver)
                _Over(metres: world.metres, best: _best, onRestart: _start),
              // The pad sits over the shaft on touch, where a thumb can reach
              // it, rather than under a canvas that now fills the window.
              Positioned(
                left: 0,
                right: 0,
                bottom: tokens.space24,
                child: AscentControls(
                  onChanged: (input) {
                    _steer = input.steer;
                    _leap = input.leap;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Altitude, best, and the two controls the owner asked for.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.world,
    required this.best,
    required this.isMuted,
    required this.onRestart,
    required this.onMute,
    required this.onClose,
  });

  final AscentWorld? world;
  final int best;
  final bool isMuted;
  final VoidCallback onRestart;
  final VoidCallback onMute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(tokens.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.ascentAltitude(world?.metres ?? 0),
                  style: type.displayM.copyWith(color: tokens.beacon),
                ),
                Row(
                  children: [
                    // The level, because the floor rising underneath is the
                    // one thing a player needs warning about.
                    Text(
                      l10n.ascentLevel((world?.level ?? 0) + 1),
                      style: type.telemetryS.copyWith(
                        color: tokens.instrumentMid,
                      ),
                    ),
                    if (best > 0) ...[
                      SizedBox(width: tokens.space12),
                      Text(
                        l10n.ascentBest(best),
                        style: type.telemetryS.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Glyphs rather than words. Three labelled buttons ran across the
            // top of the playfield, which is where the climber is heading.
            GameControl.icon(
              glyph: '↻',
              semanticLabel: l10n.ascentAgain,
              onPressed: onRestart,
            ),
            SizedBox(width: tokens.space4),
            GameControl.icon(
              glyph: isMuted ? '🔇' : '🔊',
              semanticLabel: isMuted ? l10n.ascentSoundOn : l10n.ascentSoundOff,
              onPressed: onMute,
            ),
            SizedBox(width: tokens.space4),
            GameControl.icon(
              glyph: '✕',
              semanticLabel: l10n.ascentLeave,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// What a run ended at.
class _Over extends StatelessWidget {
  const _Over({
    required this.metres,
    required this.best,
    required this.onRestart,
  });

  final int metres;
  final int best;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.94),
          border: Border.all(
            color: tokens.hairlineStrong,
            width: tokens.hairlineWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ascentAltitude(metres),
                style: type.displayL.copyWith(color: tokens.beacon),
              ),
              if (metres >= best && best > 0)
                Text(
                  l10n.ascentRecord,
                  style: type.body.copyWith(color: tokens.instrument),
                )
              else if (best > 0)
                Text(
                  l10n.ascentBest(best),
                  style: type.telemetryS.copyWith(color: tokens.textMuted),
                ),
              SizedBox(height: tokens.space24),
              GameControl(
                label: l10n.ascentAgain,
                isPrimary: true,
                onPressed: onRestart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A control that belongs to a game rather than to a document.
///
/// The page's own buttons looked pasted on here, which is the owner's word for
/// it: they are sized and weighted for reading, and this is a HUD.
