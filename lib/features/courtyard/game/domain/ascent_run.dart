import 'package:meta/meta.dart';

import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_tape.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// What replaying a seed and a tape produced.
@immutable
class AscentOutcome {
  /// Creates an outcome.
  const AscentOutcome({
    required this.metres,
    required this.ticks,
    required this.endedInFall,
  });

  /// The height reached, in whole metres. The score.
  final int metres;

  /// How many ticks were simulated before the run ended or the tape ran out.
  final int ticks;

  /// Whether the climber fell, rather than the tape simply stopping.
  final bool endedInFall;

  @override
  bool operator ==(Object other) =>
      other is AscentOutcome &&
      other.metres == metres &&
      other.ticks == ticks &&
      other.endedInFall == endedInFall;

  @override
  int get hashCode => Object.hash(metres, ticks, endedInFall);

  @override
  String toString() =>
      'AscentOutcome(metres: $metres, ticks: $ticks, fell: $endedInFall)';
}

/// The climb, driven at a fixed rate.
///
/// The game used to hand [AscentWorld.step] whatever a frame had taken,
/// clamped at a thirtieth of a second. That is the ordinary way to write a game
/// loop and it makes two things impossible at once. A replay cannot reproduce a
/// run, because it would have to reproduce the frame boundaries of a machine it
/// has never seen. And a climb is not the same climb on every device: at 120fps
/// gravity is integrated twice as finely as at 60, so the same press carries
/// you a slightly different distance — which, for a ranking, is not a rounding
/// difference but an unfair one.
///
/// So the simulation runs at [AscentContract.tickRate] and the frame only
/// decides how many ticks are due. A run becomes a seed and a list of inputs,
/// and wall-clock time drops out of it entirely.
class AscentSimulation {
  /// Starts a run over the shaft [seed] builds.
  AscentSimulation({
    required int seed,
    required int best,
    bool isPractice = false,
  }) : world = AscentWorld.seeded(
         best: best,
         isPractice: isPractice,
         seed: seed,
       ),
       _seed = seed,
       _isPractice = isPractice;

  /// The current state of the climb.
  AscentWorld world;

  final int _seed;
  final bool _isPractice;
  final AscentTape _tape = AscentTape();
  double _debt = 0;

  /// The seed this run was built from.
  int get seed => _seed;

  /// What the player did, tick by tick.
  ///
  /// A practice run records too — recording costs a few kilobytes and knowing
  /// the tape is always there is simpler than knowing when it is not. What
  /// practice cannot do is qualify, and that is decided by [isQualifying]
  /// rather than by whether anything was written down.
  AscentTape get tape => _tape;

  /// How many ticks have been simulated.
  int get ticks => _tape.ticks;

  /// Whether this run could be submitted, were it over.
  ///
  /// Practice never qualifies: falling is survivable in it, so its height is
  /// not the same measurement. Nor does a run past the contract's ceiling.
  bool get isQualifying =>
      !_isPractice && _tape.ticks <= AscentContract.maxTicks;

  /// Advances the climb by [elapsed] real seconds of the given [input].
  ///
  /// Returns the states the simulation passed through, oldest first, so a
  /// caller can sound a landing that happened two ticks ago rather than only
  /// the one the frame ended on. Usually one entry; never more than
  /// [AscentContract.maxStepsPerFrame].
  List<AscentWorld> advance(double elapsed, AscentInput input) {
    if (world.isOver) return const [];
    _debt += elapsed;
    final passed = <AscentWorld>[];
    while (_debt >= AscentContract.tickSeconds &&
        passed.length < AscentContract.maxStepsPerFrame) {
      _debt -= AscentContract.tickSeconds;
      world = world.step(
        dt: AscentContract.tickSeconds,
        steer: input.steer,
        isLeaping: input.isLeaping,
      );
      _tape.add(input);
      passed.add(world);
      if (world.isOver) break;
    }
    // A frame so late that it owed more ticks than the cap allows has its
    // remaining debt written off rather than carried: carrying it means the
    // next frame owes even more, which is the loop that turns one slow frame
    // into a locked-up game.
    if (passed.length == AscentContract.maxStepsPerFrame) _debt = 0;
    return passed;
  }

  /// Replays [tape] over the shaft [seed] builds, and reports where it got to.
  ///
  /// This is the whole verification. The server runs the same function, written
  /// in JavaScript, over the same two values; if it reaches a different height
  /// the submission is not accepted. Nothing about the result is taken from the
  /// client — the client sends what was pressed, not what it earned.
  static AscentOutcome replay({required int seed, required AscentTape tape}) {
    var world = AscentWorld.seeded(best: 0, isPractice: false, seed: seed);
    var ticks = 0;
    for (final input in tape.inputs) {
      if (world.isOver) break;
      world = world.step(
        dt: AscentContract.tickSeconds,
        steer: input.steer,
        isLeaping: input.isLeaping,
      );
      ticks++;
    }
    return AscentOutcome(
      metres: world.metres,
      ticks: ticks,
      endedInFall: world.isOver,
    );
  }
}
