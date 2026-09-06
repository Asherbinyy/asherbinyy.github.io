/// Deterministic pseudo-randomness keyed to a content identifier.
///
/// Section 11 requires a given application to render the same station card on
/// every load, so the card cannot use `Random()` — an unseeded stream would
/// make cards shift between loads and read as a rendering bug.
class StationSeed {
  /// Derives the stream from [id] with FNV-1a: short, dependency-free, and it
  /// spreads the short ASCII slugs used as application ids well.
  StationSeed(String id) : _state = _hash(id);

  static const int _offsetBasis = 0x811C9DC5;
  static const int _prime = 0x01000193;

  /// Every step is masked to 32 bits so the VM and the web build, which have
  /// different native integer widths, produce identical cards.
  static const int _mask = 0xFFFFFFFF;

  int _state;

  static int _hash(String value) {
    var hash = _offsetBasis;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * _prime) & _mask;
    }
    // A zero state locks the xorshift stream at zero for every subsequent draw.
    return hash == 0 ? _offsetBasis : hash;
  }

  /// The next value in 0..1, advancing the xorshift32 stream.
  double nextDouble() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x;
    return x / (_mask + 1);
  }

  /// The next value between [min] and [max].
  double nextRange(double min, double max) => min + nextDouble() * (max - min);

  /// The next integer in 0 (inclusive) to [max] (exclusive).
  int nextInt(int max) => max <= 0 ? 0 : (nextDouble() * max).floor();
}
