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

## Where content mutations are serialised

Workers KV has no compare-and-set and no transaction, so publishing used to
read the head, decide the base matched, and then write the document, the
revision and the head as three separate operations. Two publishes arriving
together both read revision 0, both decided they were current, and both
answered "revision 1" — one of them silently gone, history entry and all.

A `ContentStore` Durable Object now owns publish, rollback and withdrawal.
There is one instance across the network, its execution is serialised, and the
commit happens in a single `storage.transaction`. The same object counts failed
credential attempts, for the same reason.

**The binding is deliberately not enabled.** `wrangler.toml` carries it
commented out with the two things to confirm first — plan availability for
SQLite-backed objects, and what moving public reads onto a different meter
costs — plus the migration note: the object starts empty, so existing KV
content must be copied in before it is switched on. Without the binding the
Worker behaves exactly as it does today, `atomic` is false in
`GET /v1/admin/content`, and the panel says in the editing bar that concurrent
edits are not protected.

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
