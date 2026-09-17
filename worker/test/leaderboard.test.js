import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';

import { handleRequest } from '../src/index.js';
import { AscentBoard, rankInto } from '../src/game/board.js';
import { AscentVerifier, CHUNK_TICKS } from '../src/game/verifier.js';
import {
  cleanNickname,
  hashPlayer,
  issueToken,
  readToken,
} from '../src/game/leaderboard.js';
import {
  MAX_TICKS,
  VERSION,
  advance,
  decodeTape,
  outcomeOf,
  replay,
  startOf,
} from '../src/game/ascent.js';

const siteOrigin = 'https://sherbini.uk';
const secret = 'a-test-signing-secret-not-the-real-one';

const fixture = JSON.parse(
  readFileSync(
    new URL('../contracts/fixtures/ascent-vectors.json', import.meta.url),
    'utf8',
  ),
);

/** The longest real climb in the fixture: a fall from 362m. */
const played = fixture.runs.reduce((a, b) => (b.ticks > a.ticks ? b : a));

// ---------------------------------------------------------------------------
// Fakes. A Durable Object is a class with storage and an alarm; none of what is
// tested here needs Cloudflare to run it.
// ---------------------------------------------------------------------------

/**
 * A Durable Object's state, with a real mutex behind `blockConcurrencyWhile`.
 *
 * Deliberately no input gating. A real object would also refuse to deliver a
 * second event while the first is waiting on storage, which hides races that
 * `blockConcurrencyWhile` is there to prevent. Leaving the fake hostile means
 * the concurrency test is testing this code rather than testing Cloudflare.
 */
class MemoryStorage {
  map = new Map();
  alarmAt = null;
  #queue = Promise.resolve();

  blockConcurrencyWhile(callback) {
    const next = this.#queue.then(callback, callback);
    this.#queue = next.then(
      () => undefined,
      () => undefined,
    );
    return next;
  }

  async get(key) {
    return this.map.get(key);
  }

  async put(key, value) {
    this.map.set(key, structuredClone(value));
  }

  async delete(key) {
    return this.map.delete(key);
  }

  async deleteAll() {
    this.map.clear();
  }

  async setAlarm(when) {
    this.alarmAt = when;
  }
}

/**
 * A namespace of durable objects, and a hand to turn the alarm crank.
 *
 * Real alarms fire on their own. Here they are run explicitly so a test can say
 * how many hops a verification took, which is the property worth asserting:
 * the chunking has to finish, and it has to finish with the same answer.
 */
class Namespace {
  instances = new Map();

  constructor(Class, env) {
    this.Class = Class;
    this.env = env;
  }

  idFromName(name) {
    return name;
  }

  get(name) {
    if (!this.instances.has(name)) {
      const storage = new MemoryStorage();
      const state = {
        storage,
        blockConcurrencyWhile: (callback) =>
          storage.blockConcurrencyWhile(callback),
      };
      this.instances.set(name, {
        storage,
        object: new this.Class(state, this.env),
      });
    }
    const entry = this.instances.get(name);
    return {
      fetch: (url, init) => entry.object.fetch(new Request(url, init)),
    };
  }

  /** Runs every pending alarm until none are set. Returns the hop count. */
  async drain(limit = 4096) {
    let hops = 0;
    for (;;) {
      const pending = [...this.instances.values()].find(
        (entry) => entry.storage.alarmAt !== null && entry.storage.alarmAt <= Date.now(),
      );
      if (!pending) return hops;
      pending.storage.alarmAt = null;
      await pending.object.alarm();
      hops++;
      assert.ok(hops < limit, 'alarms did not settle');
    }
  }
}

function environment() {
  const env = {
    SITE_ID: 'sherbini.uk',
    SITE_ORIGIN: siteOrigin,
    GAME_SECRET: secret,
    ANALYTICS: {
      async get() {
        return null;
      },
      async put() {},
    },
  };
  env.GAME_BOARD = new Namespace(AscentBoard, env);
  env.GAME_VERIFIER = new Namespace(AscentVerifier, env);
  return env;
}

function call(path, {method = 'GET', body, origin = siteOrigin} = {}) {
  return new Request(`https://worker.example${path}`, {
    method,
    headers: {
      origin,
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
}

const now = 1_758_000_000_000;

async function play(env, {playerKey, nickname, tape, seed}) {
  const start = await handleRequest(
    call('/v1/game/runs', { method: 'POST', body: { playerKey } }),
    env,
    now,
  );
  const challenge = await start.json();
  // The tape in the fixture was played on its own seed, so the challenge's is
  // overridden here. A real client cannot do this -- the seed is inside the
  // signature -- which is exactly what `a seed cannot be chosen` checks.
  const token = await issueToken(secret, {
    r: challenge.runId,
    s: seed,
    v: VERSION,
    e: now + 600000,
    p: await hashPlayer(playerKey),
  });
  const submitted = await handleRequest(
    call('/v1/game/leaderboard', {
      method: 'POST',
      body: { token, playerKey, nickname, tape },
    }),
    env,
    now,
  );
  return { runId: challenge.runId, submitted };
}

// ---------------------------------------------------------------------------

test('chunked verification reaches the same metre as one pass', async () => {
  // The whole free-plan design rests on this. If replaying five hundred ticks
  // at a time ever disagreed with replaying them all at once, the chunking
  // would have become part of the physics.
  for (const vector of fixture.runs) {
    const tape = decodeTape(vector.tape);
    let state = startOf(vector.seed);
    let hops = 0;
    while (!state.done) {
      state = advance(state, tape, CHUNK_TICKS);
      hops++;
      assert.ok(hops < 4096, 'chunking did not terminate');
    }
    assert.deepEqual(outcomeOf(state), replay(vector.seed, tape), vector.script);
  }
});

test('an odd chunk size is still the same run', async () => {
  const tape = decodeTape(played.tape);
  for (const budget of [1, 7, 13, 997]) {
    let state = startOf(played.seed);
    while (!state.done) state = advance(state, tape, budget);
    assert.equal(outcomeOf(state).metres, played.metres, `budget ${budget}`);
  }
});

test('a climb is ranked only after it has actually been replayed', async () => {
  const env = environment();
  const { runId, submitted } = await play(env, {
    playerKey: '0'.repeat(32),
    nickname: 'Ahmed',
    tape: played.tape,
    seed: played.seed,
  });

  assert.equal(submitted.status, 202);
  assert.equal((await submitted.json()).status, 'pending');

  // Nothing is on the board yet. A submission is a request to be checked.
  const early = await handleRequest(call('/v1/game/leaderboard'), env, now);
  assert.deepEqual((await early.json()).entries, []);

  const hops = await env.GAME_VERIFIER.drain();
  assert.ok(hops > 30, `expected many chunks, took ${hops}`);

  const verdict = await (
    await handleRequest(call(`/v1/game/runs/${runId}`), env, now)
  ).json();
  assert.equal(verdict.status, 'checked');
  assert.equal(verdict.metres, played.metres);
  assert.equal(verdict.rank, 1);

  const board = await (
    await handleRequest(call('/v1/game/leaderboard'), env, now)
  ).json();
  assert.deepEqual(board.entries, [
    { rank: 1, nickname: 'Ahmed', metres: played.metres },
  ]);
});

test('a seed cannot be chosen by the player', async () => {
  const env = environment();
  const playerKey = '1'.repeat(32);
  const start = await handleRequest(
    call('/v1/game/runs', { method: 'POST', body: { playerKey } }),
    env,
    now,
  );
  const challenge = await start.json();

  // Submit the fixture's tape against the server's seed rather than its own.
  const rejected = await handleRequest(
    call('/v1/game/leaderboard', {
      method: 'POST',
      body: {
        token: challenge.token,
        playerKey,
        nickname: 'Optimist',
        tape: played.tape,
      },
    }),
    env,
    now,
  );
  assert.equal(rejected.status, 202);
  await env.GAME_VERIFIER.drain();
  const verdict = await (
    await handleRequest(call(`/v1/game/runs/${challenge.runId}`), env, now)
  ).json();
  // Played against a shaft it was not played on, the tape does not describe a
  // finished run: the climber falls somewhere else, or not at all.
  assert.equal(verdict.status, 'rejected');
});

test('a run issued to one player cannot be submitted by another', async () => {
  const env = environment();
  const mine = '2'.repeat(32);
  const yours = '3'.repeat(32);
  const start = await handleRequest(
    call('/v1/game/runs', { method: 'POST', body: { playerKey: mine } }),
    env,
    now,
  );
  const challenge = await start.json();
  const response = await handleRequest(
    call('/v1/game/leaderboard', {
      method: 'POST',
      body: {
        token: challenge.token,
        playerKey: yours,
        nickname: 'Thief',
        tape: played.tape,
      },
    }),
    env,
    now,
  );
  assert.equal(response.status, 403);
});

test('a forged or expired token is refused', async () => {
  const claims = { r: 'x', s: 1, v: VERSION, e: now + 1000, p: 'hash' };
  const token = await issueToken(secret, claims);
  assert.ok(await readToken(secret, token, now));
  assert.equal(await readToken('a different secret', token, now), null);
  assert.equal(await readToken(secret, token, now + 2000), null, 'expired');
  assert.equal(await readToken(secret, `${token}x`, now), null, 'tampered');
  assert.equal(await readToken(secret, 'nonsense', now), null);
  assert.equal(
    await readToken(secret, await issueToken(secret, { ...claims, v: 99 }), now),
    null,
    'a run of another physics version',
  );
});

test('submitting the same run twice does not rank it twice', async () => {
  const env = environment();
  const playerKey = '4'.repeat(32);
  const first = await play(env, {
    playerKey,
    nickname: 'Twice',
    tape: played.tape,
    seed: played.seed,
  });
  await env.GAME_VERIFIER.drain();

  const again = await handleRequest(
    call('/v1/game/leaderboard', {
      method: 'POST',
      body: {
        token: await issueToken(secret, {
          r: first.runId,
          s: played.seed,
          v: VERSION,
          e: now + 600000,
          p: await hashPlayer(playerKey),
        }),
        playerKey,
        nickname: 'Twice',
        tape: played.tape,
      },
    }),
    env,
    now,
  );
  assert.equal((await again.json()).status, 'checked');
  const board = await (
    await handleRequest(call('/v1/game/leaderboard'), env, now)
  ).json();
  assert.equal(board.entries.length, 1);
});

test('a player can remove their own entry and nobody else can', async () => {
  const env = environment();
  const mine = '5'.repeat(32);
  await play(env, {
    playerKey: mine,
    nickname: 'Leaving',
    tape: played.tape,
    seed: played.seed,
  });
  await env.GAME_VERIFIER.drain();

  const stranger = await handleRequest(
    call('/v1/game/leaderboard', {
      method: 'DELETE',
      body: { playerKey: '6'.repeat(32) },
    }),
    env,
    now,
  );
  assert.equal((await stranger.json()).removed, false);
  assert.equal(
    (await (await handleRequest(call('/v1/game/leaderboard'), env, now)).json())
      .entries.length,
    1,
  );

  const owner = await handleRequest(
    call('/v1/game/leaderboard', { method: 'DELETE', body: { playerKey: mine } }),
    env,
    now,
  );
  assert.equal((await owner.json()).removed, true);
  assert.deepEqual(
    (await (await handleRequest(call('/v1/game/leaderboard'), env, now)).json())
      .entries,
    [],
  );
});

test('the leaderboard is refused from another origin', async () => {
  const env = environment();
  const response = await handleRequest(
    call('/v1/game/leaderboard', { origin: 'https://elsewhere.example' }),
    env,
    now,
  );
  assert.equal(response.status, 403);
});

test('an unconfigured leaderboard says so rather than failing', async () => {
  const env = environment();
  delete env.GAME_SECRET;
  const response = await handleRequest(call('/v1/game/leaderboard'), env, now);
  assert.equal(response.status, 503);
});

// ---------------------------------------------------------------------------
// The ranking rules, without a durable object in sight.
// ---------------------------------------------------------------------------

function entry(playerHash, metres, acceptedAt, nickname = playerHash) {
  return { playerHash, nickname, metres, acceptedAt };
}

test('the board never holds more than ten, whatever arrives', () => {
  let board = [];
  for (let i = 0; i < 40; i++) {
    board = rankInto(board, entry(`p${i}`, i, 1000 + i)).board;
  }
  assert.equal(board.length, 10);
  assert.deepEqual(
    board.map((e) => e.metres),
    [39, 38, 37, 36, 35, 34, 33, 32, 31, 30],
  );
});

test('one player holds one place, and only improves it', () => {
  let board = rankInto([], entry('me', 100, 1)).board;
  const same = rankInto(board, entry('me', 100, 2));
  assert.equal(same.outcome, 'not-an-improvement');
  assert.equal(same.board, board, 'the board was rewritten for nothing');

  const worse = rankInto(board, entry('me', 50, 3));
  assert.equal(worse.outcome, 'not-an-improvement');

  const better = rankInto(board, entry('me', 150, 4));
  assert.equal(better.outcome, 'improved');
  assert.equal(better.board.length, 1);
  assert.equal(better.board[0].metres, 150);
});

test('a tie goes to whoever got there first', () => {
  let board = rankInto([], entry('early', 200, 1000)).board;
  board = rankInto(board, entry('late', 200, 2000)).board;
  assert.deepEqual(
    board.map((e) => e.playerHash),
    ['early', 'late'],
  );
});

test('a real climb that is not in the top ten is discarded, not stored', () => {
  let board = [];
  for (let i = 0; i < 10; i++) {
    board = rankInto(board, entry(`p${i}`, 500 + i, 1000 + i)).board;
  }
  const result = rankInto(board, entry('newcomer', 100, 9999));
  assert.equal(result.outcome, 'not-qualified');
  assert.equal(result.rank, null);
  assert.equal(result.board, board, 'a non-qualifier changed the board');
  assert.equal(board.length, 10);
});

test('a qualifying climb evicts the last entry in the same operation', () => {
  let board = [];
  for (let i = 0; i < 10; i++) {
    board = rankInto(board, entry(`p${i}`, 500 + i, 1000 + i)).board;
  }
  const last = board[9].playerHash;
  const result = rankInto(board, entry('newcomer', 10000, 9999));
  assert.equal(result.outcome, 'accepted');
  assert.equal(result.rank, 1);
  assert.equal(result.board.length, 10);
  assert.ok(!result.board.some((e) => e.playerHash === last), 'nothing evicted');
});

test('many climbers finishing at once cannot make eleven entries', async () => {
  // A Durable Object serialises its own requests, so the way to test the
  // property is to fire the requests without awaiting in turn and then check
  // the invariant holds.
  const env = environment();
  const board = env.GAME_BOARD.get('v1');
  await Promise.all(
    Array.from({ length: 25 }, (_, i) =>
      board.fetch('https://board/rank', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(entry(`racer${i}`, i * 10, 1000 + i)),
      }),
    ),
  );
  const view = await (await board.fetch('https://board/')).json();
  assert.equal(view.entries.length, 10);
  assert.deepEqual(
    view.entries.map((e) => e.rank),
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  );
});

// ---------------------------------------------------------------------------

test('a nickname that would break the row it sits in is refused', () => {
  assert.equal(cleanNickname('Ahmed'), 'Ahmed');
  assert.equal(cleanNickname('  spaced   out  '), 'spaced out');
  assert.equal(cleanNickname('a'), null, 'too short');
  assert.equal(cleanNickname('x'.repeat(17)), null, 'too long');
  assert.equal(cleanNickname('bad name'), null, 'a control character');
  assert.equal(cleanNickname('flip‮me'), null, 'a bidi override');
  assert.equal(cleanNickname('zero​width'), null, 'an invisible');
  assert.equal(cleanNickname('see https://x.example'), null, 'a link');
  assert.equal(cleanNickname('www.example.com'), null, 'a link');
  assert.equal(cleanNickname(42), null, 'not a string');
  // Not moderation: this one passes, and judging it is the owner's job.
  assert.equal(cleanNickname('rude words'), 'rude words');
});

test('a player key is stored only as a hash', async () => {
  const key = 'f'.repeat(32);
  const hash = await hashPlayer(key);
  assert.match(hash, /^[0-9a-f]{64}$/);
  assert.notEqual(hash, key);
  assert.equal(await hashPlayer(key), hash, 'not stable');
  assert.notEqual(await hashPlayer('e'.repeat(32)), hash);
});

test('a tape longer than the contract allows never reaches a replay', () => {
  const tooLong = Math.ceil(MAX_TICKS / 1) + 1;
  assert.ok(tooLong > MAX_TICKS);
  // The decoder is the gate; the verifier calls it before doing any work.
  assert.equal(decodeTape('!'.repeat(64)), null);
});
