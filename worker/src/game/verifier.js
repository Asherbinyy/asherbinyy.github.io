import {
  MAX_TICKS,
  VERSION,
  advance,
  decodeTape,
  outcomeOf,
  startOf,
} from './ascent.js';

/**
 * One submitted run, replayed a few hundred ticks at a time.
 *
 * A Cloudflare Worker on the free plan is allowed ten milliseconds of CPU per
 * request. Replaying a two-minute climb costs about fifty, and the fifteen
 * minute ceiling nearer four hundred, so the obvious shape — submit, verify,
 * answer — cannot be built here at any run length worth playing. Ten
 * milliseconds buys roughly twelve seconds of game.
 *
 * What fits is this: replay a chunk, save the place, and set an alarm to carry
 * on. Each alarm is a new invocation with a fresh budget. The arithmetic is
 * identical and in the same order — `ascent.test.js` requires that chunked and
 * single-pass replay reach the same metre — so the climber is held to exactly
 * the same standard, and the only thing the player gives up is that the board
 * settles a few seconds after they land instead of instantly.
 *
 * One Durable Object per submitted run, addressed by its run id, so two
 * submissions never share a cursor and a retry of the same one never starts a
 * second replay.
 */

/**
 * Ticks replayed per alarm.
 *
 * Deliberately far under what ten milliseconds can do. The measured rate is
 * about 330k ticks a second on a developer laptop; a Worker isolate on shared
 * hardware is slower, and there is no way to find out by how much from inside
 * one — `Date.now()` does not advance during computation in a Worker, which is
 * a timing-attack mitigation and also means a chunk cannot measure itself. So
 * the number is chosen with room rather than tuned, and a chunk that runs long
 * costs an extra hop rather than failing the run.
 */
export const CHUNK_TICKS = 512;

/** How long a finished verdict is kept for the client to read. */
const VERDICT_TTL_MS = 10 * 60 * 1000;

/** A ceiling on hops, so a malformed job can never alarm forever. */
const MAX_HOPS = Math.ceil(MAX_TICKS / CHUNK_TICKS) + 8;

export class AscentVerifier {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === 'POST' && url.pathname === '/begin') {
      return this.#begin(await request.json());
    }
    if (request.method === 'GET') {
      const verdict = await this.state.storage.get('verdict');
      if (verdict) return Response.json(verdict);
      const job = await this.state.storage.get('job');
      if (!job) return Response.json({ status: 'unknown' }, { status: 404 });
      const cursor = await this.state.storage.get('cursor');
      return Response.json({
        status: 'pending',
        ticksChecked: cursor?.ticks ?? 0,
      });
    }
    return new Response('not found', { status: 404 });
  }

  async #begin(body) {
    // Checking for an existing job and creating one has to be one step, or two
    // retries arriving together each see nothing and each start a replay of
    // the same run.
    const started = await this.state.blockConcurrencyWhile(async () => {
      // Resubmitting the same run is not a second run. Whatever this object
      // already knows is the answer, which is what makes submission idempotent
      // and what stops a retried request being ranked twice.
      const verdict = await this.state.storage.get('verdict');
      if (verdict) return verdict;
      if (await this.state.storage.get('job')) return { status: 'pending' };

      if (!decodeTape(body.tape)) return null;

      await this.state.storage.put('job', {
        seed: body.seed,
        tape: body.tape,
        nickname: body.nickname,
        playerHash: body.playerHash,
        startedAt: body.now,
        hops: 0,
      });
      await this.state.storage.put('cursor', {
        run: 0,
        offset: 0,
        ticks: 0,
        world: startOf(body.seed).world,
      });
      await this.state.storage.setAlarm(Date.now());
      return { status: 'pending', ticksChecked: 0 };
    });

    if (started === null) {
      return this.#settle({ status: 'rejected', reason: 'malformed-tape' });
    }
    return Response.json(started);
  }

  async alarm() {
    const verdict = await this.state.storage.get('verdict');
    if (verdict) {
      // The verdict has been available long enough to be read. A replay and a
      // nickname are not things to keep: the contract asks for no archive, and
      // the board holds everything that is meant to outlive the run.
      await this.state.storage.deleteAll();
      return;
    }

    const job = await this.state.storage.get('job');
    const cursor = await this.state.storage.get('cursor');
    if (!job || !cursor) return;

    const tape = decodeTape(job.tape);
    if (!tape) {
      await this.#settle({ status: 'rejected', reason: 'malformed-tape' });
      return;
    }

    if (job.hops >= MAX_HOPS) {
      await this.#settle({ status: 'rejected', reason: 'too-long' });
      return;
    }

    const next = advance(cursor, tape, CHUNK_TICKS);
    await this.state.storage.put('job', { ...job, hops: job.hops + 1 });
    await this.state.storage.put('cursor', next);

    if (!next.done) {
      await this.state.storage.setAlarm(Date.now());
      return;
    }

    const outcome = outcomeOf(next);

    // A tape that stops before the climb ends -- in a fall, or at the summit
    // -- is a run that was cut short rather than played out, and a tape that
    // carries on after the end is padded. Either way it is not the run it
    // claims to be.
    if (!(outcome.endedInFall || outcome.won) || outcome.ticks !== tape.ticks) {
      await this.#settle({ status: 'rejected', reason: 'incomplete-run' });
      return;
    }

    await this.#rank(job, outcome);
  }

  async #rank(job, outcome) {
    const board = this.env.GAME_BOARD.get(
      this.env.GAME_BOARD.idFromName(`v${VERSION}`),
    );
    const response = await board.fetch('https://board/rank', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        playerHash: job.playerHash,
        nickname: job.nickname,
        metres: outcome.metres,
        acceptedAt: job.startedAt,
      }),
    });
    const ranked = await response.json();
    await this.#settle({
      status: 'checked',
      metres: outcome.metres,
      outcome: ranked.outcome,
      rank: ranked.rank,
      entries: ranked.entries,
    });
  }

  async #settle(verdict) {
    await this.state.storage.put('verdict', verdict);
    await this.state.storage.delete('cursor');
    await this.state.storage.delete('job');
    await this.state.storage.setAlarm(Date.now() + VERDICT_TTL_MS);
    return Response.json(verdict);
  }
}
