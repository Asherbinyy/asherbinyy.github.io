import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import {
  MAX_TAPE_RUNS,
  MAX_TICKS,
  Rng,
  TICK_RATE,
  TICK_SECONDS,
  VERSION,
  decodeTape,
  generateLedge,
  isValidCode,
  mix,
  replay,
  seededWorld,
} from '../src/game/ascent.js';

/**
 * Holds the JavaScript climb to the same fixture the Dart one is held to.
 *
 * This is the whole reason a leaderboard can exist here. The client is Dart
 * compiled to WebAssembly; the verifier is this Worker. Nothing about them
 * guarantees that `velocity - 22 * 0.0078125` lands on the same bit fifteen
 * thousand times running, and a port that reads correctly is not evidence that
 * it is. So both sides replay the same seeds and tapes and are required to
 * reach the same metre, the same tick, and the same ending.
 *
 * The fixture is generated from Dart by `tool/generate_ascent_vectors.dart`.
 * Nothing here writes it, on purpose: a test that can regenerate what it checks
 * against agrees with itself and proves nothing.
 */

const fixture = JSON.parse(
  readFileSync(
    new URL('../contracts/fixtures/ascent-vectors.json', import.meta.url),
    'utf8',
  ),
);

const KINDS = ['stone', 'cracked', 'scarab'];

/** A double as sixteen hex digits, the same way Dart wrote it. */
function bits(value) {
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, value);
  return view.getBigUint64(0).toString(16).padStart(16, '0');
}

test('the contract matches the one the fixture was generated under', () => {
  assert.equal(VERSION, fixture.version);
  assert.equal(TICK_RATE, fixture.tickRate);
  assert.equal(MAX_TICKS, fixture.maxTicks);
  assert.equal(MAX_TAPE_RUNS, fixture.maxTapeRuns);
  assert.equal(bits(TICK_SECONDS), fixture.tickSeconds);
  assert.equal(TICK_SECONDS * TICK_RATE, 1);
});

test('mixing a seed agrees with Dart', () => {
  for (const vector of fixture.rng.mix) {
    assert.equal(mix(vector.in), vector.out, `mix(${vector.in})`);
  }
});

test('the generator stream agrees with Dart', () => {
  for (const vector of fixture.rng.streams) {
    const rng = Rng.fromSeed(vector.seed);
    const sequence = [];
    for (let i = 0; i < 8; i++) sequence.push(rng.next());
    assert.deepEqual(sequence, vector.sequence, `seed ${vector.seed}`);

    const doubles = Rng.fromSeed(vector.seed);
    const asDoubles = [];
    for (let i = 0; i < 4; i++) asDoubles.push(bits(doubles.nextDouble()));
    assert.deepEqual(asDoubles, vector.doubles, `seed ${vector.seed} doubles`);
  }
});

test('a ledge generator agrees with Dart', () => {
  for (const vector of fixture.rng.ledge) {
    assert.equal(
      Rng.forLedge(vector.runSeed, vector.id).next(),
      vector.first,
      `ledge ${vector.id} of run ${vector.runSeed}`,
    );
  }
});

/** The double sixteen hex digits stand for. */
function unbits(hex) {
  const view = new DataView(new ArrayBuffer(8));
  view.setBigUint64(0, BigInt(`0x${hex}`));
  return view.getFloat64(0);
}

function assertLedge(got, want, where) {
  assert.equal(got.id, want.id, where);
  assert.equal(KINDS[got.kind], want.kind, `${where} kind`);
  assert.equal(bits(got.x), want.x, `${where} x`);
  assert.equal(bits(got.y), want.y, `${where} y`);
  assert.equal(bits(got.width), want.width, `${where} width`);
  assert.equal(bits(got.drift), want.drift, `${where} drift`);
  assert.equal(got.hasBoon, want.hasBoon, `${where} boon`);
}

test('a shaft is built bit for bit the way Dart builds it', () => {
  for (const vector of fixture.shafts) {
    const world = seededWorld(vector.seed);
    assert.equal(world.ledges.length, vector.ledges.length);
    for (let i = 0; i < vector.ledges.length; i++) {
      assertLedge(
        world.ledges[i],
        vector.ledges[i],
        `seed ${vector.seed}, ledge ${i}`,
      );
    }
  }
});

test('every level builds the shaft its mode calls for', () => {
  // Sampled at height rather than climbed to. No recorded run reaches the
  // third or fourth level, so without these two hundred metres of shaft would
  // be ground neither implementation had ever been checked on.
  const levels = new Set();
  let withBoon = 0;
  let withoutBoon = 0;
  for (const vector of fixture.levels) {
    for (let i = 0; i < vector.ledges.length; i++) {
      const want = vector.ledges[i];
      const y = unbits(want.y);
      assertLedge(
        generateLedge(want.id, y, Rng.forLedge(vector.seed, want.id)),
        want,
        `seed ${vector.seed}, sample ${i}`,
      );
      levels.add(Math.floor(y / 100));
      if (want.hasBoon) withBoon++;
      else withoutBoon++;
    }
  }
  for (const level of [0, 1, 2, 3]) {
    assert.ok(levels.has(level), `no sample in level ${level}`);
  }
  assert.ok(withBoon > 0, 'no sampled ledge carries a boon');
  assert.ok(withoutBoon > 0);
});

test('a tape decodes to the runs Dart encoded', () => {
  for (const vector of fixture.tapes) {
    const tape = decodeTape(vector.encoded);
    assert.ok(tape, 'decoded');
    assert.equal(tape.ticks, vector.ticks);
    assert.deepEqual(
      tape.codes.map((code, i) => [code, tape.counts[i]]),
      vector.runs,
    );
  }
});

test('a malformed tape is refused', () => {
  for (const vector of fixture.rejectedTapes) {
    assert.equal(decodeTape(vector.encoded), null, vector.why);
  }
  assert.equal(decodeTape(null), null, 'not a string at all');
  assert.equal(decodeTape('a'), null, 'a single base64 character');
});

test('an input code that steers both ways at once is refused', () => {
  for (const code of [3, 7, -1, 8]) assert.equal(isValidCode(code), false);
  for (const code of [0, 1, 2, 4, 5, 6]) assert.equal(isValidCode(code), true);
});

test('every recorded run replays to the same metre and the same tick', () => {
  for (const vector of fixture.runs) {
    const tape = decodeTape(vector.tape);
    assert.ok(tape, `${vector.script} decoded`);
    const outcome = replay(vector.seed, tape);
    assert.deepEqual(
      outcome,
      {
        metres: vector.metres,
        ticks: vector.ticks,
        endedInFall: vector.endedInFall,
        boonsTaken: vector.boonsTaken,
      },
      `${vector.script} on seed ${vector.seed}`,
    );
  }
});

test('the vectors reach far enough up the shaft to mean something', () => {
  // The same guard the Dart suite carries. A fixture that never passes forty
  // metres has never seen a cracked ledge, a scarab, a recycled ledge or the
  // rising floor, and two implementations agreeing about the opening bounce is
  // not agreement worth ranking anybody on.
  const heights = fixture.runs.map((run) => run.metres);
  assert.ok(Math.max(...heights) > 300, 'no vector climbs past 300m');
  assert.ok(
    heights.filter((metres) => metres > 60).length > 4,
    'too few vectors pass the first level change',
  );
  assert.ok(
    fixture.runs.some((run) => run.endedInFall),
    'no vector ends in a fall',
  );
  assert.ok(
    fixture.runs.reduce((sum, run) => sum + run.boonsTaken, 0) > 0,
    'no vector ever takes a boon, so the lift is untested',
  );
});
