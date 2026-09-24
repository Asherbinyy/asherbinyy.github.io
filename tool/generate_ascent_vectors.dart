// ignore_for_file: avoid_print

/// Writes the fixture that proves the Dart and JavaScript climbs agree.
///
///     fvm dart run tool/generate_ascent_vectors.dart
///
/// The output is `worker/contracts/fixtures/ascent-vectors.json`. Two test
/// suites read it and neither generates it: `test/unit/features/ascent/
/// ascent_vectors_test.dart` checks that the Dart implementation still produces
/// these numbers, and `worker/test/ascent.test.js` checks that the JavaScript
/// one produces them too. A change to either side that moves a single bit fails
/// one of those suites, which is the only reason the file exists.
///
/// Doubles are written as their IEEE-754 bit patterns rather than as decimals.
/// A shortest-round-trip decimal would almost certainly survive the trip
/// through JSON intact, and "almost certainly" is not the standard a ranking
/// should be held to.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_run.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_rng.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_tape.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// A double as sixteen hex digits of its binary64 representation.
///
/// Read as two halves rather than one `getUint64`. A Dart int is signed, so
/// `getUint64` cannot represent a pattern with the top bit set and hands back
/// the wrapped negative instead — which prints with a minus sign in front of
/// it and is not a bit pattern at all. Every negative double went into the
/// first version of this fixture that way, and the Dart tests agreed with it
/// because they used the same broken helper. The JavaScript side is what
/// noticed, which is the argument for having a second implementation in one
/// sentence.
String bits(double value) {
  final data = ByteData(8)..setFloat64(0, value);
  final high = data.getUint32(0).toRadixString(16).padLeft(8, '0');
  final low = data.getUint32(4).toRadixString(16).padLeft(8, '0');
  return '$high$low';
}

/// Seeds chosen to cross the boundaries that catch a port out: zero, one, the
/// sign bit of a 32-bit integer, the top of the range, and a real timestamp.
const List<int> _seeds = [
  0,
  1,
  7,
  0x7FFFFFFF,
  0x80000000,
  0xFFFFFFFF,
  1758000000000 & 0xFFFFFFFF,
];

Map<String, Object?> _rngVectors() {
  final mixed = <Map<String, Object?>>[
    for (final seed in [0, 1, 2, 42, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF])
      {'in': seed, 'out': AscentRng.mix(seed)},
  ];
  final streams = <Map<String, Object?>>[
    for (final seed in _seeds)
      {
        'seed': seed,
        'sequence': () {
          final rng = AscentRng(seed);
          return [for (var i = 0; i < 8; i++) rng.next()];
        }(),
        'doubles': () {
          final rng = AscentRng(seed);
          return [for (var i = 0; i < 4; i++) bits(rng.nextDouble())];
        }(),
      },
  ];
  final ledgeSeeded = <Map<String, Object?>>[
    for (final seed in _seeds)
      for (final id in [1, 2, 39, 40, 1000])
        {'runSeed': seed, 'id': id, 'first': AscentRng.ledge(seed, id).next()},
  ];
  return {'mix': mixed, 'streams': streams, 'ledge': ledgeSeeded};
}

const Map<LedgeKind, String> _kinds = {
  LedgeKind.stone: 'stone',
  LedgeKind.cracked: 'cracked',
  LedgeKind.scarab: 'scarab',
};

Map<String, Object?> _ledgeVector(Ledge ledge) => {
  'id': ledge.id,
  'kind': _kinds[ledge.kind],
  'x': bits(ledge.x),
  'y': bits(ledge.y),
  'width': bits(ledge.width),
  'drift': bits(ledge.drift),
  'isLanding': ledge.isLanding,
  // The relic's index in the enum, or -1: the same numbers the JavaScript
  // side uses, so the two can be compared without a lookup table.
  'relic': ledge.relic?.index ?? -1,
};

List<Map<String, Object?>> _shaftVectors() => [
  for (final seed in _seeds)
    {
      'seed': seed,
      'ledges': [
        for (final ledge in AscentWorld.seeded(
          best: 0,
          isPractice: false,
          seed: seed,
        ).ledges)
          _ledgeVector(ledge),
      ],
    },
];

/// Heights that sit either side of every boundary the generator keys on.
///
/// Each level change at a hundred, one sample well inside every level so the
/// mode itself is checked rather than only the seam, and the summit.
const List<double> _levelSamples = [
  0,
  2.6,
  49.9,
  50,
  50.1,
  99.9,
  100,
  100.1,
  150,
  199.9,
  200,
  200.1,
  260,
  299.9,
  300,
  300.1,
  399.9,
  400,
  400.1,
  420,
  499.9,
  500,
  500.1,
  560,
  599.9,
  600,
  600.1,
  650,
  699.9,
  700,
  700.1,
  760,
  799.9,
  800,
  999,
];

/// Every relic the shaft places, for every seed: the relic (or -1) on a ledge
/// at each height the shaft's ledges stand at, up to the summit.
///
/// The recorded runs take a handful of relics at best, and the level samples
/// almost never land on one, so without these the placement -- three schedules
/// drawing from streams of their own -- would be checked on both sides only
/// where a bot happened to pass.
List<Map<String, Object?>> _relicVectors() => [
  for (final seed in _seeds)
    {
      'seed': seed,
      'relics': [
        for (var i = 1; i * AscentWorld.ledgeGap < AscentWorld.summit; i++)
          AscentWorld.relicAt(seed, i * AscentWorld.ledgeGap)?.index ?? -1,
      ],
    },
];

/// Ledges sampled across the whole shaft, level by level.
///
/// The recorded runs only ever reach the part of the shaft a bot can climb, so
/// levels three and up would otherwise go unchecked on both sides. These are
/// generated directly at height, which is the only way to hold two
/// implementations to the same answer about ground nobody has stood on.
List<Map<String, Object?>> _levelVectors() => [
  for (final seed in _seeds)
    {
      'seed': seed,
      'ledges': [
        for (var i = 0; i < _levelSamples.length; i++)
          _ledgeVector(AscentWorld.generate(900 + i, _levelSamples[i], seed)),
      ],
    },
];

/// Tapes built by hand, to pin the wire format independently of any physics.
List<Map<String, Object?>> _tapeVectors() {
  final cases = <List<(int, int)>>[
    [(0, 1)],
    [(0, 127), (4, 1)],
    [(0, 128), (2, 1000), (1, 65535)],
    [(6, 3), (5, 3), (4, 3), (2, 3), (1, 3), (0, 3)],
    [(0, AscentContract.maxTicks - 1), (4, 1)],
  ];
  return [
    for (final runs in cases)
      () {
        final tape = AscentTape();
        for (final (code, count) in runs) {
          for (var i = 0; i < count; i++) {
            tape.add(AscentInput(code));
          }
        }
        return {
          'runs': [
            for (final (code, count) in runs) [code, count],
          ],
          'ticks': tape.ticks,
          'encoded': tape.encode(),
        };
      }(),
  ];
}

/// Strings a decoder must refuse.
///
/// Every one of these is a thing an attacker would try rather than a thing a
/// fuzzer found: a code that means steering both ways at once, a run of zero
/// length, a tape split into needless pieces, a truncated integer, and a climb
/// longer than the contract allows.
List<Map<String, Object?>> _rejectedTapes() => [
  {
    'why': 'code 3 steers both ways',
    'encoded': base64Url.encode([11]),
  },
  {
    'why': 'a run of no ticks',
    'encoded': base64Url.encode([4]),
  },
  {
    'why': 'the same code twice in a row',
    'encoded': base64Url.encode([8, 8]),
  },
  {
    'why': 'a varint with no final byte',
    'encoded': base64Url.encode([0x80, 0x80]),
  },
  {'why': 'not base64 at all', 'encoded': '!!!!'},
];

/// Input streams that stand in for players.
///
/// A real climb is not a random walk, so these are written as intentions —
/// hold nothing, hold one side, jump on a rhythm, jump and steer — rather than
/// generated. Between them they reach every branch that matters: the floor, a
/// wall kick, a cracked ledge giving way, the rising floor catching up, and a
/// run ending in a fall.
List<(String, List<(int, int)>)> _scripts() => [
  ('stand still until the floor arrives', [(0, 4000)]),
  ('hold the jump from the first tick', [(4, 6000)]),
  (
    'jump on a half-second rhythm',
    [
      for (var i = 0; i < 90; i++) ...[(4, 8), (0, 56)],
    ],
  ),
  (
    'jump into the left wall, then ride it',
    [
      for (var i = 0; i < 120; i++) ...[(5, 10), (1, 30)],
    ],
  ),
  (
    'jump into the right wall, then ride it',
    [
      for (var i = 0; i < 120; i++) ...[(6, 10), (2, 30)],
    ],
  ),
  (
    'alternate the walls, which is how the shaft is meant to be climbed',
    [
      for (var i = 0; i < 60; i++) ...[(5, 16), (1, 48), (6, 16), (2, 48)],
    ],
  ),
  (
    'steer without ever leaving the ground',
    [
      for (var i = 0; i < 40; i++) ...[(1, 64), (2, 64)],
    ],
  ),
];

/// A climber good enough to reach the parts of the shaft a script cannot.
///
/// The hand-written scripts above are blind: they press the same keys whatever
/// the shaft looks like, so none of them survives thirty seconds, and a vector
/// set built only from them would prove the two implementations agree about
/// the opening bounce and nothing else — never a cracked ledge giving way,
/// never a scarab drifting underfoot, never the ledge recycler, never the floor
/// starting to rise at sixty metres.
///
/// So this one looks at the world: steer towards the lowest ledge above, press
/// jump on landing, hold it while still rising. It is a poor player by human
/// standards and an excellent one for coverage, because it keeps going.
///
/// It exists only in this generator. The game ships no bot.
AscentTape _climb(int seed, int maxTicks) {
  var world = AscentWorld.seeded(best: 0, isPractice: false, seed: seed);
  final tape = AscentTape();
  var leaping = false;
  int? targetId;

  Ledge? byId(int? id) {
    for (final ledge in world.ledges) {
      if (ledge.id == id) return ledge;
    }
    return null;
  }

  for (var tick = 0; tick < maxTicks && !world.isOver; tick++) {
    if (world.isGrounded) {
      // Aim only from the ground. Re-aiming in mid-air was the first version
      // and it never got past the second ledge: the moment the climber rose
      // past the ledge it was jumping for, that ledge stopped being "above"
      // and it began steering away from its own landing.
      Ledge? next;
      for (final ledge in world.ledges) {
        if (!ledge.isBroken && ledge.y > world.climberY + 0.3) {
          next = ledge;
          break;
        }
      }
      targetId = next?.id;
    }
    final target = byId(targetId);
    final offset = (target?.x ?? 0.5) - world.climberX;
    final steer = offset.abs() < 0.01
        ? 0.0
        : offset < 0
        ? -1.0
        : 1.0;
    // Jump the moment it lands, and do the lining up in the air. Waiting on
    // the ledge until the next one was overhead sounded more careful and was
    // fatal: a target two ledge-widths sideways is off the end of the one you
    // are standing on, so the climber walked off it every fifth jump. A flight
    // lasts 1.18s and the climber crosses two thirds of the shaft in that, so
    // there is no reason to do any of it on foot.
    //
    // Holding matters as much as pressing. Letting go early cuts the rise
    // short at 9.5 m/s, whose apex is 2.05m — less than the 2.6m between
    // ledges, so a tapped jump can never climb at all.
    leaping = world.isGrounded || (leaping && world.velocity > 0);
    tape.add(AscentInput.of(steer: steer, isLeaping: leaping));
    world = world.step(
      dt: AscentContract.tickSeconds,
      steer: steer,
      isLeaping: leaping,
    );
  }
  return tape;
}

List<Map<String, Object?>> _runVectors() {
  final vectors = <Map<String, Object?>>[];

  void record(String name, int seed, AscentTape tape) {
    final outcome = AscentSimulation.replay(seed: seed, tape: tape);
    vectors.add({
      'script': name,
      'seed': seed,
      'tape': tape.encode(),
      'metres': outcome.metres,
      'ticks': outcome.ticks,
      'endedInFall': outcome.endedInFall,
      'won': outcome.won,
      'relicsTaken': outcome.relicsTaken,
      'livesLost': outcome.livesLost,
    });
  }

  for (final seed in _seeds) {
    for (final (name, script) in _scripts()) {
      final tape = AscentTape();
      for (final (code, count) in script) {
        for (var i = 0; i < count; i++) {
          tape.add(AscentInput(code));
        }
      }
      record(name, seed, tape);
    }
    record('a climber that watches the shaft', seed, _climb(seed, 90000));
  }
  return vectors;
}

void main() {
  final fixture = <String, Object?>{
    'note':
        'Generated by tool/generate_ascent_vectors.dart. Do not edit by hand. '
        'Doubles are IEEE-754 bit patterns, big-endian, as 16 hex digits.',
    'version': AscentContract.version,
    'tickRate': AscentContract.tickRate,
    'tickSeconds': bits(AscentContract.tickSeconds),
    'maxTicks': AscentContract.maxTicks,
    'maxTapeRuns': AscentContract.maxTapeRuns,
    'rng': _rngVectors(),
    'shafts': _shaftVectors(),
    'levels': _levelVectors(),
    'relics': _relicVectors(),
    'tapes': _tapeVectors(),
    'rejectedTapes': _rejectedTapes(),
    'runs': _runVectors(),
  };

  const path = 'worker/contracts/fixtures/ascent-vectors.json';
  File(path).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(fixture)}\n',
  );

  final runs = fixture['runs']! as List<Map<String, Object?>>;
  print('$path: ${runs.length} runs, ${File(path).lengthSync()} bytes');
  for (final run in runs.take(7)) {
    print(
      '  seed ${run['seed']}  ${run['metres']}m  '
      '${run['ticks']} ticks  ${run['script']}',
    );
  }
  final relics = runs.fold<int>(
    0,
    (sum, run) => sum + (run['relicsTaken']! as int),
  );
  final lives = runs.fold<int>(
    0,
    (sum, run) => sum + (run['livesLost']! as int),
  );
  final deepest = runs.fold<int>(0, (top, run) {
    final metres = run['metres']! as int;
    return metres > top ? metres : top;
  });
  print('  highest: ${deepest}m, relics taken: $relics, lives spent: $lives');
}
