# Game leaderboard — app/Worker contract proposal

Updated 2026-09-13. Owner request: a more engaging game, a one-time player prompt and a visible top 5/top 10 board, retaining only the top 10 scores in the cloud. This explicitly supersedes the earlier no-leaderboard plan. **No leaderboard endpoint, prompt or persistence is implemented yet.** September 14: Claude owns both the Worker and Flutter. Do not deploy during implementation.

## Status — September 17

**The physics is frozen at version 2 and the cross-language replay agreement is proved.** This was the precondition the rest of the document depends on, and it is done:

- `AscentContract.version = 2`, a fixed timestep of exactly 1/128s, and a specified 32-bit PRNG (`AscentRng`) replacing `dart:math`'s.
- A run is a seed plus a base64url input tape, bounded at 15 minutes and 12,000 input changes. A submitted height is never read.
- `worker/src/game/ascent.js` is the JavaScript half. `worker/contracts/fixtures/ascent-vectors.json` is generated from Dart and asserted by both suites; neither writes it. 56 runs up to 507m agree on metre, tick, ending and boons taken, and eighteen ledges per seed are sampled directly at height so that every level is checked rather than only the part a bot can climb to.
- CI runs both halves.

**Version 2 empties the board.** It adds levels every hundred metres, a floor that steps up every fifty, and collectable ankhs that lift the jump — all of which change what a metre costs. A version 1 entry was earned on a different climb and is never ranked against a version 2 one. Detail: `worklog/2026-09-17-01-claude-ascent-v2.md`.

Detail on the freeze itself and the bugs it found: `worklog/2026-09-16-03-claude-frozen-physics.md`.

Still to do, in order: the endpoints below, transactional top-ten storage, and the Flutter participant flow. One correction to make plainly on the board when it ships — replay proves a score is *reachable under the physics*, not that a person reached it; a scripted tape replays exactly like a played one.

### Amendments — September 17

Two product decisions below were overruled by the owner after seeing them built, and the code now follows the amendment rather than the bullet:

- **The prompt asks for a name and nothing else.** "Explain before joining that nickname and qualifying score are public" produced a paragraph, a note about browser identity and a tick box; the owner's instruction was "just ask the name to join the leaderboard, that's it, no more and no hints". Disclosure is now carried by naming rather than explaining — the sheet is titled with the board, the field is labelled *name on the board*, the button says join it, and the board is visible behind it with other people's names on it.
- **Both answers are remembered.** "Remember only after the visitor explicitly chooses to" was the tick box. Without it, the honest default is to remember either answer: somebody who joins expects to still be on the board next time, and somebody who declines expects not to be asked again after every climb. Dismissing the sheet without answering is still not an answer and still brings it back. Change-name and forget controls are unchanged.

The board is also **top five everywhere**, not five beside play and ten in the results — the owner asked for five, and five is what a rail beside a live climb can be read at a glance.

## Product decisions

- Show top 5 compactly alongside play where space permits, and all top 10 in the start/results surface. On a narrow phone keep a clearly labelled ranking control visible; do not cover the landing area with ten rows.
- Ask for a public nickname on first game entry, with two explicit choices: join the leaderboard, or play locally. Explain before joining that nickname and qualifying score are public. No real name/email/account required.
- Remember a nickname and the decision only after the visitor explicitly chooses to remember it on this browser. A local-play choice without remembering remains memory-only. “One time” means this browser while that setting exists; clearing storage or using another device can require the prompt again. Provide change-name/forget controls.
- No automatic posting merely because someone starts playing. An opted-in participant can enable automatic eligible-score submission in the initial choice; make that behavior explicit. A local-only run never starts a cloud run or submits a score.
- One best qualifying entry per anonymous player key, ten entries maximum. This is the implementation assumption for a useful board instead of one player filling every place. Anonymous browser identity does not prove distinct humans; do not claim otherwise.
- Scores are deterministic game results, not client-supplied assertions. Start with altitude in whole metres using a versioned physics rule set. Any later combo/relic score changes require a new version/season so incompatible runs do not share a ranking.

## Proposed endpoint boundary — not deployed APIs

| Operation | Shape / behavior |
|---|---|
| `GET /v1/game/leaderboard?season=<id>` | Up to ten ordered public `{rank, nickname, score}` entries plus season/revision. No private player keys, request IPs or auth tokens. Useful empty/error states; no seeded fake scores. |
| `POST /v1/game/runs` | Explicit participating player starts a run. Return a bounded-lived signed challenge containing seed, physics version, expiry and run ID. Do not create a permanent score history. |
| `POST /v1/game/leaderboard` | Submit run proof, nickname and participant credential; validate/replay server-side, then atomically keep only the best ten. Response distinguishes accepted/rank, valid-but-not-qualified, duplicate, expired and rejected. |
| participant update/forget | Claude proposes ownership proof and exact paths. Renaming/deleting a player's retained entry must not let one visitor affect another. |

Claude should review endpoint names/shapes before wiring the client. Keep this independent of content/admin release snapshots; a leaderboard must not rewrite the owner's content documents.

## Integrity and retention

Use a single authoritative transactional ranking operation, with deterministic tie handling (earlier accepted qualifying run first), idempotent submission and per-player improvement checks. Concurrent qualifying results cannot create eleven retained scores or lose accepted higher scores. A valid non-qualifier is discarded immediately; evict the previous last entry in the same transaction. Do not keep an append-only score/replay/name archive, backup table or rejected-score history.

Server replay must use the same seeded physics/version and a bounded input stream, duration and payload size. Clamp control values, reject non-finite numbers, impossible input sequences, unsupported versions and expired/replayed challenges. A submitted height or hash generated solely by the client is not verification. Practice mode never qualifies. Use synthetic runs to prove replay agrees before accepting public results.

Transient abuse-control counters/challenges may expire, but are not a permanent score archive. Document their precise fields and TTLs; do not log nickname, token, replay or submission bodies. No new visitor fingerprinting or analytics. Cloud platform operational logs/limits must be checked explicitly before release; “only ten entries” is a data-model guarantee, not an invented claim about every provider log.

## Flutter responsibilities

- One entry flow tied to an explicit remembered choice, never a recurring modal on every restart.
- In-memory local runs remain fully playable if offline, declined, unavailable or in an unsupported season. Never label an unverified local result as globally ranked.
- Keep top 5/top 10 rendering accessible with keyboard/screen reader/RTL and clear loading, empty, stale and failure states. Avoid continuous polling; refresh at entry, after a submission and on a deliberate refresh action.
- Wait for a server challenge only when the player chooses a qualifying run; retain a local-play escape. Version mismatches explain that the local run cannot qualify instead of breaking the game.
- Store no nickname/decision/player key before the relevant explicit visitor choice. Send no participant identifiers before joining. Clearing the remembered setting stops future submissions; define cloud-entry deletion separately and visibly.

## Acceptance before connection

Claude: deterministic replay agreement, one-slot race with many submissions, at most ten persistent score entries, idempotency, tie order, self-improvement, non-qualifier disposal, eviction, rename/delete authorization, abuse/expiry handling and no body logging. Document binding/migration/cost implications without enabling production.

Codex: prompt once after remembered choice; restart does not reprompt; local-only/offline runs cause no participant calls/storage; nickname change and forget; real top-ten responses; submitted/ranked distinction; smaller phone layouts; keyboard/RTL/reduced motion; updated game physics/version compatibility.

The board is complete only after real Flutter-to-Worker fixture flows pass. Current UI/game work does not close this item.

## Claude task to take after auth merge blockers

Claude now owns both halves. Implement and verify the versioned replay contract, Flutter participant flow and transactional top-ten storage using sanitized fixtures. Record shape changes in `worker/contracts/INTEGRATION.md`, retention/TTL details and cross-language replay evidence. The old restriction on Flutter edits is revoked. Do not deploy or silently activate visitor data collection. See `29-CLAUDE-FULL-PROJECT-HANDOFF.md`.
