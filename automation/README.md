# Automation — the daily digest

Roadmap 2.6. The Worker already does the scheduled half of this; what lives
here is the workflow that turns its webhook into an email.

**This is the part of Milestone 2 that cannot be finished inside the
repository.** It needs an n8n instance and a Resend account, both of which are
the owner's to create. Everything that *can* be built is built: the trigger,
the payload, the summary logic and the message are all here and version
controlled. Importing the workflow and adding two credentials is the remaining
step.

---

## What already runs

`worker/src/index.js` has an hourly Cron Trigger that fires 01:00–23:00 UTC. On
the invocation where the London clock reads 12:00 — which is 11:00 UTC in
summer and 12:00 UTC in winter, so this survives the daylight-saving change —
it POSTs to `DIGEST_WEBHOOK_URL` and writes an idempotency key so a retry or a
second invocation cannot send twice.

The payload:

```json
{
  "generatedAt": "2026-09-06T11:00:00.000Z",
  "counters": [{ "dimensions": ["2026-09-05", "route_view", "/work", "GB", "pointer", "-", "deloitte"], "count": 18 }],
  "totals":   [{ "dimensions": ["2026-09-05", "section_dwell", "/work"], "total": 536 }]
}
```

Counter dimensions are positional:
`date | event | route | country | deviceClass | referrerHost | campaign`. The
unique-visitor row is the exception and carries only `date` and the literal
`unique_visitor`.

**Nothing in the payload identifies a person, and there is no field that
could.** The IP is discarded inside the same request that resolved the country,
and the Tier 1 session identifier is never stored as a dimension. That is why
this can be handed to a third-party automation platform at all.

---

## Setting it up

1. **Create the n8n workflow.** Import `digest-workflow.json`. It has three
   nodes: a webhook, a code node that summarises yesterday, and an HTTP request
   to Resend.
2. **Add the Resend credential.** In n8n, create a *Header Auth* credential
   named `Resend API key` with header `Authorization` and value
   `Bearer re_...`. Then open the "Send via Resend" node and select it — the
   exported `id` is a placeholder and will not resolve on import.
3. **Set two environment variables** on the n8n instance: `DIGEST_FROM` (a
   verified Resend sender) and `DIGEST_TO` (where the digest goes).
4. **Activate the workflow** and copy its production webhook URL.
5. **Give the URL to the Worker:**
   ```bash
   npx wrangler secret put DIGEST_WEBHOOK_URL
   ```
   Until this secret exists the Worker sends nothing, which is why the digest
   is dormant rather than broken today.

## Verifying it

The Worker only posts at London noon, so do not wait a day to find out whether
it works. Post the shape by hand:

```bash
curl -X POST "<the n8n webhook URL>" \
  -H 'content-type: application/json' \
  -d '{"generatedAt":"2026-09-06T11:00:00.000Z",
       "counters":[{"dimensions":["2026-09-05","route_view","/work","GB","pointer","-","deloitte"],"count":18},
                   {"dimensions":["2026-09-05","cv_opened","/work","GB","pointer","-","deloitte"],"count":3}],
       "totals":[]}'
```

That should produce one email reading
`NOCTURNE 2026-09-05: 18 views, 3 CV`.

## Two decisions worth knowing about

**A quiet day sends nothing.** The code node returns no items when there were
no views and no CV opens. A daily email that says "0" every day trains its only
reader to ignore it, and this one exists to be noticed on the day a CV gets
opened.

**It reports yesterday, not today.** The digest fires at noon, so "today" would
be half a day. Yesterday is a complete figure, which is the one worth comparing
to the day before.

## Related

- `docs/06-ANALYTICS-AND-PRIVACY.md` — what may be collected, and why this
  payload is safe to send off-platform.
- `worker/README.md` — deploying the Worker and setting its secrets.
- `docs/11-OPEN-ISSUES.md` §1.12 — the outstanding owner action.
