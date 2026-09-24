import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/painting/sign_paths.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_audio.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/render_scale.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_run.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_controls.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';
import 'package:nocturne/features/courtyard/game/presentation/game_control.dart';
import 'package:nocturne/features/courtyard/game/presentation/leaderboard_controller.dart';
import 'package:nocturne/features/courtyard/game/presentation/widgets/join_prompt.dart';
import 'package:nocturne/features/courtyard/game/presentation/widgets/leaderboard_panel.dart';

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
class AscentStage extends ConsumerStatefulWidget {
  /// Opens the stage over the current route.
  const AscentStage({super.key});

  /// Pushes the stage, and restores the page scroll position on the way back.
  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: ReducedMotion.duration(context, Tokens.considered),
      reverseTransitionDuration: ReducedMotion.duration(context, Tokens.quick),
      pageBuilder: (context, animation, _) =>
          FadeTransition(opacity: animation, child: const AscentStage()),
    ),
  );

  @override
  ConsumerState<AscentStage> createState() => _AscentStageState();
}

class _AscentStageState extends ConsumerState<AscentStage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Tokens.considered,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'ascent-stage');
  final AscentAudio _audio = AscentAudio();

  AscentSimulation? _run;
  AscentWorld? get _world => _run?.world;
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

  /// Whether the legend has been seen since the site was opened.
  ///
  /// Kept in memory, not on the device: the site writes nothing a player has
  /// not asked it to keep, and seeing the legend once a visit is a small
  /// price for that. The info button brings it back whenever it is wanted.
  static bool _legendSeen = false;

  /// Whether the legend is showing, which holds the climb.
  bool _showsLegend = false;

  /// The last relic taken or life spent, and when, for the line that names
  /// it over the shaft.
  String? Function(BuildContext)? _news;
  double _newsAt = double.negativeInfinity;

  /// The level the climber was in on the last frame, for the sands' sound.
  int _level = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Capped for exactly as long as this stage is open, and given back the
    // moment it closes -- see RenderScale for why a phone needs this and a
    // desktop does not.
    RenderScale.capForGame();
    // Straight into a run. The owner asked for start and restart and a best
    // score, and nothing else: an empty stage with a Play button on it is one
    // press between him and the thing he came for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetched once, here, because this is where somebody might look at it.
      // The board is refreshed again after a submission and on a deliberate
      // retry, and at no other time: a scoreboard that polls a server for as
      // long as a tab is open is a beacon with a table drawn over it.
      unawaited(ref.read(leaderboardControllerProvider.notifier).refresh());
      // The first time, the legend before the climb: what the three signs
      // do, and that there is a summit to reach.
      if (_legendSeen) {
        unawaited(_start());
      } else {
        setState(() => _showsLegend = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RenderScale.restore();
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

  /// How many hundred-metre marks this run has passed, and when the last one
  /// landed, so the banner can fade rather than blink.
  int _rewards = 0;
  double _rewardAt = double.negativeInfinity;

  void _onTick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / 1000000;
    final run = _run;
    if (run == null) return;
    final dt = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;

    final before = run.world;
    // One frame can owe the simulation several ticks. Each is a real moment of
    // the climb -- a landing on the first of them is not cancelled by the
    // second -- so the events are gathered across all of them and the sounds
    // played once, rather than reading only the state the frame ended on.
    var leapt = false;
    var broke = false;
    var kicked = false;
    Relic? took;
    var lostLife = false;
    var previous = before;
    for (final state in run.advance(
      dt.clamp(0.0, 0.25),
      AscentInput.of(steer: _steer, isLeaping: _leap),
    )) {
      leapt |= state.velocity > 0 && previous.velocity <= 0;
      broke |= state.brokeLedge;
      kicked |= state.kickedWall;
      took ??= state.tookRelic;
      lostLife |= state.lostLife;
      previous = state;
    }
    final next = run.world;
    if (identical(next, before)) return;

    if (leapt) _audio.play(AscentSound.bounce);
    if (broke) _audio.play(AscentSound.breaking);
    if (kicked) {
      _kickedAt = _elapsed;
      _audio.play(AscentSound.collect);
    }
    // Each relic has a voice of its own, and a line over the shaft that says
    // what it just did.
    if (took != null) {
      _audio.play(switch (took) {
        Relic.ankh => AscentSound.ankh,
        Relic.eye => AscentSound.eye,
        Relic.feather => AscentSound.feather,
      });
      _news = switch (took) {
        Relic.ankh => (context) => context.l10n.ascentGotAnkh,
        Relic.eye => (context) => context.l10n.ascentGotEye,
        Relic.feather => (context) => context.l10n.ascentGotFeather,
      };
      _newsAt = _elapsed;
    }
    if (lostLife) {
      _audio.play(AscentSound.life);
      _news = (context) => context.l10n.ascentLifeLost;
      _newsAt = _elapsed;
    }
    final level = AscentWorld.levelOf(next.climberY);
    if (level != _level && AscentWorld.isWindy(level)) {
      _audio.play(AscentSound.sand);
    }
    _level = level;
    if (next.registersPassed > _bands) _audio.play(AscentSound.level);
    _bands = next.registersPassed;

    // Every hundred metres is worth marking. The climb had nothing to show for
    // a long run but a number ticking up, which the owner said made it feel
    // unrewarding; this is the moment the shaft acknowledges the player.
    final earned = next.metres ~/ Tokens.ascentRewardStep;
    if (earned > _rewards) {
      _rewards = earned;
      _rewardAt = _elapsed;
      _audio.play(AscentSound.reward);
    }

    if (next.isOver && !before.isOver) {
      _audio.play(
        next.won
            ? AscentSound.win
            : next.metres > _best
            ? AscentSound.record
            : AscentSound.fall,
      );
      if (next.metres > _best) _best = next.metres;
      _ticker.stop();
      // The tape goes up, not the score. What the server ranks is what it
      // reaches replaying these keypresses; `next.metres` is only ever what
      // this screen prints.
      final challenge = _runChallenge;
      _runChallenge = null;
      if (challenge != null && run.isQualifying) {
        unawaited(
          ref
              .read(leaderboardControllerProvider.notifier)
              .finish(challenge: challenge, tape: run.tape.encode()),
        );
      }
      unawaited(_afterRun());
    }

    setState(() {});
  }

  /// The challenge the run in progress is climbing under, if it has one.
  ///
  /// Held here rather than in the controller for the length of a run: this is
  /// the one that will be submitted, and it must not be replaced by the next
  /// one being fetched while the climb is still going.
  RunChallenge? _runChallenge;

  /// Everything the board wants, done between runs rather than before one.
  ///
  /// Both halves of this were originally at the top of `_start`, and both were
  /// wrong there.
  ///
  /// The question was asked before the first climb, which is asking somebody
  /// whether they want to be on a scoreboard for a game they have not played.
  /// Here it is asked with their first height still on the screen, which is the
  /// moment it means something — and only when the board actually answered,
  /// because offering a place on a leaderboard that is not deployed is worse
  /// than not offering one.
  ///
  /// And the challenge was fetched while the player waited to start. A ranked
  /// run needs a server-chosen shaft before its first tick, so that seeds
  /// cannot be shopped for, and a network call in front of the Play button is a
  /// game that is broken whenever the network is slow. Fetching it now means it
  /// is already in hand when they press Climb again.
  Future<void> _afterRun() async {
    final leaderboard = ref.read(leaderboardControllerProvider.notifier);
    if (!leaderboard.isAvailable) return;

    final fetched = ref.read(leaderboardControllerProvider);
    if (fetched.board == null && !fetched.isLoadingBoard) {
      await leaderboard.refresh();
      if (!mounted) return;
    }
    // No board, no offer. Until the Worker has the leaderboard deployed this
    // returns here every time, and the climb is exactly the game it was: no
    // prompt, no panel, nothing asked of anybody.
    if (ref.read(leaderboardControllerProvider).board == null) return;

    if (ref.read(leaderboardControllerProvider).participation is Undecided) {
      final chosen = await JoinPrompt.show(context);
      if (!mounted) return;
      // Dismissing the sheet is not an answer and is not recorded as one. It
      // means the question comes back, which is the only reading of a
      // dismissal that does not put words in somebody's mouth.
      if (chosen != null) await leaderboard.choose(chosen);
      if (!mounted) return;
    }

    if (leaderboard.canTryRanked) await leaderboard.beginRankedRun();
  }

  Future<void> _start() async {
    // Whatever challenge is in hand, if any. Never fetched here: the run starts
    // now, and a climb with no challenge is an ordinary local one.
    final leaderboard = ref.read(leaderboardControllerProvider.notifier);
    var challenge = leaderboard.takeChallenge();
    // None in hand -- the first climb of a visit. Worth a short wait for one,
    // or that climb can never go on the board; not worth a long one, or a
    // slow network is a game that will not start. One that arrives late is
    // kept for the next climb.
    if (challenge == null && leaderboard.canTryRanked) {
      await leaderboard.beginRankedRun().timeout(
        LeaderboardController.firstRunWait,
        onTimeout: () => null,
      );
      if (!mounted) return;
      challenge = leaderboard.takeChallenge();
    }
    _runChallenge =
        challenge != null && challenge.expiresAt.isAfter(DateTime.now())
        ? challenge
        : null;
    leaderboard.clearVerdict();

    await _audio.prime();
    _audio.play(AscentSound.start);

    _last = Duration.zero;
    _bands = 0;
    _rewards = 0;
    _rewardAt = double.negativeInfinity;
    _kickedAt = double.negativeInfinity;
    _news = null;
    _newsAt = double.negativeInfinity;
    _level = 0;
    _steer = 0;
    _leap = false;
    if (!mounted) return;
    setState(() {
      _run = AscentSimulation(
        best: _best,
        seed:
            _runChallenge?.seed ??
            DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF,
      );
    });
    _focus.requestFocus();
    if (ReducedMotion.of(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward(from: 0);
    }
    _ticker
      ..stop()
      ..start();
  }

  /// Shows the legend, holding the climb while it is open.
  void _openLegend() {
    _ticker.stop();
    _steer = 0;
    _leap = false;
    setState(() => _showsLegend = true);
  }

  /// Closes the legend: the first time into a new climb, afterwards back
  /// into the one that was held.
  void _closeLegend() {
    final isFirst = !_legendSeen;
    _legendSeen = true;
    setState(() => _showsLegend = false);
    _focus.requestFocus();
    if (isFirst || _run == null) {
      unawaited(_start());
    } else if (!(_world?.isOver ?? true)) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is! KeyUpEvent;

    if (_showsLegend) {
      if (isDown &&
          (key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.escape)) {
        _closeLegend();
      }
      return KeyEventResult.handled;
    }

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
      // Space is jump while the climb is live and "go again" once it is over.
      // A player who has just fallen has a thumb on the space bar already, and
      // making them reach for the mouse to start again is the wrong end of the
      // keyboard.
      if (isDown && (_world?.isOver ?? false)) {
        unawaited(_start());
        return KeyEventResult.handled;
      }
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
              // Under everything but the picture: the whole screen below the
              // top bar is the controls on touch, and the bar, the results
              // and the legend sit above them and take their own taps.
              if (world != null && !world.isOver && !_showsLegend)
                Positioned.fill(
                  top: tokens.space64 + tokens.space24,
                  child: AscentControls(
                    onChanged: (input) {
                      _steer = input.steer;
                      _leap = input.isLeaping;
                    },
                  ),
                ),
              _Hud(
                world: world,
                best: _best,
                isMuted: _audio.isMuted,
                onRestart: _start,
                onMute: () => setState(_audio.toggleMute),
                onInfo: _openLegend,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              // The board, kept on the left for the length of the climb.
              //
              // The owner asked for it to be always visible and he is right
              // about why: a leaderboard you only meet after you have fallen is
              // a scoreboard, and a leaderboard you can see while you climb is
              // the reason to climb. It reads rather than reacts -- no taps, no
              // retry, nothing that can steal a thumb from the game.
              // A phone is the exception, and not a grudging one: at 390 points
              // the shaft *is* the frame, so a rail would be a panel over the
              // playfield rather than beside it. There it stays where it was,
              // on the results, which is the only place a phone has room.
              if (context.platform.viewport != ViewportClass.compact)
                PositionedDirectional(
                  start: tokens.space16,
                  top: tokens.space64 + tokens.space24,
                  width: Tokens.ascentRailWidth,
                  child: const IgnorePointer(
                    child: LeaderboardPanel(isQuiet: true),
                  ),
                ),
              if (world != null && !world.isOver)
                _RewardMark(
                  metres: _rewards * Tokens.ascentRewardStep,
                  age: (_elapsed - _rewardAt) / Tokens.ascentRewardHold,
                ),
              if (world != null && !world.isOver && _news != null)
                _News(
                  text: _news!(context) ?? '',
                  age: (_elapsed - _newsAt) / Tokens.ascentNewsHold,
                ),
              if (world != null && world.isOver)
                _Over(
                  metres: world.metres,
                  best: _best,
                  won: world.won,
                  onRestart: _start,
                ),
              if (_showsLegend) _Legend(onClose: _closeLegend),
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
    required this.onInfo,
    required this.onClose,
  });

  final AscentWorld? world;
  final int best;
  final bool isMuted;
  final VoidCallback onRestart;
  final VoidCallback onMute;
  final VoidCallback onInfo;
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
                      '${l10n.ascentLevel((world?.level ?? 0) + 1)}  '
                      '${levelName(l10n, world?.level ?? 0)}',
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
                if (world case final world?) ...[
                  SizedBox(height: tokens.space8),
                  _Relics(world: world),
                ],
              ],
            ),
            const Spacer(),
            GameControl.icon(
              glyph: 'i',
              semanticLabel: l10n.ascentHowToPlay,
              onPressed: onInfo,
            ),
            SizedBox(width: tokens.space4),
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

/// What a run ended at, and what the board made of it.
class _Over extends ConsumerWidget {
  const _Over({
    required this.metres,
    required this.best,
    required this.won,
    required this.onRestart,
  });

  final int metres;
  final int best;
  final bool won;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final leaderboard = ref.watch(leaderboardControllerProvider);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.space16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Tokens.boardDialogWidth),
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
                  // The reward at the top of the climb: the golden mask, the
                  // one place the site shows it, earned rather than hung up.
                  if (won) ...[
                    const SizedBox.square(
                      dimension: Tokens.ascentMaskSize,
                      child: CustomPaint(painter: _MaskPainter()),
                    ),
                    SizedBox(height: tokens.space16),
                    Text(
                      l10n.ascentWonTitle,
                      textAlign: TextAlign.center,
                      style: type.heading.copyWith(color: tokens.beacon),
                    ),
                    SizedBox(height: tokens.space8),
                    Text(
                      l10n.ascentWonBody,
                      textAlign: TextAlign.center,
                      style: type.body.copyWith(color: tokens.textSecondary),
                    ),
                    SizedBox(height: tokens.space16),
                  ],
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
                  SizedBox(height: tokens.space12),
                  _VerdictLine(state: leaderboard),
                  SizedBox(height: tokens.space24),
                  GameControl(
                    label: l10n.ascentAgain,
                    isPrimary: true,
                    onPressed: onRestart,
                  ),
                  if (leaderboard.board != null) ...[
                    SizedBox(height: tokens.space24),
                    const LeaderboardPanel(),
                  ],
                  if (leaderboard.participation case final Joined joined) ...[
                    SizedBox(height: tokens.space12),
                    _ParticipantControls(joined: joined),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the server said, or that it has not said yet.
///
/// The one thing this must never print is the number on the screen above it
/// dressed up as a ranking. Until the run has been replayed there is no
/// verified height, and a climb played without joining is simply not a board
/// entry — both of which are said here in words rather than left to be assumed.
class _VerdictLine extends StatelessWidget {
  const _VerdictLine({required this.state});

  final LeaderboardState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    final (String text, Color colour) = switch (state.verdict) {
      VerdictPending() => (l10n.ascentChecking, tokens.textMuted),
      VerdictRejected() => (l10n.ascentUnverified, tokens.textMuted),
      final VerdictChecked checked when checked.isRanked => (
        l10n.ascentCheckedRanked(checked.rank!),
        tokens.beacon,
      ),
      final VerdictChecked checked
          when checked.outcome == 'not-an-improvement' =>
        (l10n.ascentCheckedStands(checked.metres), tokens.textMuted),
      final VerdictChecked checked => (
        l10n.ascentCheckedMissed(checked.metres),
        tokens.textMuted,
      ),
      // A run that was submitted and then stopped being waited on, or a run
      // that was never ranked at all. Both are local results, and saying so is
      // the difference between honest and flattering.
      null when state.pendingRunId != null => (
        l10n.ascentStillChecking,
        tokens.textMuted,
      ),
      null => (l10n.ascentLocalRun, tokens.textMuted),
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: type.telemetryS.copyWith(color: colour),
    );
  }
}

/// Leaving, and changing the name on the way out.
class _ParticipantControls extends ConsumerWidget {
  const _ParticipantControls({required this.joined});

  final Joined joined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      children: [
        Text(
          l10n.ascentPlayingAs(joined.nickname),
          style: context.type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: tokens.space8,
          runSpacing: tokens.space8,
          children: [
            GameControl(
              label: l10n.ascentChangeName,
              onPressed: () async {
                final chosen = await JoinPrompt.show(context);
                if (chosen is Joined) {
                  await ref
                      .read(leaderboardControllerProvider.notifier)
                      .rename(chosen.nickname);
                }
              },
            ),
            GameControl(
              label: l10n.ascentLeaveBoard,
              onPressed: () =>
                  ref.read(leaderboardControllerProvider.notifier).forget(),
            ),
          ],
        ),
      ],
    );
  }
}

/// A control that belongs to a game rather than to a document.
///
/// The page's own buttons looked pasted on here, which is the owner's word for
/// it: they are sized and weighted for reading, and this is a HUD.

/// The fifty-metre mark, thrown up over the shaft and fading out.
///
/// Drawn rather than announced: a cartouche, which is how this site marks
/// something as worth naming, with the distance inside it and a line under it.
///
/// The line is the part that was missing. The owner's note was that a long
/// climb had nothing to show for itself but a number ticking up, and a number
/// in a ring is still only a number — so each mark now says what has actually
/// changed: the floor beginning to move at fifty, a new shaft at every hundred,
/// and plain acknowledgement in between.
class _RewardMark extends StatelessWidget {
  const _RewardMark({required this.metres, required this.age});

  /// The mark just passed, in whole metres.
  final int metres;

  /// How far through its life the mark is, 0 to 1 and beyond.
  final double age;

  /// What this mark has to say, if anything.
  String _words(BuildContext context) {
    final l10n = context.l10n;
    if (metres == AscentWorld.difficultyStep) return l10n.ascentMarkFloor;
    if (metres % AscentWorld.levelHeight == 0) {
      // Levels are counted from one on screen and from zero in the world, the
      // same way the HUD counts them.
      final level = metres ~/ AscentWorld.levelHeight;
      return '${levelName(l10n, level)}\n${levelHint(l10n, level)}';
    }
    return l10n.ascentMarkHeight(metres);
  }

  @override
  Widget build(BuildContext context) {
    if (metres <= 0 || age > 1 || age < 0) return const SizedBox.shrink();
    final tokens = context.tokens;
    // Full for the first third, then out. A mark that starts fading at once
    // is never actually seen at full strength.
    final fade = (1 - (age - 0.34) / 0.66).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, -age * Tokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: tokens.beacon,
                      width: tokens.hairlineWidth,
                    ),
                    borderRadius: BorderRadius.circular(Tokens.space24),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.space24,
                      vertical: tokens.space8,
                    ),
                    child: Text(
                      '$metres',
                      style: context.type.displayM.copyWith(
                        color: tokens.beacon,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: tokens.space8),
                Text(
                  _words(context),
                  textAlign: TextAlign.center,
                  style: context.type.telemetry.copyWith(
                    color: tokens.instrument,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The name of level [level], 0 to 7.
String levelName(AppLocalizations l10n, int level) => switch (level) {
  0 => l10n.ascentLevelTemple,
  1 => l10n.ascentLevelSands,
  2 => l10n.ascentLevelFrozen,
  3 => l10n.ascentLevelDuat,
  4 => l10n.ascentLevelMaat,
  5 => l10n.ascentLevelApep,
  6 => l10n.ascentLevelFire,
  _ => l10n.ascentLevelReeds,
};

/// What changes in level [level], in a line.
String levelHint(AppLocalizations l10n, int level) => switch (level) {
  0 => l10n.ascentLevelTempleHint,
  1 => l10n.ascentLevelSandsHint,
  2 => l10n.ascentLevelFrozenHint,
  3 => l10n.ascentLevelDuatHint,
  4 => l10n.ascentLevelMaatHint,
  5 => l10n.ascentLevelApepHint,
  6 => l10n.ascentLevelFireHint,
  _ => l10n.ascentLevelReedsHint,
};

/// A relic's sign, drawn small, for the HUD and the legend.
class RelicMark extends StatelessWidget {
  /// Draws [relic] at [size].
  const RelicMark({
    required this.relic,
    required this.size,
    this.dim = false,
    super.key,
  });

  /// Which sign.
  final Relic relic;

  /// Its square.
  final double size;

  /// Drawn at rest rather than lit.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SignPainter(
          sign: switch (relic) {
            Relic.ankh => Sign.ankh,
            Relic.eye => Sign.eye,
            Relic.feather => Sign.feather,
          },
          colour: dim ? tokens.beaconDim : tokens.beaconGlow,
        ),
      ),
    );
  }
}

class _SignPainter extends CustomPainter {
  const _SignPainter({required this.sign, required this.colour});

  final Sign sign;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    SignPaths.of(sign, size.shortestSide),
    Paint()..color = colour,
  );

  @override
  bool shouldRepaint(_SignPainter oldDelegate) =>
      oldDelegate.sign != sign || oldDelegate.colour != colour;
}

/// Lives in hand and the relics burning, under the height.
///
/// An ankh for each life, and a bar for the eye or the feather that empties
/// as it runs out -- the owner asked for the effect to be shown clearly, and
/// a number of seconds is something to read while a bar is something to see.
class _Relics extends StatelessWidget {
  const _Relics({required this.world});

  final AscentWorld world;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.ascentHudLives(world.lives),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < AscentWorld.maxLives; i++)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: tokens.space4),
                    child: Opacity(
                      opacity: i < world.lives ? 1 : Tokens.ascentEmptyLife,
                      child: const RelicMark(
                        relic: Relic.ankh,
                        size: Tokens.ascentHudMark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (world.hasEye)
          _Meter(
            relic: Relic.eye,
            label: l10n.ascentHudEye,
            left: world.eyeFor / AscentWorld.eyeSeconds,
          ),
        if (world.hasFeather)
          _Meter(
            relic: Relic.feather,
            label: l10n.ascentHudFeather,
            left: world.featherFor / AscentWorld.featherSeconds,
          ),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.relic, required this.label, required this.left});

  final Relic relic;
  final String label;
  final double left;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RelicMark(relic: relic, size: Tokens.ascentHudMark),
          SizedBox(width: tokens.space8),
          SizedBox(
            width: Tokens.ascentMeterWidth,
            height: tokens.hairlineWidth * 4,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: tokens.hairline)),
                FractionallySizedBox(
                  widthFactor: left.clamp(0.0, 1.0),
                  child: ColoredBox(color: tokens.beacon),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.space8),
          Text(
            label,
            style: context.type.telemetryS.copyWith(color: tokens.beacon),
          ),
        ],
      ),
    );
  }
}

/// What just happened -- a relic taken, a life spent -- said once over the
/// shaft and gone.
class _News extends StatelessWidget {
  const _News({required this.text, required this.age});

  final String text;
  final double age;

  @override
  Widget build(BuildContext context) {
    if (age < 0 || age > 1 || text.isEmpty) return const SizedBox.shrink();
    final fade = (1 - (age - 0.5) / 0.5).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.6),
        child: Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, -age * Tokens.space24),
            child: Text(
              text,
              style: context.type.heading.copyWith(
                color: context.tokens.beaconGlow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The legend: the climb in a sentence, and what each sign does.
///
/// Shown before the first climb of a visit and whenever the info button is
/// pressed, and it holds the climb while it is open.
class _Legend extends StatelessWidget {
  const _Legend({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    Widget row(Relic relic, String name, String help) => Padding(
      padding: EdgeInsets.only(top: tokens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Tokens.ascentLegendMark,
            height: Tokens.ascentLegendMark,
            padding: EdgeInsets.all(tokens.space8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tokens.beaconDim,
                width: tokens.hairlineWidth,
              ),
            ),
            child: RelicMark(relic: relic, size: Tokens.ascentLegendMark),
          ),
          SizedBox(width: tokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: type.body.copyWith(color: tokens.beacon)),
                SizedBox(height: tokens.space4),
                Text(
                  help,
                  style: type.bodyS.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: tokens.void_.withValues(alpha: Tokens.boardBarrierAlpha),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.space16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Tokens.boardDialogWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border.all(
                  color: tokens.hairlineStrong,
                  width: tokens.hairlineWidth,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(tokens.space32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.ascentLegendTitle, style: type.heading),
                    SizedBox(height: tokens.space8),
                    Text(
                      l10n.ascentLegendBody,
                      style: type.body.copyWith(color: tokens.textSecondary),
                    ),
                    SizedBox(height: tokens.space8),
                    Text(
                      // What the hand in front of the screen actually has.
                      context.platform.isPointer
                          ? l10n.ascentKeys
                          : l10n.ascentTouch,
                      style: type.bodyS.copyWith(color: tokens.textMuted),
                    ),
                    SizedBox(height: tokens.space24),
                    Text(
                      l10n.ascentLegendRelics,
                      style: type.meta.copyWith(color: tokens.textMuted),
                    ),
                    row(
                      Relic.ankh,
                      l10n.ascentRelicAnkh,
                      l10n.ascentRelicAnkhHelp,
                    ),
                    row(
                      Relic.eye,
                      l10n.ascentRelicEye,
                      l10n.ascentRelicEyeHelp,
                    ),
                    row(
                      Relic.feather,
                      l10n.ascentRelicFeather,
                      l10n.ascentRelicFeatherHelp,
                    ),
                    SizedBox(height: tokens.space32),
                    Center(
                      child: GameControl(
                        label: l10n.ascentLegendGo,
                        isPrimary: true,
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The golden mask: the reward at the top of the climb.
///
/// `12-MOTIF-LIBRARY.md` keeps it out of the site for exactly this: it
/// appears in one place, as the reward at the top of the game, earned rather
/// than decorative. Drawn in the site's golds: the striped nemes, the face,
/// the eyes lined in kohl, the beard.
class _MaskPainter extends CustomPainter {
  const _MaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const gold = Tokens.ascentMaskGold;
    const deep = Tokens.ascentMaskDeep;
    const ink = Tokens.ascentMaskInk;
    Offset p(double x, double y) => Offset(w * x, h * y);
    // The nemes, flaring to the shoulders.
    final nemes = Path()
      ..moveTo(p(0.5, 0.04).dx, p(0.5, 0.04).dy)
      ..quadraticBezierTo(
        p(0.2, 0.06).dx,
        p(0.2, 0.06).dy,
        p(0.18, 0.32).dx,
        p(0.18, 0.32).dy,
      )
      ..lineTo(p(0.06, 0.92).dx, p(0.06, 0.92).dy)
      ..lineTo(p(0.94, 0.92).dx, p(0.94, 0.92).dy)
      ..lineTo(p(0.82, 0.32).dx, p(0.82, 0.32).dy)
      ..quadraticBezierTo(
        p(0.8, 0.06).dx,
        p(0.8, 0.06).dy,
        p(0.5, 0.04).dx,
        p(0.5, 0.04).dy,
      )
      ..close();
    canvas
      ..drawPath(nemes, Paint()..color = gold)
      ..save()
      ..clipPath(nemes);
    final stripe = Paint()..color = deep;
    for (var y = 0.1; y < 0.95; y += 0.075) {
      canvas.drawRect(Rect.fromLTRB(0, h * y, w, h * (y + 0.035)), stripe);
    }
    canvas.restore();
    // The face.
    final face = Path()
      ..moveTo(p(0.3, 0.24).dx, p(0.3, 0.24).dy)
      ..lineTo(p(0.7, 0.24).dx, p(0.7, 0.24).dy)
      ..quadraticBezierTo(
        p(0.72, 0.62).dx,
        p(0.72, 0.62).dy,
        p(0.5, 0.74).dx,
        p(0.5, 0.74).dy,
      )
      ..quadraticBezierTo(
        p(0.28, 0.62).dx,
        p(0.28, 0.62).dy,
        p(0.3, 0.24).dx,
        p(0.3, 0.24).dy,
      )
      ..close();
    canvas
      ..drawPath(face, Paint()..color = gold)
      // The brow band, and the uraeus on it.
      ..drawRect(
        Rect.fromLTRB(w * 0.29, h * 0.22, w * 0.71, h * 0.27),
        Paint()..color = deep,
      )
      ..drawCircle(p(0.5, 0.2), w * 0.035, Paint()..color = gold);
    // Eyes and kohl.
    final kohl = Paint()
      ..color = ink
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in const [-1.0, 1.0]) {
      final c = p(0.5 + side * 0.1, 0.4);
      canvas
        ..drawOval(
          Rect.fromCenter(center: c, width: w * 0.1, height: h * 0.04),
          Paint()..color = ink,
        )
        ..drawLine(
          c + Offset(side * w * 0.05, 0),
          c + Offset(side * w * 0.11, h * 0.012),
          kohl,
        )
        ..drawLine(
          c - Offset(w * 0.05, h * 0.035),
          c + Offset(w * 0.05, -h * 0.035),
          kohl,
        );
    }
    // Nose, mouth, beard.
    canvas
      ..drawLine(p(0.5, 0.44), p(0.49, 0.54), kohl)
      ..drawLine(p(0.45, 0.62), p(0.55, 0.62), kohl)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.46, h * 0.74, w * 0.54, h * 0.9),
          Radius.circular(w * 0.03),
        ),
        Paint()..color = deep,
      );
  }

  @override
  bool shouldRepaint(_MaskPainter oldDelegate) => false;
}
