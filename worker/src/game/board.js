/**
 * The top ten, and the one place it is allowed to change.
 *
 * Ranking is a read-modify-write, and KV cannot do one safely: it is eventually
 * consistent with no compare-and-swap, so two climbers finishing at the same
 * moment would each read the same board, each append, and one of them would
 * quietly lose their place — or both would land and leave eleven entries. A
 * Durable Object handles one request at a time, which makes the whole operation
 * atomic without a transaction keyword anywhere.
 *
 * `rankInto` is separated out and pure so the rules can be tested without a
 * Durable Object, a network, or a clock.
 */

/** How many entries the board keeps. The owner asked for ten. */
export const BOARD_SIZE = 10;

/**
 * A total order over entries.
 *
 * Higher first; a tie goes to whoever was accepted first, which is the rule
 * `26-GAME-LEADERBOARD-CONTRACT.md` sets; and the player hash breaks a tie in
 * the tie, so that the order is total rather than merely mostly-decided. A
 * comparator that can return 0 for two different entries leaves their order to
 * whatever sort the runtime ships, which is not a property a ranking should
 * have.
 */
function before(a, b) {
  if (a.metres !== b.metres) return b.metres - a.metres;
  if (a.acceptedAt !== b.acceptedAt) return a.acceptedAt - b.acceptedAt;
  if (a.playerHash === b.playerHash) return 0;
  return a.playerHash < b.playerHash ? -1 : 1;
}

/**
 * Places `candidate` on `board`, or explains why it did not go on.
 *
 * Returns `{board, outcome, rank, best}`. The board is a new array; the one
 * passed in is never modified. Outcomes:
 *
 * - `accepted` — it is on the board, at `rank`.
 * - `improved` — the same, and it replaced this player's own earlier entry.
 * - `not-an-improvement` — this player already has an equal or better entry,
 *   which stays. One player holds one place; a good run does not get to push
 *   its own author down a row.
 * - `not-qualified` — a real climb that was not in the top ten. It is
 *   discarded here and now rather than kept anywhere, which is the contract's
 *   instruction and also the only way "ten entries" is a fact about the data
 *   rather than a claim about a query.
 */
export function rankInto(board, candidate, limit = BOARD_SIZE) {
  const mine = board.find((e) => e.playerHash === candidate.playerHash);
  if (mine && candidate.metres <= mine.metres) {
    return {
      board,
      outcome: 'not-an-improvement',
      rank: board.indexOf(mine) + 1,
      best: mine.metres,
    };
  }

  const others = board.filter((e) => e.playerHash !== candidate.playerHash);
  const next = [...others, candidate].sort(before).slice(0, limit);
  const place = next.findIndex((e) => e.playerHash === candidate.playerHash);

  if (place === -1) {
    return { board, outcome: 'not-qualified', rank: null, best: candidate.metres };
  }
  return {
    board: next,
    outcome: mine ? 'improved' : 'accepted',
    rank: place + 1,
    best: candidate.metres,
  };
}

/** What a viewer is allowed to see: a place, a name and a height. */
export function publicView(board) {
  return board.map((entry, index) => ({
    rank: index + 1,
    nickname: entry.nickname,
    metres: entry.metres,
  }));
}

/**
 * The board, as a Durable Object.
 *
 * One instance for the whole season, addressed by name, so every write to the
 * ranking is serialised through it by construction.
 */
export class AscentBoard {
  constructor(state) {
    this.state = state;
  }

  async #board() {
    return (await this.state.storage.get('board')) ?? [];
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === 'GET') {
      const board = await this.#board();
      return Response.json({
        entries: publicView(board),
        updatedAt: (await this.state.storage.get('updatedAt')) ?? null,
      });
    }

    if (request.method === 'POST' && url.pathname === '/rank') {
      const candidate = await request.json();
      // Read, rank and write are one indivisible step, said so explicitly.
      //
      // A Durable Object's input gating would very likely cover this on its
      // own, because every await between the read and the write is a storage
      // call. "Very likely" is the wrong standard for the operation that
      // decides whether somebody's climb counted, and it depends on a platform
      // subtlety that a later edit -- one `await fetch()` added in the middle
      // -- would silently break. `blockConcurrencyWhile` is the guarantee
      // written down.
      const result = await this.state.blockConcurrencyWhile(async () => {
        const board = await this.#board();
        const ranked = rankInto(board, candidate);
        if (ranked.board !== board) {
          // One write for the whole ranking. Evicting the previous last entry
          // is not a second step that could fail on its own -- it already
          // happened, in `rankInto`, to the array being stored here.
          await this.state.storage.put('board', ranked.board);
          await this.state.storage.put('updatedAt', candidate.acceptedAt);
        }
        return ranked;
      });
      return Response.json({
        outcome: result.outcome,
        rank: result.rank,
        best: result.best,
        entries: publicView(result.board),
      });
    }

    if (request.method === 'POST' && url.pathname === '/forget') {
      // Removing your own entry must not be able to touch anybody else's, so
      // the only thing this can match on is the hash of the key the caller
      // proved they hold.
      const { playerHash } = await request.json();
      const { removed, entries } = await this.state.blockConcurrencyWhile(
        async () => {
          const board = await this.#board();
          const remaining = board.filter((e) => e.playerHash !== playerHash);
          const didRemove = remaining.length !== board.length;
          if (didRemove) await this.state.storage.put('board', remaining);
          return { removed: didRemove, entries: remaining };
        },
      );
      return Response.json({ removed, entries: publicView(entries) });
    }

    return new Response('not found', { status: 404 });
  }
}
