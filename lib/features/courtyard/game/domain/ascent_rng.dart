/// The climb's random numbers, specified tightly enough to be ported.
///
/// `dart:math`'s `Random` is deterministic for a seed, but it is deterministic
/// *in Dart*. A leaderboard has to replay a run somewhere else — in this case a
/// Cloudflare Worker, in JavaScript — and re-deriving Dart's internal generator
/// from its source would be a guess dressed up as a contract. So the generator
/// is ours, it is thirty lines, and `worker/src/game/ascent.js` contains the
/// same thirty lines. `worker/contracts/fixtures/ascent-vectors.json` is
/// what proves the two agree; neither implementation is trusted on its looks.
///
/// Every operation here stays inside 32 bits, and every product is split into
/// 16-bit halves so that no intermediate exceeds 2^53. That is deliberate: it
/// makes the arithmetic exact on a 64-bit Dart int, on a JavaScript double, and
/// on anything else either language might compile to, rather than exact only on
/// the two backends that happen to be in use today.
library;

const int _mask = 0xFFFFFFFF;

/// A 32-bit xorshift, seeded through a murmur3 finaliser.
///
/// Small, fast and — the only property that matters here — reproducible
/// somewhere that is not Dart.
class AscentRng {
  /// A generator started from [seed]. Any integer will do; it is mixed first.
  AscentRng(int seed) : _state = _nonZero(mix(seed & _mask));

  /// The generator for the ledge with [id] in the run seeded [runSeed].
  ///
  /// Ledges are derived from their id rather than drawn from one stream, so a
  /// shaft is a pure function of its seed. Drawing them in sequence would make
  /// ledge 400 depend on how many times the recycler had run by then, which is
  /// reproducible only if the replay also reproduces the frame boundaries —
  /// exactly the coupling a fixed timestep exists to remove.
  AscentRng.ledge(int runSeed, int id)
    : _state = _nonZero(mix(mix(runSeed & _mask) ^ mix(id & _mask)));

  int _state;

  /// The murmur3 32-bit finaliser. Public because the vector generator prints
  /// it directly: a seeding bug that cancels itself out inside `next` would
  /// otherwise be invisible to the cross-language comparison.
  static int mix(int seed) {
    var z = (seed + 0x9E3779B9) & _mask;
    z = imul(z ^ (z >> 16), 0x85EBCA6B);
    z = imul(z ^ (z >> 13), 0xC2B2AE35);
    return (z ^ (z >> 16)) & _mask;
  }

  /// The low 32 bits of `a * b`, without ever forming `a * b`.
  ///
  /// `Math.imul` in JavaScript, and the same value here. The halves keep every
  /// product under 2^53 so a double holds it exactly.
  static int imul(int a, int b) {
    final low = a & 0xFFFF;
    final high = (a >> 16) & 0xFFFF;
    return (low * b + (((high * b) & 0xFFFF) << 16)) & _mask;
  }

  /// Zero is xorshift's fixed point: it would emit nothing but zero forever.
  static int _nonZero(int state) => state == 0 ? 0x9E3779B9 : state;

  /// The next 32-bit value.
  int next() {
    var s = _state;
    s = (s ^ (s << 13)) & _mask;
    s = s ^ (s >> 17);
    s = (s ^ (s << 5)) & _mask;
    _state = s;
    return s;
  }

  /// The next value in `[0, 1)`.
  ///
  /// An integer below 2^32 divided by 2^32 is exact in binary64, so this
  /// carries no rounding of its own into the physics.
  double nextDouble() => next() / 4294967296.0;
}
