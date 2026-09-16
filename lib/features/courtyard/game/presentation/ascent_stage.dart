import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_audio.dart';
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
      unawaited(_start());
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
    var previous = before;
    for (final state in run.advance(
      dt.clamp(0.0, 0.25),
      AscentInput.of(steer: _steer, isLeaping: _leap),
    )) {
      leapt |= state.velocity > 0 && previous.velocity <= 0;
      broke |= state.brokeLedge;
      kicked |= state.kickedWall;
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
      _audio.play(next.metres > _best ? AscentSound.record : AscentSound.fall);
      if (next.metres > _best) _best = next.metres;
      _ticker.stop();
      // The tape goes up, not the score. What the server ranks is what it
      // reaches replaying these keypresses; `next.metres` is only ever what
      // this screen prints.
      if (_isRanked && run.isQualifying) {
        _isRanked = false;
        unawaited(
          ref
              .read(leaderboardControllerProvider.notifier)
              .submit(tape: run.tape.encode()),
        );
      }
    }

    setState(() {});
  }

  /// Whether the run in progress is one the board will be asked to judge.
  bool _isRanked = false;

  /// Asks the one question, at the moment it first matters.
  ///
  /// Not on arriving at the site, not on opening the climb: on starting a run,
  /// which is the first point at which the answer changes anything. A visitor
  /// who only wants to play reaches the shaft without ever being asked to
  /// decide about a scoreboard.
  Future<void> _settleParticipation() async {
    final leaderboard = ref.read(leaderboardControllerProvider.notifier);
    if (!leaderboard.isAvailable) return;
    if (ref.read(leaderboardControllerProvider).participation is! Undecided) {
      return;
    }
    final chosen = await JoinPrompt.show(context);
    // Dismissing the sheet is not an answer, and must not be recorded as one.
    // It means the question comes back next time, which is the only reading of
    // a dismissal that does not put words in somebody's mouth.
    if (chosen == null) return;
    await leaderboard.choose(chosen);
  }

  Future<void> _start() async {
    await _settleParticipation();
    if (!mounted) return;

    // A ranked run climbs a shaft the server chose, so that a seed cannot be
    // shopped for. If the server does not answer -- offline, not configured,
    // slow -- the climb still happens, on a local seed, and simply does not
    // count. The game never waits on a network to be playable.
    final leaderboard = ref.read(leaderboardControllerProvider.notifier)
      ..clearVerdict();
    final challenge = ref.read(leaderboardControllerProvider).canPlayRanked
        ? await leaderboard.beginRankedRun()
        : null;
    if (!mounted) return;
    _isRanked = challenge != null;

    await _audio.prime();
    _audio.play(AscentSound.start);

    _last = Duration.zero;
    _bands = 0;
    _rewards = 0;
    _rewardAt = double.negativeInfinity;
    _kickedAt = double.negativeInfinity;
    _steer = 0;
    _leap = false;
    if (!mounted) return;
    setState(() {
      _run = AscentSimulation(
        best: _best,
        seed:
            challenge?.seed ??
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
              _Hud(
                world: world,
                best: _best,
                isMuted: _audio.isMuted,
                onRestart: _start,
                onMute: () => setState(_audio.toggleMute),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              if (world != null && !world.isOver)
                _RewardMark(
                  metres: _rewards * Tokens.ascentRewardStep,
                  age: (_elapsed - _rewardAt) / Tokens.ascentRewardHold,
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
                    _leap = input.isLeaping;
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

/// What a run ended at, and what the board made of it.
class _Over extends ConsumerWidget {
  const _Over({
    required this.metres,
    required this.best,
    required this.onRestart,
  });

  final int metres;
  final int best;
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
          constraints: const BoxConstraints(maxWidth: 420),
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
                  SizedBox(height: tokens.space12),
                  _VerdictLine(state: leaderboard),
                  SizedBox(height: tokens.space24),
                  GameControl(
                    label: l10n.ascentAgain,
                    isPrimary: true,
                    onPressed: onRestart,
                  ),
                  if (leaderboard.board != null ||
                      leaderboard.isLoadingBoard ||
                      leaderboard.boardFailed) ...[
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

/// The hundred-metre mark, thrown up over the shaft and fading out.
///
/// Drawn rather than announced: a cartouche, which is how this site marks
/// something as worth naming, with the distance inside it.
class _RewardMark extends StatelessWidget {
  const _RewardMark({required this.metres, required this.age});

  /// The mark just passed, in whole metres.
  final int metres;

  /// How far through its life the mark is, 0 to 1 and beyond.
  final double age;

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
            child: DecoratedBox(
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
                  style: context.type.displayM.copyWith(color: tokens.beacon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
