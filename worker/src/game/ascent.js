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

export const VERSION = 3;
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

/** Relics, as their index in the Dart enum. -1 is none. */
const NO_RELIC = -1;
const ANKH = 0;
const EYE = 1;
const FEATHER = 2;

const INPUT_GRACE = 0.14;
const ACCELERATION = 7;
const BRAKING = 9;
const SHORT_JUMP_SPEED = 9.5;
const LEDGE_GAP = 2.6;
const WALL_BOOST = 1.34;
const LEVEL_HEIGHT = 100;
const LEVEL_COUNT = 8;
export const SUMMIT = LEVEL_HEIGHT * LEVEL_COUNT;
const DIFFICULTY_STEP = 50;
const OPENING_WIDTH = 0.42;
const OPENING_SPREAD = 0.14;
const RELIC_HEIGHT = 1.3;
const RELIC_REACH_X = 0.09;
const RELIC_REACH_Y = 0.85;
const EYE_SECONDS = 10;
const EYE_SLOW = 0.3;
const FEATHER_SECONDS = 5;
const FEATHER_JUMPS = 2;
const MAX_LIVES = 3;
const LIFE_CLEARANCE = 6;
const WIND_MAX = 0.18;
const WIND_PERIOD = 5.5;
const ICE_GRIP = 0.2;
const FLOOR_CAP = 5;
const ANKH_BAND = 125;
const ANKH_OFFSET = 25;
const ANKH_WINDOW = 25;
const EYE_BAND = 50;
const EYE_OFFSET = 5;
const EYE_WINDOW = 15;
const FEATHER_BAND = 50;
const FEATHER_OFFSET = 30;
const FEATHER_WINDOW = 15;
const ANKH_STREAM = 0x40000000;
const EYE_STREAM = 0x50000000;
const FEATHER_STREAM = 0x60000000;
const EYE_FIRST_BAND = 1;
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
  return step === 0 ? 0 : Math.min(0.4 + step * 0.34, FLOOR_CAP);
}

/** The level a height is in, 0 to 7. Mirrors `AscentWorld.levelOf`. */
export function levelOf(y) {
  return clamp(Math.floor(y / LEVEL_HEIGHT), 0, LEVEL_COUNT - 1);
}

function isWindy(level) {
  return level === 1 || level === 7;
}

function isIcy(level) {
  return level === 2 || level === 7;
}

/** The wind's push at `time`: a triangle wave, exact in both languages. */
export function windAt(time) {
  const u = time / WIND_PERIOD;
  const f = u - Math.floor(u);
  return WIND_MAX * (1 - 4 * Math.abs(f - 0.5));
}

/** The relic, if any, on a ledge at `y`. Mirrors `AscentWorld.relicAt`. */
export function relicAt(seed, y) {
  if (y <= 0 || y >= SUMMIT) return NO_RELIC;
  const hits = (band, offset, window, stream, firstBand) => {
    const index = Math.floor(y / band);
    if (index < firstBand) return false;
    const roll = Rng.forLedge(seed, stream + index).nextDouble();
    const target = index * band + offset + roll * window;
    return target >= y && target < y + LEDGE_GAP;
  };
  if (hits(ANKH_BAND, ANKH_OFFSET, ANKH_WINDOW, ANKH_STREAM, 0)) return ANKH;
  if (hits(EYE_BAND, EYE_OFFSET, EYE_WINDOW, EYE_STREAM, EYE_FIRST_BAND)) return EYE;
  if (hits(FEATHER_BAND, FEATHER_OFFSET, FEATHER_WINDOW, FEATHER_STREAM, 0)) {
    return FEATHER;
  }
  return NO_RELIC;
}

/**
 * The ledge at `y`, in the character its level calls for. See
 * `AscentWorld._generate` for the eight levels.
 *
 * Four draws, in a fixed order — kind, width, position, drift — whatever the
 * ledge turns out to be, because the Dart side draws them in that same order
 * from the same generator and a stream read out of step is a different shaft.
 */
export function generateLedge(id, y, rng, seed) {
  const level = levelOf(y);
  const roll = rng.nextDouble();
  const widthRoll = rng.nextDouble();
  const xRoll = rng.nextDouble();
  const driftRoll = rng.nextDouble();
  if (level > 0 && levelOf(y - LEDGE_GAP) < level) {
    return {
      id,
      kind: STONE,
      x: 0.5,
      y,
      width: 1,
      drift: 0,
      isBroken: false,
      isLanding: true,
      relic: NO_RELIC,
      relicTaken: false,
    };
  }
  let kind;
  if (level <= 0) kind = STONE;
  else if (level === 1) kind = roll < 0.6 ? STONE : CRACKED;
  else if (level === 2) kind = roll < 0.58 ? STONE : SCARAB;
  else if (level === 3) kind = roll < 0.54 ? STONE : roll < 0.8 ? CRACKED : SCARAB;
  else if (level === 4) kind = roll < 0.4 ? STONE : roll < 0.85 ? CRACKED : SCARAB;
  else if (level === 5) kind = roll < 0.42 ? STONE : roll < 0.6 ? CRACKED : SCARAB;
  else kind = roll < 0.5 ? STONE : roll < 0.75 ? CRACKED : SCARAB;

  let narrowest;
  let spread;
  if (level <= 0) {
    narrowest = OPENING_WIDTH;
    spread = OPENING_SPREAD;
  } else if (level === 1) {
    narrowest = 0.25;
    spread = 0.14;
  } else if (level === 2) {
    narrowest = 0.22;
    spread = 0.13;
  } else if (level === 3) {
    narrowest = 0.19;
    spread = 0.12;
  } else if (level === 4) {
    narrowest = 0.18;
    spread = 0.12;
  } else if (level === 5) {
    narrowest = 0.17;
    spread = 0.11;
  } else {
    narrowest = 0.16;
    spread = 0.1;
  }

  const width = narrowest + widthRoll * spread;
  const x = width / 2 + xRoll * (1 - width);
  const pace = level === 5 ? 0.26 : level >= 6 ? 0.2 : 0.16;
  const drift = kind === SCARAB ? (driftRoll < 0.5 ? pace : -pace) : 0;
  return {
    id,
    kind,
    x,
    y,
    width,
    drift,
    isBroken: false,
    isLanding: false,
    relic: relicAt(seed, y),
    relicTaken: false,
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
      isLanding: false,
      relic: NO_RELIC,
      relicTaken: false,
    },
  ];
  for (let i = 1; i < LEDGE_COUNT; i++) {
    ledges.push(generateLedge(i, i * LEDGE_GAP, Rng.forLedge(seed, i), seed));
  }
  return {
    seed,
    ledges,
    climberX: 0.5,
    climberY: 1,
    velocity: 0,
    altitude: 0,
    isOver: false,
    won: false,
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
    time: 0,
    lives: 0,
    eyeFor: 0,
    featherFor: 0,
    airJumps: 0,
    relicsTaken: 0,
    livesLost: 0,
  };
}

/**
 * One tick. A transcription of `AscentWorld.step`, in the same order, because
 * floating-point addition is not associative and a tidier arrangement of the
 * same arithmetic is a different answer.
 *
 * Only the fields that feed the next tick are carried; the ones that exist so
 * the client can play a sound or draw a pose are dropped. Practice mode is
 * absent: a practice run can never qualify, so the branch would be
 * unreachable here.
 */
export function step(world, dt, steer, isLeaping) {
  if (world.isOver) return world;

  const level = levelOf(world.climberY);
  const now = world.time + dt;

  const difficulty = Math.floor(world.altitude / DIFFICULTY_STEP);
  const rise = floorSpeed(difficulty) * dt * (world.eyeFor > 0 ? EYE_SLOW : 1);

  const target = clamp(steer, -1, 1) * STEER_RATE;
  const grip = world.isGrounded && isIcy(level) ? ICE_GRIP : 1;
  const change = (steer === 0 ? BRAKING : ACCELERATION) * dt * grip;
  let horizontal =
    world.horizontalVelocity +
    clamp(target - world.horizontalVelocity, -change, change);
  let x = world.climberX + horizontal * dt;
  if (!world.isGrounded && isWindy(level)) x = x + windAt(world.time) * dt;
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
  let airUsed = world.isGrounded ? 0 : world.airJumps;

  if (walled && speed > 0 && !world.wasWalled && kickSide !== (x === 0 ? -1 : 1)) {
    kickSide = x === 0 ? -1 : 1;
    speed = BOUNCE * WALL_BOOST;
    kicked = true;
    horizontal = x === 0 ? STEER_RATE : -STEER_RATE;
  }

  const live = world.ledges.map((ledge) => advanceLedge(ledge, dt));

  const requested = queued > 0 || (isLeaping && !consumed);
  let jumped = false;
  if (requested && grace > 0 && !consumed && !kicked) {
    speed = BOUNCE;
    y = world.climberY + speed * dt;
    grace = 0;
    queued = 0;
    consumed = true;
    jumped = true;
  }
  if (
    !jumped &&
    !kicked &&
    world.featherFor > 0 &&
    isLeaping &&
    !world.jumpHeld &&
    grace <= 0 &&
    airUsed < FEATHER_JUMPS
  ) {
    speed = BOUNCE;
    y = world.climberY + speed * dt;
    queued = 0;
    consumed = true;
    airUsed = airUsed + 1;
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
      airUsed = 0;
      if (queued > 0 && !consumed) {
        speed = BOUNCE;
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

  let took = NO_RELIC;
  for (let i = 0; i < live.length; i++) {
    const ledge = live[i];
    if (ledge.relic === NO_RELIC || ledge.relicTaken) continue;
    if (Math.abs(x - ledge.x) > RELIC_REACH_X) continue;
    if (Math.abs(y - (ledge.y + RELIC_HEIGHT)) > RELIC_REACH_Y) continue;
    live[i] = { ...ledge, relicTaken: true };
    took = ledge.relic;
    break;
  }
  const livesNow = took === ANKH ? Math.min(world.lives + 1, MAX_LIVES) : world.lives;
  const eyeLeft = took === EYE ? EYE_SECONDS : Math.max(0, world.eyeFor - dt);
  const featherLeft =
    took === FEATHER ? FEATHER_SECONDS : Math.max(0, world.featherFor - dt);
  const relics = world.relicsTaken + (took === NO_RELIC ? 0 : 1);

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
    kept.push(generateLedge(nextId, highest, Rng.forLedge(world.seed, nextId), world.seed));
    nextId++;
  }
  // Only re-sort when the recycler actually moved something: ledges never
  // change height otherwise, so `kept` is already in order and sorting it
  // under a total comparator would return it unchanged.
  if (nextId !== world.nextLedgeId) {
    kept.sort((a, b) => (a.y === b.y ? a.id - b.id : a.y < b.y ? -1 : 1));
  }

  const carried = {
    seed: world.seed,
    ledges: kept,
    altitude: reached,
    nextLedgeId: nextId,
    registersPassed: registers,
    time: now,
    eyeFor: eyeLeft,
    featherFor: featherLeft,
    relicsTaken: relics,
    livesLost: world.livesLost,
    won: false,
  };

  if (reached >= SUMMIT) {
    return {
      ...world,
      ...carried,
      climberX: x,
      climberY: y,
      velocity: speed,
      isOver: true,
      won: true,
      floorY: risenFloor,
      lives: livesNow,
    };
  }

  const fallen = y < risenFloor;

  if (fallen && livesNow > 0) {
    let landing = null;
    for (const ledge of kept) {
      if (!ledge.isBroken && ledge.y <= reached) landing = ledge;
    }
    const spot = landing ?? kept[0];
    return {
      ...carried,
      climberX: spot.x,
      climberY: spot.y,
      velocity: 0,
      isOver: false,
      isGrounded: true,
      wasWalled: false,
      floorY: Math.min(risenFloor, spot.y - LIFE_CLEARANCE),
      horizontalVelocity: 0,
      coyoteFor: 0,
      jumpQueuedFor: 0,
      jumpHeld: isLeaping,
      jumpConsumed: isLeaping,
      lastKickSide: 0,
      lives: livesNow - 1,
      airJumps: 0,
      livesLost: world.livesLost + 1,
    };
  }

  return {
    ...carried,
    climberX: x,
    climberY: y,
    velocity: speed,
    isOver: fallen,
    isGrounded: grounded,
    wasWalled: walled,
    floorY: risenFloor,
    horizontalVelocity: horizontal,
    coyoteFor: grace,
    jumpQueuedFor: queued,
    jumpHeld: isLeaping,
    jumpConsumed: consumed,
    lastKickSide: touchedDown ? 0 : kickSide,
    lives: livesNow,
    airJumps: airUsed,
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
    endedInFall: state.world.isOver && !state.world.won,
    won: state.world.won,
    relicsTaken: state.world.relicsTaken,
    livesLost: state.world.livesLost,
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
