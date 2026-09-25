# Analytics and privacy — NOCTURNE

This document is the binding collection contract. Implementation and operations
are recorded in
[`32-ANALYTICS-DASHBOARD-RUNBOOK.md`](32-ANALYTICS-DASHBOARD-RUNBOOK.md).

## Current release contract

The public build sends bounded first-party analytics to
`https://nocturne-analytics.asherbinyy.workers.dev/v1/beacon` automatically.
There is no consent panel, cookie, analytics preference, browser identifier,
`localStorage` value or analytics `sessionStorage` value. Admin previews and
`/console` never report activity.

The CV and brief are standalone HTML pages and use the same Worker contract.
The owner is the data controller and the service runs on Cloudflare. There is
no Google Analytics, Firebase Analytics, advertising pixel or third-party tag.

## Never collect

- Form contents, search terms, contact addresses or phone numbers.
- URL query strings or fragments, except a public Google Play application ID.
- Referrer paths or referrer query strings. Only the host may be counted.
- Raw IP addresses or user-agent strings in storage or logs.
- Cookies, browser analytics identifiers or per-event visitor records.
- Session replay, pointer paths, keystrokes or continuous scroll positions.
- Demographic inference, fingerprint profiles or cross-site identifiers.

If a future request needs one of these, it requires a new explicit owner
decision and privacy review. It must not be added as an ordinary dashboard
field.

## Recorded fields

The site may send:

- route views;
- outbound public app and link activations, with a stable target name and a
  redacted public destination;
- CV opens;
- gallery opens and external media activations;
- name-audio plays;
- game starts and completed results;
- journey stops, case studies, language changes, theme changes and visible
  errors;
- active time on a route, as whole seconds from 2 to 3,600;
- deepest scroll quartile, from 1 to 4;
- input class (`touch` or `pointer`);
- referrer host, coarse Cloudflare country and an owner-defined campaign slug.

`section_dwell` and `scroll_depth` are sent once when a route is left. Hidden
tab time is excluded. This is aggregate engagement, not a reconstruction of a
visit.

## Daily uniqueness and storage

For a daily unique estimate and abuse control, the Worker briefly receives the
request IP address and user-agent string from Cloudflare. It computes:

```text
visitorHash = sha256(dailyRandomSalt + IP + userAgent)
```

The raw inputs are discarded in the same invocation. The hash is not a report
dimension. It is retained for at most two UTC dates and cannot be linked across
days because the 32-byte salt changes daily. Daily unique counts must never be
summed and labelled as monthly people.

Aggregate counter rows are retained for 24 months. They hold only:

```text
date, event, route, country, input class, referrer host,
campaign, target, redacted destination, count, numeric total where applicable
```

The store contains no event log and no row per visit. Numeric totals exist only
to compute mean active seconds and mean scroll quartile.

## Reporting rules

- Page, country, source, device and campaign shares use page views as their
  denominator.
- Clicks count activations. They do not prove that an app was installed, a CV
  was read, a message was sent or a booking completed.
- Clicks per 100 views is a frequency, not a conversion rate, and may exceed
  100 because one view can produce several clicks.
- Missing days remain missing in graphs; the dashboard must not invent zeros.
- Old counters without targets are labelled as legacy data, not guessed.
- Direct navigation and unavailable referrers cannot be distinguished.
- Daily uniques are estimates per UTC day. There is no weekly or monthly unique
  visitor total.
- Empty states, disabled collection and backend errors are visibly different.

## Required checks

- No consent or analytics preference UI appears on Flutter, CV or brief.
- A configured production client records immediately.
- No analytics cookie or browser identifier is created.
- Raw IP and user-agent values never enter storage.
- Concurrent requests cannot lose counter increments or double count one daily
  visitor.
- Storage failure rolls back the whole event.
- Rate limiting does not change accepted counters.
- Salt rotation breaks cross-day linkage; retention alarms delete expired
  hashes and counters.
- Destinations remove private queries, fragments, credentials and contact
  values.
- Admin insights require authentication and show exact stored aggregates.
- Empty charts contain no fabricated points.
- The public preview and `/console` never report analytics.
