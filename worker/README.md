# Analytics Worker

This service implements the server-side privacy boundary in
`docs/06-ANALYTICS-AND-PRIVACY.md`. It stores aggregate counters and a daily
deduplication hash. Raw IP addresses and user-agent values are used only as
inputs to SHA-256 inside one request invocation and are never written or logged.

Before deployment:

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
5. Deploy with `npx wrangler deploy`. The Pages release build supplies the
   checked production endpoint at
   `https://nocturne-analytics.asherbinyy.workers.dev/v1/beacon`; local builds
   omit it and therefore make no analytics requests.

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
