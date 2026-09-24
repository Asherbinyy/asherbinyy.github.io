/// The frozen rules a run is judged against.
///
/// A leaderboard entry is not a number the browser sent. It is a seed and the
/// keys that were pressed, replayed on a server that knows the same physics and
/// arrives at the same height. That only works if "the same physics" is a
/// written thing rather than whatever the client happened to compile, which is
/// what this file is: a version, a tick rate, and the bounds outside which a
/// submission is not worth replaying.
///
/// Changing any constant here — or any number in `AscentWorld` — changes what a
/// score means, so it changes [AscentContract.version] too. Runs of different
/// versions are not comparable and are never ranked against each other.
library;

/// The rules a score is earned under.
abstract final class AscentContract {
  /// The physics generation. Bump it for any change to simulation behaviour.
  ///
  /// **2** — the shaft now has levels. The first hundred metres are wide
  /// dressed stone; cracked ledges arrive at a hundred, drifting ones at two
  /// hundred, and all three together above three hundred, narrowing as they
  /// go. The floor stands still for the opening fifty metres and then
  /// accelerates every fifty rather than every sixty. Gilded ankhs appear above
  /// fifty metres and lift the jump for ten seconds when taken. A score earned
  /// under version 1 was earned on a different climb and does not belong on the
  /// same board.
  ///
  /// **3** — eight named levels and a summit at 800 metres that wins the
  /// climb. Relics replace the lifting ankh: the ankh is an extra life, the eye
  /// of Horus slows the floor for ten seconds, Ma'at's feather gives two jumps
  /// in the air for five. The sands blow a jump off its line, the ice slides,
  /// every level opens on a full-width ledge, and the floor's pace is capped.
  static const int version = 3;

  /// How many simulation steps make a second.
  ///
  /// 128 rather than 120 for one reason: 1/128 is exactly representable in
  /// binary64 and 1/120 is not. A dt with no rounding of its own is one fewer
  /// thing that can differ between two languages summing it fifteen thousand
  /// times.
  static const int tickRate = 128;

  /// One simulation step, in seconds. Exactly 1/128.
  static const double tickSeconds = 0.0078125;

  /// The longest run that may be submitted, in ticks. Fifteen minutes.
  ///
  /// Not a judgement about how long anyone can climb — it is the bound on how
  /// much work one submission can ask the server to do.
  static const int maxTicks = tickRate * 60 * 15;

  /// The most run-length pairs a submitted tape may contain.
  ///
  /// A human changes direction a few times a second. Twelve thousand changes
  /// is far past generous and still bounds the decoder.
  static const int maxTapeRuns = 12000;

  /// The most steps the client may simulate in one rendered frame.
  ///
  /// A frame that arrives late owes the simulation several ticks. Paying all of
  /// them can cost more than a frame, which makes the next frame later still.
  /// Beyond this the debt is written off: the climb runs briefly in slow motion
  /// instead of spiralling. It does not affect replay — a run is its ticks, not
  /// its wall clock.
  static const int maxStepsPerFrame = 8;
}

/// What the player was doing during one tick.
///
/// Three states of steering and a leap held or not: seven distinct values, so
/// the tape stores one small integer per tick and nothing else. Analogue
/// steering would need quantising before it could be replayed exactly, and the
/// game has never had any.
extension type const AscentInput(int code) {
  /// Builds a code from the two controls the game actually has.
  factory AscentInput.of({required double steer, required bool isLeaping}) =>
      AscentInput(
        (steer < 0
                ? 1
                : steer > 0
                ? 2
                : 0) |
            (isLeaping ? 4 : 0),
      );

  /// Neither steering nor leaping.
  static const AscentInput idle = AscentInput(0);

  /// -1, 0 or 1.
  double get steer => switch (code & 3) {
    1 => -1,
    2 => 1,
    _ => 0,
  };

  /// Whether the leap control was down.
  bool get isLeaping => code & 4 != 0;

  /// Whether this is a code the contract defines. 3 is not: it would be
  /// steering both ways at once.
  bool get isValid => code >= 0 && code <= 6 && (code & 3) != 3;
}
