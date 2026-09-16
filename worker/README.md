# Portfolio Worker

This service implements the server-side privacy boundary in
`docs/06-ANALYTICS-AND-PRIVACY.md`. It stores aggregate counters and a daily
deduplication hash. Raw IP addresses and user-agent values are used only as
inputs to SHA-256 inside one request invocation and are never written or logged.

Current-state note (2026-09-11): this Worker also serves content, media and the admin panel. The Pages release currently omits `ANALYTICS_ENDPOINT`, so visitor collection is disabled. The setup steps below describe initial provisioning; inspect existing bindings before creating any namespace. Admin limitations and the new publication contract are in [`docs/15-ADMIN-AND-MEDIA.md`](../docs/15-ADMIN-AND-MEDIA.md).

Before an explicitly authorized deployment:

1. Authenticate with `npx wrangler login`.
2. The `ANALYTICS` namespace binding in `wrangler.toml` points to the deployed
   production namespace. Create a separate preview namespace before using a
   preview environment.
3. Set or rotate the long random console token with
   `npx wrangler secret put CONSOLE_TOKEN`.
4. Optionally set `ALERT_WEBHOOK_URL` and `DIGEST_WEBHOOK_URL` as secrets. The
   former receives CV-open and failed-salt-rotation alerts; the latter receives
   the noon Europe/London aggregate digest. No webhook is called when its
   secret is absent.
5. For the admin panel, create the content namespace and uncomment its binding
   in `wrangler.toml`:

   ```
   npx wrangler kv namespace create CONTENT
   npx wrangler secret put ADMIN_TOKEN   # 48+ random characters
   ```

   Both are optional. With neither set the Worker behaves exactly as it did
   before: `/v1/content/*` returns 404 and the site reads its bundle, and the
   write endpoints answer 401 or 503 rather than pretending to have stored
   anything.

   `ADMIN_TOKEN` is a different secret from `CONSOLE_TOKEN` and must stay that
   way. The console token is handed to a dashboard that only reads counters;
   the admin token can rewrite what the site says about the owner. Rotating
   either is `wrangler secret put` again, with no code change.

6. Deploy with `npx wrangler deploy` only for an authorized release. Pages
   currently omits the analytics endpoint. Deploying the Worker does not enable
   collection in the public client; content relay configuration is separate.

The midnight UTC trigger rotates the 32-byte daily salt. The second trigger runs
hourly from 01:00 through 23:00 UTC, verifies that rotation happened, and sends
the digest once at local London noon, including across daylight-saving changes.
Keeping midnight out of the second trigger prevents two independent invocations
from rotating the same salt concurrently. Counter keys expire after 24 calendar
months; daily visitor hashes expire after two days; digest idempotency keys
expire after two days.

## Runtime and release verification

Wrangler 4.129.0 requires Node 22 or later. The machine's default Node 20 can
remain installed: run the deployment tool in an isolated npm runtime instead.
The following invocation was verified with Node 22.23.2 and Wrangler 4.129.0:

```bash
npm exec --yes --package=node@22 --package=wrangler@4.129.0 -- wrangler --version
npm exec --yes --package=node@22 -- node --test worker/test/*.test.js
npm exec --yes --package=node@22 --package=wrangler@4.129.0 -- wrangler deploy --dry-run
npm exec --yes --package=node@22 --package=wrangler@4.129.0 -- wrangler deploy
```

Run these from the repository root so Wrangler reads `wrangler.toml`. Use the
existing authenticated Cloudflare account. A normal code deployment preserves
existing secrets; do not rotate `CONSOLE_TOKEN` just to publish new code.

Pages and the Worker deploy separately. A green Pages release does not deploy
`worker/src/index.js`. When a release changes that file or its bindings, include
the Worker deployment in the release and record its version ID in the worklog.
Keep absent optional beacon fields omitted so older Workers continue accepting
Tier 0 events while the two deployments are being coordinated.

After deployment, check `/v1/writing` with the configured site Origin: it should
return parseable RSS, not just a successful status. Check that missing Origin
is rejected and that `/v1/aggregates` rejects an unauthenticated read. Verify an
authenticated console read using the owner's existing token, entered through
the console UI rather than copied into source or logs.

A synthetic accepted beacon writes production counters. Do not use one as a
routine health check without explicit authorization; use local contract tests
and a consented browser session for positive event verification. Document any
production test data and its cleanup separately from real visitor metrics.

## The climb's leaderboard

Three endpoints under `/v1/game/`, all same-origin, plus two Durable Objects.
None of it exists until the bindings below are added: without them the Worker
answers `503 Leaderboard is not configured` and the client falls back to a best
score kept on the device, which is what it does today.

### Why it is built the way it is

A score cannot be a number the browser sends, so the server replays the run:
the client submits the seed it was given and the keys that were pressed, and the
Worker simulates it with the same physics. `src/game/ascent.js` is that physics,
proved bit-identical to the Dart client's by
`contracts/fixtures/ascent-v1-vectors.json`.

Replaying costs CPU — about 50ms for a two-minute climb, measured — and the
**Workers Free plan allows 10ms of CPU per request**, which is roughly twelve
seconds of game. So a run is replayed about five hundred ticks at a time, each
chunk in its own Durable Object alarm with a fresh budget, and a submission
answers `202 pending` until the last chunk lands. Chunked and single-pass replay
are required by test to reach the same metre.

On a paid plan this could be one request instead. The chunking is not wasted
either way: it also means one long submission cannot occupy a request slot.

### What to add to `wrangler.toml`

```toml
[[durable_objects.bindings]]
name = "GAME_BOARD"
class_name = "AscentBoard"

[[durable_objects.bindings]]
name = "GAME_VERIFIER"
class_name = "AscentVerifier"

[[migrations]]
tag = "v1-ascent-board"
new_sqlite_classes = ["AscentBoard", "AscentVerifier"]
```

`new_sqlite_classes` rather than `new_classes`: the SQLite storage backend is
the one available on the free plan, and the key-value backend is not. This needs
a recent `compatibility_date` and a recent Wrangler; both fail loudly rather
than quietly if they are too old.

Then one secret, which signs the run challenges:

```
npx wrangler secret put GAME_SECRET    # 32+ random characters
```

It must not be `ADMIN_TOKEN` or `CONSOLE_TOKEN`. A leaked `GAME_SECRET` lets
somebody mint their own run challenges and choose their own shaft; it does not
let them write content or read counters, and the separation should stay that
way.

### What is stored, and what is not

The board holds at most ten entries, each `{playerHash, nickname, metres,
acceptedAt}`. `playerHash` is the SHA-256 of a random value the visitor's own
browser generated — never a name, an email, an account or an IP, and never the
key itself, so the board cannot hand back the thing that proves ownership of an
entry. It identifies a browser, not a person, and the page says so.

A run being verified holds its tape and nickname for as long as the check takes,
and its verdict for ten minutes so the client can read it. Then the object
deletes itself. There is no score history, no rejected-submission log and no
replay archive; a climb that is real but outside the top ten is discarded in the
same operation that judged it.

### Checking it after a deployment

`GET /v1/game/leaderboard` with the site Origin should return
`{"season":"v1","entries":[],...}` on an empty board, and 403 without the
Origin. `POST /v1/game/runs` with a 32-hex `playerKey` should return a signed
token. Nothing writes a board entry until a submitted tape has been replayed.
