import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_audio.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_controls.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// The climb, inside the courtyard.
///
/// An arcade game and nothing else. It carried a list of career facts while it
/// lived on its own route, which made it a CV delivery mechanism wearing a
/// game's clothes; the owner cut that, and the game is better for having one
/// job. Nothing here is gated behind reflexes because nothing here is content.
class AscentScreen extends ConsumerStatefulWidget {
  /// Creates the climb.
  const AscentScreen({super.key});

  @override
  ConsumerState<AscentScreen> createState() => _AscentScreenState();
}

class _AscentScreenState extends ConsumerState<AscentScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Tokens.considered,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'ascent');
  final AscentAudio _audio = AscentAudio();

  AscentWorld? _world;
  Duration _last = Duration.zero;
  double _steer = 0;
  bool _leap = false;
  bool _dive = false;
  int _bands = 0;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  void _onTick(Duration elapsed) {
    final world = _world;
    if (world == null) return;
    final dt = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;
    // A long frame, a resumed tab or a loaded machine must not teleport the
    // climber through a ledge. Clamping is what keeps collision honest.
    final step = dt.clamp(0.0, 1 / 30);

    final before = world;
    final next = world.step(
      dt: step,
      steer: _steer,
      isLeaping: _leap,
      isDiving: _dive,
    );

    // Sound is driven off what changed between two frames rather than from
    // inside the physics, which stays a pure function with no idea a speaker
    // exists.
    if (next.velocity > 0 && before.velocity <= 0) {
      _audio.play(AscentSound.bounce);
    }
    if (next.brokeLedge) _audio.play(AscentSound.breaking);
    final bands = next.registersPassed;
    if (bands > _bands) _audio.play(AscentSound.collect);
    _bands = bands;
    if (next.isOver && !before.isOver) {
      _audio.play(AscentSound.fall);
      _best = next.metres > _best ? next.metres : _best;
      _ticker.stop();
    }

    setState(() => _world = next);
  }

  Future<void> _start({required bool isPractice}) async {
    // The first gesture is what lets a browser play anything at all, so the
    // players are built here rather than on mount.
    await _audio.prime();
    _audio.play(AscentSound.start);

    _last = Duration.zero;
    _bands = 0;
    setState(() {
      _world = AscentWorld.seeded(
        best: _best,
        isPractice: isPractice,
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
    // Arrows and WASD both, because a player reaches for whichever their
    // hands already know. Space and up are the same key: leaping is the only
    // thing "up" could mean in a climber.
    final left = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
    final right = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};
    final leap = {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.space,
    };
    final dive = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};

    final key = event.logicalKey;
    final isDown = event is! KeyUpEvent;

    if (left.contains(key)) {
      _steer = isDown ? -1 : 0;
      return KeyEventResult.handled;
    }
    if (right.contains(key)) {
      _steer = isDown ? 1 : 0;
      return KeyEventResult.handled;
    }
    if (leap.contains(key)) {
      _leap = isDown;
      return KeyEventResult.handled;
    }
    if (dive.contains(key)) {
      _dive = isDown;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final world = _world;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Tokens.ascentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Shaft(
                world: world,
                entrance: _entrance,
                focus: _focus,
                onKey: _onKey,
              ),
              AscentControls(
                onChanged: (input) {
                  _steer = input.steer;
                  _leap = input.leap;
                  _dive = input.dive;
                },
              ),
              if (context.platform.isPointer) ...[
                SizedBox(height: tokens.space12),
                Text(
                  l10n.ascentKeys,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
              SizedBox(height: tokens.space16),
              Wrap(
                spacing: tokens.space16,
                runSpacing: tokens.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BeaconButton(
                    label: world == null
                        ? l10n.ascentBegin
                        : (world.isOver
                              ? l10n.ascentAgain
                              : l10n.ascentRestart),
                    emphasis: ButtonEmphasis.primary,
                    onPressed: () => _start(isPractice: false),
                  ),
                  BeaconButton(
                    label: l10n.ascentPractice,
                    onPressed: () => _start(isPractice: true),
                  ),
                  BeaconButton(
                    label: _audio.isMuted
                        ? l10n.ascentSoundOn
                        : l10n.ascentSoundOff,
                    onPressed: () => setState(_audio.toggleMute),
                  ),
                  if (world != null)
                    Text(
                      l10n.ascentAltitude(world.metres),
                      style: context.type.telemetry.copyWith(
                        color: tokens.instrument,
                      ),
                    ),
                  if (_best > 0)
                    Text(
                      l10n.ascentBest(_best),
                      style: context.type.telemetryS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The playfield, and the way in.
class _Shaft extends StatelessWidget {
  const _Shaft({
    required this.world,
    required this.entrance,
    required this.focus,
    required this.onKey,
  });

  final AscentWorld? world;
  final Animation<double> entrance;
  final FocusNode focus;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final live = world;

    return InstrumentPanel(
      fill: tokens.surface,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRect(
          child: Focus(
            focusNode: focus,
            onKeyEvent: onKey,
            child: Semantics(
              label: context.l10n.ascentCanvasLabel,
              child: live == null
                  ? Center(
                      child: Text(
                        context.l10n.ascentReady,
                        style: context.type.body.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: entrance,
                      builder: (context, _) => CustomPaint(
                        painter: AscentPainter(
                          world: live,
                          entrance: entrance.value,
                          stone: tokens.instrument,
                          cracked: tokens.instrumentDim,
                          gold: tokens.beacon,
                          glow: tokens.beaconGlow,
                          wall: tokens.hairline,
                          strokeWidth: tokens.hairlineWidth,
                          isReducedMotion: ReducedMotion.of(context),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
