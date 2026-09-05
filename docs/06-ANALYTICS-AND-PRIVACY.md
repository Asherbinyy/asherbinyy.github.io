# Analytics and Privacy — NOCTURNE

This document is binding. Where it conflicts with a feature request, this wins.

---

## 1. Position

The owner is the data controller for this site, personally. UK GDPR and PECR apply. PECR requires consent **before** storing or reading anything on a visitor's device that is not strictly necessary. UK GDPR makes IP addresses personal data.

Beyond compliance there is a credibility argument. The owner's dissertation examines the gap between what organisations claim about AI governance and what they actually do. A portfolio that displays a privacy posture while covertly profiling visitors would be a live example of that gap, on the wrong side of it. Any reviewer with governance literacy will notice.

So the privacy design is not overhead. It is the most defensible thing on the site, and it is treated as a feature.

---

## 2. What is never collected

Not behind consent. Not at all.

- Inferred gender, age, ethnicity or any demographic attribute
- Session replay or full input recording
- Raw IP addresses in any stored record
- Cross-site identifiers or third-party cookies
- Fingerprinting: canvas, audio, font enumeration, WebGL
- Anything from a viewer who has declined

If a future request asks for one of these, refuse and cite this section.

---

## 3. Tier 0 — no consent required

Aggregate, anonymous, cookieless. No identifier of any kind is stored or set. Nothing is written to the device.

Collected:
- Route path viewed
- Coarse country, resolved **server-side** from the request, IP discarded in the same function invocation and never written to any store
- Device class only: `touch` or `pointer`
- Referrer host only, path stripped
- Campaign slug if the entry was `/r/:campaign`
- A daily visitor hash — see below

Implementation:
- A single **Cloudflare Worker** receives the beacon, resolves country, discards IP, increments a counter in Workers KV. No per-visitor row exists.
- Cloudflare rather than Firebase Functions: the site is hosted on GitHub Pages, which is static-only, so the endpoint needs a separate host. Workers' free tier covers 100k requests a day and needs no billing account. Cloudflare also exposes `request.cf.country` directly, so country resolution needs no IP lookup at all — the IP is never even read.
- Storage is counters, not events. `{ date, route, country, deviceClass, referrerHost, count }`.
- Because no per-person record is created and nothing is stored on the device, this sits outside PECR consent and does not constitute personal data processing.

**The IP must never be written, logged, or forwarded.** Verify this in the function's tests.

### Unique visitors without cookies

Unique-visitor counts are achievable without consent, using the rotating-salt approach Plausible and Fathom use.

```
salt        = random 32 bytes, regenerated every 24h, never persisted after rotation
visitorHash = sha256(salt + ipAddress + userAgent + siteId)
```

- Computed **server-side inside the function**. The IP is never written anywhere.
- Only the resulting hash is stored, and only for the current day.
- **The salt rotates every 24 hours and the old salt is destroyed.** Once it rotates, yesterday's hashes cannot be linked to today's — the identifier is mathematically unlinkable across days.
- No cookie, no `localStorage`, no `sessionStorage`. Nothing is written to the device, so PECR consent is not engaged.

This yields: unique visitors per day, new versus returning **within a day**, and views-per-visitor. It does not yield a person followed across weeks — which is the trade, and it is the right one. These are the numbers Linktree-style dashboards actually show.

Cross-day returning-visitor identification requires consent and lives in Tier 1.

Rotation must be automated (Cloudflare Cron Trigger, daily). A salt that fails to rotate silently turns this into persistent tracking. Add a test asserting the salt's age is under 24 hours, and alert if rotation fails.

---

## 4. Tier 1 — explicit opt-in only

Requires an affirmative action. No pre-ticked boxes, no implied consent from scrolling, no cookie wall.

Collected once granted:
- Session-scoped random ID, held in `sessionStorage`, dies with the tab, never linked across visits
- Time per section
- Scroll depth
- Interaction events: map node opened, case study opened, CV downloaded, language changed, theme changed
- Error reports

Rules:
- `analytics_client.dart` is a **hard no-op** until consent resolves to granted. Not a queue that flushes later — no data is captured at all before the grant.
- Withdrawal is as easy as granting, reachable from the footer on every page, and takes effect immediately.
- The session ID is regenerated per tab. It is never persisted to `localStorage`.

---

## 5. The consent panel as a feature

`/privacy` is a designed page, not a banner.

It shows a live table of every field the site can collect. For each: what it is, which tier, whether it is currently on, and — for anything currently being collected — **the actual live value from the viewer's own session.**

So a visitor sees, for example: route `/work`, device class `pointer`, country `GB`, referrer `linkedin.com`, and a row for `session time` marked off with a toggle. They can watch their own data.

Two toggles: Tier 1 on/off, and a single "collect nothing" that also disables Tier 0 counters for that viewer.

Plain-language copy. No legalese, no dark patterns, decline is the same visual weight as accept. A separate short privacy notice covers controller identity, lawful basis, retention (aggregate counters 24 months, Tier 1 events 90 days), and the request/erasure route.

This page is the honest answer to "show me you understand governance," and it costs a fraction of what a real tracking stack would.

---

## 6. Campaign links

`/r/:campaign` sets the campaign slug for the session and redirects to `/`.

Used when applying: `/r/deloitte-tech-grad`, `/r/kpmg-cyber`, `/r/bjss-mobile`. The owner then knows which application produced which visit and when.

No personal data. The slug identifies an *application*, not a person. This is first-party, purpose-limited, and needs no consent — it is functionally a UTM parameter the owner controls end to end.

Practically this is the highest-value analytics feature on the site: knowing that the traffic at 16:20 on Tuesday came from a specific application is directly actionable, in a way that no demographic estimate ever would be.

---

## 7. Alerts and digest

**Real-time alert.** When a Tier 0 CV download or a session over 90 seconds occurs, the Worker pushes a notification to the owner. Contains: campaign slug, route, country, timestamp. Nothing identifying.

**`/console` — the dashboard.** Gated by a single long random token held in a Worker secret and supplied by the owner at `/console`; not linked from anywhere public, `noindex` in `robots.txt`. Layout in `02-SCREEN-SPECS.md`.

Shows: views and unique visitors over 7/30/90 days with a sparkline, top routes, median session duration, CV downloads, referrer breakdown, country breakdown, consent grant rate, and the campaign table.

The campaign table is the operationally useful part — views and CV downloads per application, with a last-seen timestamp.

Aggregates are read through an authenticated Worker route, never by direct client access to KV. The dashboard route is code-split so its bundle is not shipped to public visitors.

Building this rather than installing Google Analytics is a deliberate choice with two returns: fewer data flows and a cleaner privacy claim, and a genuine interview artifact. "I built a cookieless analytics pipeline with rotating-salt visitor hashing" is a substantially better answer than "I added a tracking script."

**Daily digest, 12:00 Europe/London.** Cloudflare Cron Trigger → Worker → n8n → HTML email via Resend.

Contents: visits by day with a 7-day sparkline, top routes, dwell time on `/work` and case studies, CV downloads by campaign, referrer breakdown, new-versus-returning ratio (aggregate only), consent grant rate, any errors.

**Not a video.** Video rendering is slow, costly, and worse than a well-set HTML table for scanning eight numbers. An email that can be read in fifteen seconds on a phone is the correct format.

**Build the pipeline in n8n.** Scheduler triggers an n8n workflow that queries the counters, formats the digest, and sends it. This is deliberate: it turns "learning n8n" into a running production system the owner can point at, rather than a line on a skills list. It also becomes a legitimate item for `/how-it-was-built`.

---

## 8. No third-party analytics

There is no Google Analytics, no Firebase Analytics, no Plausible script, no third-party tag of any kind. Tier 0 counters plus Tier 1 events cover everything the owner actually needs, with fewer data flows and a claim that survives scrutiny.

This is also the point. A portfolio that says "I understand data governance" while loading a third-party tracker is making a claim its own network tab contradicts.

## 9. Test requirements

These are not optional tests.

- Assert zero network calls before consent resolves
- Assert `analytics_client` no-ops in the ungranted state
- Assert the Tier 0 Worker never writes an IP to any store or log
- Assert withdrawal stops collection within the same session
- Assert the session ID is absent from `localStorage`
- Assert the consent panel's live readout matches actual current collection state
- Assert the visitor-hash salt is under 24 hours old
- Assert the salt is absent from any persisted record after rotation
- Assert `/console` rejects unauthenticated aggregate reads
- Assert the `/console` bundle is not served to public routes
