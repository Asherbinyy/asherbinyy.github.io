/**
 * The climb, in JavaScript, so a score can be checked rather than believed.
 *
 * This is a deliberate duplicate of
 * `lib/features/courtyard/game/domain/ascent_world.dart`,
 * `ascent_rng.dart`, `ascent_tape.dart` and `ascent_contract.dart`. Sharing one
 * implementation would be better and is not available: the client is Dart
 * compiled to WebAssembly and the verifier is a Cloudflare Worker, and the only
 * honest way to run the same physics in both is to write it twice and then
 * prove the two agree.
 *
 * The proof is `worker/contracts/fixtures/ascent-vectors.json`, generated
 * from the Dart side by `tool/generate_ascent_vectors.dart` and asserted by
 * `worker/test/ascent.test.js` here and `test/unit/features/ascent/
 * ascent_vectors_test.dart` there. Both sides check the same file, so a change
 * to either implementation that moves a single bit fails one of them.
 *
 * If you edit this file, edit the Dart, regenerate the vectors, and bump
 * VERSION. A score earned under one set of numbers does not belong on a board
 * built from another.
 */

// ---------------------------------------------------------------------------
// The contract. Mirrors ascent_contract.dart.
// ---------------------------------------------------------------------------

export const VERSION = 2;
export const TICK_RATE = 128;
/** Exactly 1/128, which is exactly representable in binary64. */
export const TICK_SECONDS = 0.0078125;
export const MAX_TICKS = TICK_RATE * 60 * 15;
export const MAX_TAPE_RUNS = 12000;

// ---------------------------------------------------------------------------
// The generator. Mirrors ascent_rng.dart.
// ---------------------------------------------------------------------------

const MASK = 0xffffffff;

/**
 * The low 32 bits of a * b. `Math.imul` computes exactly this, as a signed
 * value; `>>> 0` reads it back unsigned. The Dart side reaches the same number
 * through 16-bit halves, because it cannot assume an imul exists.
 */
function imul(a, b) {
  return Math.imul(a, b) >>> 0;
}

/**
 * The murmur3 32-bit finaliser.
 *
 * Every step stays on the 32-bit bit pattern, so it does not matter that `&`
 * hands back a signed representative here and Dart's hands back an unsigned
 * one: the bits are the same, and only the bits are ever used.
 */
export function mix(seed) {
  let z = (seed + 0x9e3779b9) & MASK;
  z = imul(z ^ (z >>> 16), 0x85ebca6b);
  z = imul(z ^ (z >>> 13), 0xc2b2ae35);
  return (z ^ (z >>> 16)) >>> 0;
}

/** Zero is xorshift's fixed point, so it is never allowed to be the state. */
function nonZero(state) {
  return state === 0 ? 0x9e3779b9 : state;
}

/** A 32-bit xorshift seeded through {@link mix}. */
export class Rng {
  constructor(state) {
    this.state = state;
  }

  /** A generator started from an arbitrary seed. */
  static fromSeed(seed) {
    return new Rng(nonZero(mix(seed >>> 0)));
  }

  /** The generator for ledge `id` in the run seeded `runSeed`. */
  static forLedge(runSeed, id) {
    return new Rng(nonZero(mix((mix(runSeed >>> 0) ^ mix(id >>> 0)) >>> 0)));
  }

  next() {
    let s = this.state;
    s = (s ^ (s << 13)) >>> 0;
    s = (s ^ (s >>> 17)) >>> 0;
    s = (s ^ (s << 5)) >>> 0;
    this.state = s;
    return s;
  }

  nextDouble() {
    return this.next() / 4294967296.0;
  }
}

// ---------------------------------------------------------------------------
// The tape. Mirrors ascent_tape.dart.
// ---------------------------------------------------------------------------

/** Whether `code` is one of the seven inputs the contract defines. */
export function isValidCode(code) {
  return code >= 0 && code <= 6 && (code & 3) !== 3;
}

function steerOf(code) {
  const lateral = code & 3;
  if (lateral === 1) return -1;
  if (lateral === 2) return 1;
  return 0;
}

function base64UrlToBytes(encoded) {
  const padded = encoded.padEnd((encoded.length + 3) & ~3, '=');
  const standard = padded.replace(/-/g, '+').replace(/_/g, '/');
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(standard)) return null;
  let binary;
  try {
    binary = atob(standard);
  } catch {
    return null;
  }
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/**
 * Reads a tape, or returns null if the string is not one.
 *
 * Null covers every way it can be wrong, and the caller is told no more than
 * that: a rejected submission learns that it was rejected, not which check
 * caught it.
 */
export function decodeTape(encoded) {
  if (typeof encoded !== 'string') return null;
  const bytes = base64UrlToBytes(encoded);
  if (bytes === null) return null;

  const codes = [];
  const counts = [];
  let ticks = 0;
  let index = 0;
  while (index < bytes.length) {
    let value = 0;
    let shift = 0;
    for (;;) {
      if (index >= bytes.length || shift > 28) return null;
      const byte = bytes[index++];
      value += (byte & 0x7f) * 2 ** shift;
      if ((byte & 0x80) === 0) break;
      shift += 7;
    }
    const code = value & 7;
    const count = Math.floor(value / 8);
    if (count < 1 || !isValidCode(code)) return null;
    // Two adjacent runs of the same code are not a tape this encoder can
    // produce. Accepting them would let one run be split into as many entries
    // as an attacker liked, which is a way to make the decoder do work without
    // making the climb any longer.
    if (codes.length > 0 && codes[codes.length - 1] === code) return null;
    codes.push(code);
    counts.push(count);
    ticks += count;
    if (codes.length > MAX_TAPE_RUNS) return null;
    if (ticks > MAX_TICKS) return null;
  }
  return { codes, counts, ticks };
}

// ---------------------------------------------------------------------------
// The world. Mirrors ascent_world.dart.
// ---------------------------------------------------------------------------

const STONE = 0;
const CRACKED = 1;
const SCARAB = 2;

const INPUT_GRACE = 0.14;
const ACCELERATION = 7;
const BRAKING = 9;
const SHORT_JUMP_SPEED = 9.5;
const LEDGE_GAP = 2.6;
const WALL_BOOST = 1.34;
const LEVEL_HEIGHT = 100;
const DIFFICULTY_STEP = 50;
const OPENING_WIDTH = 0.42;
const OPENING_SPREAD = 0.14;
const BOON_FLOOR = 50;
const BOON_CHANCE = 0.13;
const BOON_HEIGHT = 1.3;
const BOON_REACH_X = 0.09;
const BOON_REACH_Y = 0.85;
const BOON_SECONDS = 10;
const BOON_LIFT = 1.42;
const REGISTER_GAP = 24;
const LEDGE_COUNT = 40;
const BOUNCE = 13;
const GRAVITY = 22;
const STEER_RATE = 1.15;
const FALL_MARGIN = 14;

/**
 * Dart's `num.clamp`, for the values this simulation actually produces.
 *
 * Dart compares through `compareTo`, which orders -0.0 below 0.0 and NaN above
 * everything. Neither case arises here — every limit is a finite non-zero
 * bound, and a non-finite value is rejected before replay begins — so the
 * ordinary comparisons give the same answer.
 */
function clamp(value, low, high) {
  if (value < low) return low;
  if (value > high) return high;
  return value;
}

function floorSpeed(step) {
  return step === 0 ? 0 : 0.4 + step * 0.34;
}

/**
 * The ledge at `y`, in the character its level calls for.
 *
 * Every hundred metres is a different shaft: I dressed stone and wide, II
 * weathered, III carried by scarabs, IV and above all three at the narrowest
 * the ledges get. See `AscentWorld._generate` for why it is shaped that way.
 *
 * The draws happen in a fixed order — kind, width, position, drift, boon — and
 * every one of them happens whether or not its result is used, because the Dart
 * side draws them in that same order from the same generator and a stream read
 * out of step is a different shaft.
 */
export function generateLedge(id, y, rng) {
  const level = Math.floor(y / LEVEL_HEIGHT);
  const roll = rng.nextDouble();
  let kind;
  if (level <= 0) kind = STONE;
  else if (level === 1) kind = roll < 0.6 ? STONE : CRACKED;
  else if (level === 2) kind = roll < 0.58 ? STONE : SCARAB;
  else kind = roll < 0.54 ? STONE : roll < 0.8 ? CRACKED : SCARAB;

  let narrowest;
  let spread;
  if (level <= 0) {
    narrowest = OPENING_WIDTH;
    spread = OPENING_SPREAD;
  } else if (level === 1) {
    narrowest = 0.25;
    spread = 0.14;
  } else if (level === 2) {
    narrowest = 0.2;
    spread = 0.13;
  } else {
    narrowest = 0.16;
    spread = 0.12;
  }

  const width = narrowest + rng.nextDouble() * spread;
  const x = width / 2 + rng.nextDouble() * (1 - width);
  const drift = kind === SCARAB ? (rng.nextDouble() < 0.5 ? 0.16 : -0.16) : 0;
  const boonRoll = rng.nextDouble();
  return {
    id,
    kind,
    x,
    y,
    width,
    drift,
    isBroken: false,
    hasBoon: y >= BOON_FLOOR && boonRoll < BOON_CHANCE,
    boonTaken: false,
  };
}

function advanceLedge(ledge, dt) {
  if (ledge.kind !== SCARAB || ledge.drift === 0) return ledge;
  let next = ledge.x + ledge.drift * dt;
  let heading = ledge.drift;
  if (next < ledge.width / 2 || next > 1 - ledge.width / 2) {
    heading = -ledge.drift;
    next = clamp(next, ledge.width / 2, 1 - ledge.width / 2);
  }
  return { ...ledge, x: next, drift: heading };
}

function carries(ledge, climberX) {
  return Math.abs(climberX - ledge.x) <= ledge.width / 2;
}

/** A fresh run over the shaft `seed` builds. */
export function seededWorld(seed) {
  const ledges = [
    {
      id: 0,
      kind: STONE,
      x: 0.5,
      y: 0,
      width: 0.9,
      drift: 0,
      isBroken: false,
      hasBoon: false,
      boonTaken: false,
    },
  ];
  for (let i = 1; i < LEDGE_COUNT; i++) {
    ledges.push(generateLedge(i, i * LEDGE_GAP, Rng.forLedge(seed, i)));
  }
  return {
    seed,
    ledges,
    climberX: 0.5,
    climberY: 1,
    velocity: 0,
    altitude: 0,
    isOver: false,
    nextLedgeId: LEDGE_COUNT,
    registersPassed: 0,
    isGrounded: false,
    wasWalled: false,
    floorY: -FALL_MARGIN,
    horizontalVelocity: 0,
    coyoteFor: 0,
    jumpQueuedFor: 0,
    jumpHeld: false,
    jumpConsumed: false,
    lastKickSide: 0,
    boonFor: 0,
    boonsTaken: 0,
  };
}

/**
 * One tick. A transcription of `AscentWorld.step`, in the same order, because
 * floating-point addition is not associative and a tidier arrangement of the
 * same arithmetic is a different answer.
 *
 * Only the fields that feed the next tick are carried; the ones that exist so
 * the client can play a sound or draw a pose are dropped, since nothing here
 * has a speaker.
 *
 * Practice mode is absent for the same reason. In it a fall sets the climber
 * back down instead of ending the run, and a practice run can never qualify —
 * so the branch would be unreachable here, and an unreachable branch that
 * claims to mirror something is worse than no branch at all.
 */
export function step(world, dt, steer, isLeaping) {
  if (world.isOver) return world;

  const difficulty = Math.floor(world.altitude / DIFFICULTY_STEP);
  const rise = floorSpeed(difficulty) * dt;

  // Read from the state coming in, so a boon taken on the way up does not
  // retroactively raise the jump that reached it.
  const lift = world.boonFor > 0 ? BOON_LIFT : 1;

  const target = clamp(steer, -1, 1) * STEER_RATE;
  const change = (steer === 0 ? BRAKING : ACCELERATION) * dt;
  let horizontal =
    world.horizontalVelocity +
    clamp(target - world.horizontalVelocity, -change, change);
  let x = world.climberX + horizontal * dt;
  let grace = world.isGrounded
    ? INPUT_GRACE
    : Math.max(0, world.coyoteFor - dt);
  let queued =
    isLeaping && !world.jumpHeld
      ? INPUT_GRACE
      : Math.max(0, world.jumpQueuedFor - dt);
  let consumed = isLeaping && world.jumpConsumed;
  let walled = false;
  if (x <= 0) {
    x = 0;
    walled = true;
  }
  if (x >= 1) {
    x = 1;
    walled = true;
  }

  let speed = world.velocity - GRAVITY * dt;
  if (!isLeaping && world.jumpHeld && world.jumpConsumed && speed > SHORT_JUMP_SPEED) {
    speed = SHORT_JUMP_SPEED;
  }
  let y = world.climberY + speed * dt;
  let grounded = false;
  let kicked = false;
  let kickSide = world.isGrounded ? 0 : world.lastKickSide;

  if (walled && speed > 0 && !world.wasWalled && kickSide !== (x === 0 ? -1 : 1)) {
    kickSide = x === 0 ? -1 : 1;
    speed = BOUNCE * WALL_BOOST * lift;
    kicked = true;
    horizontal = x === 0 ? STEER_RATE : -STEER_RATE;
  }

  const live = world.ledges.map((ledge) => advanceLedge(ledge, dt));

  const requested = queued > 0 || (isLeaping && !consumed);
  if (requested && grace > 0 && !consumed && !kicked) {
    speed = BOUNCE * lift;
    y = world.climberY + speed * dt;
    grace = 0;
    queued = 0;
    consumed = true;
  }
  let touchedDown = false;

  if (speed < 0) {
    for (let i = live.length - 1; i >= 0; i--) {
      const ledge = live[i];
      if (ledge.isBroken) continue;
      const crossed = world.climberY >= ledge.y && y <= ledge.y;
      if (!crossed || !carries(ledge, x)) continue;

      y = ledge.y;
      speed = 0;
      grounded = true;
      touchedDown = !world.isGrounded;
      grace = INPUT_GRACE;
      if (queued > 0 && !consumed) {
        speed = BOUNCE * lift;
        grounded = false;
        grace = 0;
        queued = 0;
        consumed = true;
      }
      if (ledge.kind === CRACKED) {
        live[i] = { ...ledge, isBroken: true };
      }
      break;
    }
  }

  // Boons, taken by passing through them. Over `live` rather than the recycled
  // list, and one per tick, for the reasons `AscentWorld.step` gives.
  let tookBoon = false;
  for (let i = 0; i < live.length; i++) {
    const ledge = live[i];
    if (!ledge.hasBoon || ledge.boonTaken) continue;
    if (Math.abs(x - ledge.x) > BOON_REACH_X) continue;
    if (Math.abs(y - (ledge.y + BOON_HEIGHT)) > BOON_REACH_Y) continue;
    live[i] = { ...ledge, boonTaken: true };
    tookBoon = true;
    break;
  }
  const boonLeft = tookBoon ? BOON_SECONDS : Math.max(0, world.boonFor - dt);

  const reached = Math.max(world.altitude, y);
  const registers = Math.floor(reached / REGISTER_GAP);
  const risenFloor = Math.max(world.floorY + rise, reached - FALL_MARGIN);

  const floor = risenFloor - FALL_MARGIN * 2;
  const kept = [];
  let nextId = world.nextLedgeId;
  let highest = 0.0;
  for (const ledge of live) highest = Math.max(highest, ledge.y);
  for (const ledge of live) {
    if (ledge.y >= floor) {
      kept.push(ledge);
      continue;
    }
    highest += LEDGE_GAP;
    kept.push(generateLedge(nextId, highest, Rng.forLedge(world.seed, nextId)));
    nextId++;
  }
  // Only re-sort when the recycler actually moved something. Ledges never
  // change height otherwise, so on a tick that recycled nothing `kept` is
  // already in the order it arrived in, and sorting an ordered array under a
  // total comparator returns it unchanged. This is not a shortcut around the
  // physics -- it is the same array either way -- but the sort ran a hundred
  // and fifteen thousand times on a long run, and it recycles on a few hundred
  // of those.
  if (nextId !== world.nextLedgeId) {
    kept.sort((a, b) => (a.y === b.y ? a.id - b.id : a.y < b.y ? -1 : 1));
  }

  const fallen = y < risenFloor;

  return {
    seed: world.seed,
    ledges: kept,
    climberX: x,
    climberY: y,
    velocity: speed,
    altitude: reached,
    isOver: fallen,
    nextLedgeId: nextId,
    registersPassed: registers,
    isGrounded: grounded,
    wasWalled: walled,
    floorY: risenFloor,
    horizontalVelocity: horizontal,
    coyoteFor: grace,
    jumpQueuedFor: queued,
    jumpHeld: isLeaping,
    jumpConsumed: consumed,
    lastKickSide: touchedDown ? 0 : kickSide,
    boonFor: boonLeft,
    boonsTaken: world.boonsTaken + (tookBoon ? 1 : 0),
  };
}

/**
 * Where a part-replayed run has got to.
 *
 * `run` and `offset` are a position in the tape's run-length pairs; `ticks` is
 * how many ticks have been simulated. A fresh cursor is `{run: 0, offset: 0,
 * ticks: 0}`.
 */
export function startOf(seed) {
  return { world: seededWorld(seed), run: 0, offset: 0, ticks: 0, done: false };
}

/**
 * Replays at most `budget` ticks and hands back where it stopped.
 *
 * The climb is verified in pieces because a Cloudflare Worker is allowed ten
 * milliseconds of CPU per request on the free plan, and a two-minute run costs
 * closer to fifty. So the server replays a few hundred ticks, saves its place,
 * and wakes itself up to carry on — which is slower in wall-clock terms and
 * exactly as strict, because it is the same arithmetic in the same order.
 *
 * `advance(state, Infinity)` and repeated small budgets must agree, and
 * `leaderboard.test.js` requires it against every vector in the fixture. If
 * they ever disagree, the chunking has become part of the physics and the
 * whole contract is void.
 */
export function advance(state, tape, budget) {
  let { world, run, offset, ticks } = state;
  let spent = 0;
  while (spent < budget && run < tape.codes.length) {
    if (world.isOver) {
      return { world, run, offset, ticks, done: true };
    }
    const code = tape.codes[run];
    const steer = steerOf(code);
    const isLeaping = (code & 4) !== 0;
    world = step(world, TICK_SECONDS, steer, isLeaping);
    ticks++;
    spent++;
    offset++;
    if (offset >= tape.counts[run]) {
      run++;
      offset = 0;
    }
  }
  return {
    world,
    run,
    offset,
    ticks,
    done: run >= tape.codes.length || world.isOver,
  };
}

/** The verdict a finished state carries. */
export function outcomeOf(state) {
  return {
    metres: Math.floor(state.world.altitude),
    ticks: state.ticks,
    endedInFall: state.world.isOver,
    boonsTaken: state.world.boonsTaken,
  };
}

/**
 * Replays a decoded tape over the shaft `seed` builds, in one go.
 *
 * The entire verification: the height is what this function reaches, never what
 * a submission claimed.
 */
export function replay(seed, tape) {
  return outcomeOf(advance(startOf(seed), tape, Infinity));
}
