import 'dart:convert';
import 'dart:typed_data';

import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';

/// What the player did, tick by tick, small enough to post.
///
/// The controls change a few times a second and the simulation runs a hundred
/// and twenty-eight times a second, so nearly every tick repeats the one before
/// it. The tape stores runs of identical input rather than each tick: a
/// three-minute climb is a few thousand bytes instead of twenty-three thousand.
///
/// One run is one variable-length integer, `count * 8 + code`, because a code
/// is always under 8. The bytes are then base64url, which is what survives a
/// JSON body without escaping. `worker/src/game/ascent.js` decodes the same
/// format, and the shared vectors include tapes so that agreement is measured
/// rather than assumed.
class AscentTape {
  /// An empty tape, ready to record.
  AscentTape() : _codes = <int>[], _counts = <int>[], _ticks = 0;

  AscentTape._(this._codes, this._counts, this._ticks);

  final List<int> _codes;
  final List<int> _counts;
  int _ticks;

  /// How many ticks have been recorded.
  int get ticks => _ticks;

  /// How many runs of identical input the tape holds.
  int get runs => _codes.length;

  /// Adds one tick of [input].
  void add(AscentInput input) {
    if (_codes.isNotEmpty && _codes.last == input.code) {
      _counts[_counts.length - 1]++;
    } else {
      _codes.add(input.code);
      _counts.add(1);
    }
    _ticks++;
  }

  /// The input at each tick, in order.
  Iterable<AscentInput> get inputs sync* {
    for (var run = 0; run < _codes.length; run++) {
      for (var i = 0; i < _counts[run]; i++) {
        yield AscentInput(_codes[run]);
      }
    }
  }

  /// Forgets everything, so one recorder can serve a second run.
  void clear() {
    _codes.clear();
    _counts.clear();
    _ticks = 0;
  }

  /// The tape as a base64url string.
  String encode() {
    final bytes = BytesBuilder(copy: false);
    for (var run = 0; run < _codes.length; run++) {
      var value = _counts[run] * 8 + _codes[run];
      while (value >= 0x80) {
        bytes.addByte((value & 0x7F) | 0x80);
        value >>= 7;
      }
      bytes.addByte(value);
    }
    return base64Url.encode(bytes.takeBytes()).replaceAll('=', '');
  }

  /// A tape read back from [encoded], or null if it is not one.
  ///
  /// Null covers every way the string can be wrong — not base64, a truncated
  /// integer, a code the contract does not define, a zero-length run, more runs
  /// or more ticks than the contract allows. The caller does not need to know
  /// which: a tape that cannot be decoded is not replayed either way, and
  /// saying precisely how a rejected submission was malformed is a courtesy
  /// owed to honest clients and a hint owed to nobody else.
  static AscentTape? decode(String encoded) {
    final Uint8List bytes;
    try {
      bytes = base64Url.decode(
        encoded.padRight((encoded.length + 3) & ~3, '='),
      );
    } on FormatException {
      return null;
    }

    final codes = <int>[];
    final counts = <int>[];
    var ticks = 0;
    var index = 0;
    while (index < bytes.length) {
      var value = 0;
      var shift = 0;
      while (true) {
        if (index >= bytes.length || shift > 28) return null;
        final byte = bytes[index++];
        value |= (byte & 0x7F) << shift;
        if (byte & 0x80 == 0) break;
        shift += 7;
      }
      final code = value & 7;
      final count = value >> 3;
      if (count < 1 || !AscentInput(code).isValid) return null;
      if (codes.isNotEmpty && codes.last == code) return null;
      codes.add(code);
      counts.add(count);
      ticks += count;
      if (codes.length > AscentContract.maxTapeRuns) return null;
      if (ticks > AscentContract.maxTicks) return null;
    }
    return AscentTape._(codes, counts, ticks);
  }
}
