import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_run.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_rng.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_tape.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// Holds the Dart climb to the fixture the Worker is also held to.
///
/// This suite does not check that the physics is *good*. It checks that it has
/// not moved. A leaderboard compares runs played weeks apart against a server
/// that replays them, so a constant nudged for feel is not a tweak — it is a
/// silent rescoring of every entry on the board, and the way to notice is for
/// this file to go red.
///
/// When a change to the physics is intended: bump `AscentContract.version`,
/// re-run `fvm dart run tool/generate_ascent_vectors.dart`, and say so in the
/// worklog. The old board does not carry over.
void main() {
  final fixture = jsonDecode(
    File('worker/contracts/fixtures/ascent-vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  // Two halves, not one getUint64: a Dart int is signed, so a pattern with the
  // top bit set comes back wrapped negative and prints with a minus in front.
  // See the note on the same function in tool/generate_ascent_vectors.dart.
  String bits(double value) {
    final data = ByteData(8)..setFloat64(0, value);
    final high = data.getUint32(0).toRadixString(16).padLeft(8, '0');
    final low = data.getUint32(4).toRadixString(16).padLeft(8, '0');
    return '$high$low';
  }

  group('the contract', () {
    test('is the version the fixture was generated under', () {
      expect(fixture['version'], AscentContract.version);
      expect(fixture['tickRate'], AscentContract.tickRate);
      expect(fixture['maxTicks'], AscentContract.maxTicks);
      expect(fixture['maxTapeRuns'], AscentContract.maxTapeRuns);
    });

    test('ticks at exactly one one-hundred-and-twenty-eighth of a second', () {
      // Not approximately. A dt that is exactly representable is the reason
      // fifteen thousand additions can be expected to land on the same bit in
      // two languages, so "close to 1/128" would defeat the point of choosing
      // it.
      expect(bits(AscentContract.tickSeconds), fixture['tickSeconds']);
      expect(AscentContract.tickSeconds * AscentContract.tickRate, 1.0);
    });

    test('rejects an input code that steers both ways at once', () {
      expect(const AscentInput(3).isValid, isFalse);
      expect(const AscentInput(7).isValid, isFalse);
      expect(const AscentInput(-1).isValid, isFalse);
      for (final code in [0, 1, 2, 4, 5, 6]) {
        expect(AscentInput(code).isValid, isTrue, reason: 'code $code');
      }
    });
  });

  group('the generator', () {
    final rng = fixture['rng'] as Map<String, dynamic>;

    test('mixes a seed the way the fixture recorded', () {
      for (final vector in rng['mix'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        expect(
          AscentRng.mix(entry['in'] as int),
          entry['out'],
          reason: 'mix(${entry['in']})',
        );
      }
    });

    test('produces the recorded stream for every seed', () {
      for (final vector in rng['streams'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        final seed = entry['seed'] as int;
        final generator = AscentRng(seed);
        expect(
          [for (var i = 0; i < 8; i++) generator.next()],
          entry['sequence'],
          reason: 'seed $seed',
        );
        final doubles = AscentRng(seed);
        expect(
          [for (var i = 0; i < 4; i++) bits(doubles.nextDouble())],
          entry['doubles'],
          reason: 'seed $seed as doubles',
        );
      }
    });

    test('derives a ledge from its run and its id', () {
      for (final vector in rng['ledge'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        expect(
          AscentRng.ledge(entry['runSeed'] as int, entry['id'] as int).next(),
          entry['first'],
          reason: 'ledge ${entry['id']} of run ${entry['runSeed']}',
        );
      }
    });

    test('never settles on zero, which xorshift cannot leave', () {
      for (final seed in [0, 0x9E3779B9, -1]) {
        final generator = AscentRng(seed);
        expect(
          {for (var i = 0; i < 64; i++) generator.next()}.length,
          greaterThan(1),
          reason: 'seed $seed collapsed to a constant',
        );
      }
    });
  });

  void expectLedge(Ledge got, Map<String, dynamic> want, String where) {
    expect(got.id, want['id'], reason: where);
    expect(got.kind.name, want['kind'], reason: '$where kind');
    expect(bits(got.x), want['x'], reason: '$where x');
    expect(bits(got.y), want['y'], reason: '$where y');
    expect(bits(got.width), want['width'], reason: '$where width');
    expect(bits(got.drift), want['drift'], reason: '$where drift');
    expect(got.isLanding, want['isLanding'], reason: '$where landing');
    expect(got.relic?.index ?? -1, want['relic'], reason: '$where relic');
  }

  test('a shaft is a pure function of its seed', () {
    for (final vector in fixture['shafts'] as List<dynamic>) {
      final entry = vector as Map<String, dynamic>;
      final seed = entry['seed'] as int;
      final world = AscentWorld.seeded(best: 0, isPractice: false, seed: seed);
      final expected = entry['ledges'] as List<dynamic>;
      expect(world.ledges, hasLength(expected.length));
      for (var i = 0; i < expected.length; i++) {
        expectLedge(
          world.ledges[i],
          expected[i] as Map<String, dynamic>,
          'seed $seed, ledge $i',
        );
      }
    }
  });

  test('every level builds the shaft its mode calls for', () {
    // Sampled at height rather than climbed to, so every level's shaft is
    // checked whether or not a recorded run happened to reach it.
    for (final vector in fixture['levels'] as List<dynamic>) {
      final entry = vector as Map<String, dynamic>;
      final seed = entry['seed'] as int;
      final expected = entry['ledges'] as List<dynamic>;
      for (var i = 0; i < expected.length; i++) {
        final want = expected[i] as Map<String, dynamic>;
        final data = ByteData(8)
          ..setUint32(
            0,
            int.parse((want['y'] as String).substring(0, 8), radix: 16),
          )
          ..setUint32(
            4,
            int.parse((want['y'] as String).substring(8), radix: 16),
          );
        expectLedge(
          AscentWorld.generate(want['id']! as int, data.getFloat64(0), seed),
          want,
          'seed $seed, sample $i',
        );
      }
    }
  });

  test('the samples cover every level and the floor each one opens on', () {
    // The fixture is only as good as the heights it was taken at. This is the
    // guard that notices if somebody trims the sample list back to the part of
    // the shaft a player usually sees.
    final levels = <int>{};
    var landings = 0;
    for (final vector in fixture['levels'] as List<dynamic>) {
      for (final row
          in (vector as Map<String, dynamic>)['ledges'] as List<dynamic>) {
        final want = row as Map<String, dynamic>;
        final data = ByteData(8)
          ..setUint32(
            0,
            int.parse((want['y'] as String).substring(0, 8), radix: 16),
          )
          ..setUint32(
            4,
            int.parse((want['y'] as String).substring(8), radix: 16),
          );
        levels.add(AscentWorld.levelOf(data.getFloat64(0)));
        if (want['isLanding'] == true) landings++;
      }
    }
    expect(levels, containsAll([0, 1, 2, 3, 4, 5, 6, 7]));
    expect(landings, greaterThan(0), reason: 'no sample opens a level');
  });

  test('places every relic where the fixture recorded it', () {
    final kinds = <int>{};
    for (final vector in fixture['relics'] as List<dynamic>) {
      final entry = vector as Map<String, dynamic>;
      final seed = entry['seed'] as int;
      final relics = entry['relics'] as List<dynamic>;
      for (var i = 0; i < relics.length; i++) {
        final got =
            AscentWorld.relicAt(seed, (i + 1) * AscentWorld.ledgeGap)?.index ??
            -1;
        expect(got, relics[i], reason: 'seed $seed, ledge ${i + 1}');
        kinds.add(got);
      }
    }
    expect(kinds, containsAll([0, 1, 2]), reason: 'a relic is never placed');
  });

  group('the tape', () {
    test('encodes the recorded runs to the recorded strings', () {
      for (final vector in fixture['tapes'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        final tape = AscentTape();
        for (final run in entry['runs'] as List<dynamic>) {
          final pair = run as List<dynamic>;
          final count = pair[1] as int;
          for (var i = 0; i < count; i++) {
            tape.add(AscentInput(pair[0] as int));
          }
        }
        expect(tape.ticks, entry['ticks']);
        expect(tape.encode(), entry['encoded']);
      }
    });

    test('reads back exactly what it wrote', () {
      for (final vector in fixture['tapes'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        final decoded = AscentTape.decode(entry['encoded'] as String);
        expect(decoded, isNotNull, reason: 'round trip');
        expect(decoded!.ticks, entry['ticks']);
        expect(decoded.encode(), entry['encoded']);
      }
    });

    test('refuses every malformed tape in the fixture', () {
      for (final vector in fixture['rejectedTapes'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        expect(
          AscentTape.decode(entry['encoded'] as String),
          isNull,
          reason: entry['why'] as String,
        );
      }
    });

    test('refuses a climb longer than the contract allows', () {
      final tape = AscentTape();
      for (var i = 0; i <= AscentContract.maxTicks; i++) {
        tape.add(i.isEven ? AscentInput.idle : const AscentInput(4));
      }
      expect(AscentTape.decode(tape.encode()), isNull);
    });
  });

  group('a replayed run', () {
    test('reaches the recorded height, tick for tick', () {
      for (final vector in fixture['runs'] as List<dynamic>) {
        final entry = vector as Map<String, dynamic>;
        final tape = AscentTape.decode(entry['tape'] as String);
        expect(tape, isNotNull, reason: entry['script'] as String);
        final outcome = AscentSimulation.replay(
          seed: entry['seed'] as int,
          tape: tape!,
        );
        expect(
          outcome,
          AscentOutcome(
            metres: entry['metres'] as int,
            ticks: entry['ticks'] as int,
            endedInFall: entry['endedInFall'] as bool,
            won: entry['won'] as bool,
            relicsTaken: entry['relicsTaken'] as int,
            livesLost: entry['livesLost'] as int,
          ),
          reason: '${entry['script']} on seed ${entry['seed']}',
        );
      }
    });

    test('is the same run however many times it is replayed', () {
      final entry =
          (fixture['runs'] as List<dynamic>).last as Map<String, dynamic>;
      final tape = AscentTape.decode(entry['tape'] as String)!;
      final first = AscentSimulation.replay(
        seed: entry['seed'] as int,
        tape: tape,
      );
      final second = AscentSimulation.replay(
        seed: entry['seed'] as int,
        tape: tape,
      );
      expect(first, second);
    });

    test('covers the whole shaft, not just the opening bounce', () {
      // A vector set that never reaches forty metres has never seen a cracked
      // ledge give way, a scarab drift underfoot, a ledge recycled, or the
      // floor begin to rise at sixty. It would agree across two languages and
      // mean almost nothing.
      final heights = [
        for (final vector in fixture['runs'] as List<dynamic>)
          (vector as Map<String, dynamic>)['metres']! as int,
      ];
      expect(heights.reduce((a, b) => a > b ? a : b), greaterThan(300));
      expect(heights.where((m) => m > 60), hasLength(greaterThan(4)));
      expect(
        [
          for (final vector in fixture['runs'] as List<dynamic>)
            (vector as Map<String, dynamic>)['endedInFall'],
        ].where((fell) => fell == true),
        isNotEmpty,
        reason: 'no vector ends in a fall, so the loss condition is untested',
      );
      expect(
        [
          for (final vector in fixture['runs'] as List<dynamic>)
            (vector as Map<String, dynamic>)['relicsTaken']! as int,
        ].reduce((a, b) => a + b),
        greaterThan(0),
        reason: 'no vector ever takes a relic, so their effects are untested',
      );
      expect(
        [
          for (final vector in fixture['runs'] as List<dynamic>)
            (vector as Map<String, dynamic>)['livesLost']! as int,
        ].reduce((a, b) => a + b),
        greaterThan(0),
        reason: 'no vector spends a life, so the respawn is untested',
      );
      expect(
        [
          for (final vector in fixture['runs'] as List<dynamic>)
            (vector as Map<String, dynamic>)['won'],
        ],
        contains(true),
        reason: 'no vector reaches the summit, so winning is untested',
      );
    });
  });
}
