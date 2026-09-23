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

## Running the admin panel locally

Neither of these reaches Cloudflare, and neither needs a production credential.

```bash
node worker/dev/serve.js 8788
npm exec --yes --package=node@22 -- node worker/dev/verify-a1.js
```

`serve.js` runs `handleRequest` behind a plain Node server with an in-memory
key/value store, the sanitized fixtures in `worker/contracts/fixtures/` standing
in for both the published content and the site's own bundle, and a throwaway
admin token printed at startup. `verify-a1.js` drives that panel in headless
Chrome over the DevTools protocol — no automation package is installed — and
writes screenshots to `docs/audits/`. It needs Node 22 for the global
`WebSocket`, which is why it runs through `npm exec`.

Use the harness for anything that involves typing into the panel. Editing the
owner's live content with his real token to find out whether a button works is
not a test.

## Signing in to the admin

Two credentials, and they do different jobs.

**`ADMIN_TOKEN`** is the deployment secret, set with `wrangler secret put`. It
is the way back in when the password is forgotten, and the reason an
unreachable password store cannot lock the owner out of his own site. Keep it
somewhere he can actually find it.

**A password**, set from the Account section of the panel and stored beside the
content as a PBKDF2-SHA256 verifier with a per-record salt and iteration count.
Never as itself.

Either one is exchanged at `POST /v1/admin/session` for a **session token**,
and that is all the browser ever holds. Sessions expire twelve hours after
their last use and seven days after they were created, whichever comes first,
and are stored under a hash of themselves so a dump of the namespace yields
nothing replayable. `DELETE /v1/admin/session` ends one. Changing the password
ends all of them and issues a replacement to whoever made the change.

**No Cloudflare account credential ever reaches the browser**, and nothing in
the panel can touch the hosting account.

### The iteration count

`passwordIterations` in `worker/src/index.js` is 50,000. That is a compromise
with the Workers free plan's per-request processor budget, which a password
hash has to fit inside — stretching only happens at sign-in and at a password
change, never on an ordinary request, but a sign-in that exceeds the budget
fails. Verify a sign-in after the first deployment that sets a password.

Because of that ceiling, **length is what protects this password**; the panel
requires at least twelve characters. Each stored hash records the count it was
made with, so the number can be raised later without invalidating the existing
password.

### Being locked out

Two credentials, two rules, and the split is the point.

**An ordinary password** is throttled: ten wrong attempts an hour, counted
atomically, and once the limit is reached the endpoint stops answering
*without deriving a key at all* — including for a correct password. An earlier
version derived for every guess and only changed the answer once the limit was
reached, which meant guessing was never actually bounded.

**The deployment secret** is a constant-time comparison of a 48-character
random value. It is not throttled, because there is nothing to protect from
repetition and it has to keep working when everything else is stopped. It is
how the owner gets back in, and getting in clears the count.

So guessing is bounded, and nobody can lock the owner out of his own site by
typing rubbish at it.

### Sessions expire on idleness, not on age

Twelve hours after last use, seven days after they began, whichever comes
first. Using a session pushes the idle clock back, but only once the remaining
window has fallen below half — so an afternoon of editing costs one write
rather than one per request, and the absolute limit is never extended.

## Where content mutations and sessions are serialised

Workers KV has no compare-and-set and no transaction, so publishing used to
read the head, decide the base matched, and then write the document, the
revision and the head as three separate operations. Two publishes arriving
together both read revision 0, both decided they were current, and both
answered "revision 1" — one of them silently gone, history entry and all.

A `ContentStore` Durable Object now owns publish, rollback and withdrawal.
There is one instance across the network, its execution is serialised, and the
commit happens in a single `storage.transaction`.

The same object owns three other things that turned out to have the same
problem:

- **Failed-attempt counting**, and the admission decision itself. A slot is
  taken and the limit checked in one step, before any key is derived, so a
  burst of guesses gets exactly the attempts that were left rather than all
  deriving against the same stale count.
- **The session lifecycle.** Renewal, logout and password-change invalidation
  cannot interleave, so a renewal already in flight cannot put back a session
  that was just revoked.
- **The password verifier and its generation.** Rotating the password writes
  the verifier, advances the generation and clears every session in one
  transaction. A login carries the generation it verified against, and the
  session is only issued if that is still current -- so a login held up long
  enough for a rotation to finish underneath it is refused rather than handed
  a session earned with a password that no longer opens anything. A session
  also carries its generation and is rejected if it is superseded.

Reads that have to agree go through it in one operation too: a document and the
revision it is, and the whole set of overrides that goes into a release.

### The fallback is not protected

Without the binding the Worker keeps working, and keeps being honest about what
that means:

- Concurrent publishes can still lose a revision. `GET /v1/admin/content`
  reports `atomic: false` and the panel says so in the editing bar.
- **Session renewal is switched off entirely.** Read-then-write renewal cannot
  be made safe against a logout landing between the two, and a stale renewal
  that resurrects a revoked session is worse than a session that expires twelve
  hours after it was created. Where it cannot be done safely it is not done.

Do not describe a deployment running this way as having concurrency
protection.

### Production activation

The binding is enabled in `wrangler.toml` as `CONTENT_STORE`, using the
SQLite-backed `ContentStore` class. Before activation:

1. **Confirm plan availability** for SQLite-backed Durable Objects
   (`new_sqlite_classes`), and **what it costs** — every public content read
   becomes a request to the object rather than a KV read.
2. **Migrate the content.** The object starts empty. Copy the existing
   `content:*`, `revision:*` and `revision-head:*` values from the CONTENT
   namespace into `doc:*`, `rev:*` and `head:*` in the object *before* the
   binding goes live, or the first read finds nothing and the site falls back
   to its bundle. Do it against a preview environment first.
3. **Know the way back.** Re-commenting the binding returns the Worker to KV
   immediately, and the KV values are untouched by the object — so a rollback
   loses whatever was published after the switch, and nothing before it. Copy
   the object's contents back out if anything was published in between.

Before the production activation, the account's existing game objects proved
SQLite Durable Objects were available and the production CONTENT namespace
was inspected through Cloudflare: it contained zero keys. There was therefore
no published document, revision or password record to migrate. The content
write path was also run in local workerd: eight concurrent same-base saves
produced one 200 and seven 409s, with one retained revision.

Nothing about the public response shape changes either way.

## Content validation

`worker/contracts/content-schema.js` describes the five editable documents and
`worker/contracts/validate.js` checks a document against it. Both run inside the
Worker: `PUT /v1/admin/content/<file>` refuses a document that does not match
with **422** and the failing paths, and `POST /v1/admin/validate` answers the
same question without writing anything. `POST /v1/admin/review` adds what would
change and which claims moved.

The schema is derived from `lib/content/models/*.dart`. When those change, the
schema has to follow: `worker/test/content-schema.test.js` validates every
document in `assets/content/` and fails when the two disagree.

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
`contracts/fixtures/ascent-vectors.json`.

Replaying costs CPU — about 50ms for a two-minute climb, measured — and the
**Workers Free plan allows 10ms of CPU per request**, which is roughly twelve
seconds of game. So a run is replayed about five hundred ticks at a time, each
chunk in its own Durable Object alarm with a fresh budget, and a submission
answers `202 pending` until the last chunk lands. Chunked and single-pass replay
are required by test to reach the same metre.

On a paid plan this could be one request instead. The chunking is not wasted
either way: it also means one long submission cannot occupy a request slot.

### The bindings

Already in `wrangler.toml`: two Durable Object bindings, `GAME_BOARD` and
`GAME_VERIFIER`, and the `v1-ascent-board` migration that creates them. Both
classes are exported from `worker/src/index.js`, which is the Worker's `main`,
so nothing else has to be wired up.

`new_sqlite_classes` rather than `new_classes`: the SQLite storage backend is
the one available on the free plan, and the key-value backend is not. The
`compatibility_date` already in the file is recent enough; Wrangler fails
loudly rather than quietly if it or the CLI is too old.

**The migration is the one irreversible step.** It creates a namespace on the
account, and the free plan refuses a downgrade while a key-value-backed
namespace exists — this one is SQLite-backed, so that does not apply, but it is
worth knowing that deleting a namespace later is a separate deliberate act.

What is left is one secret, which signs the run challenges:

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
