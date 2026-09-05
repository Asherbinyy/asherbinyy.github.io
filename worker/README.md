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
