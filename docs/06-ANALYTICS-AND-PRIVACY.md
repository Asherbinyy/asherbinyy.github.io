# Analytics and privacy — NOCTURNE

This document is the binding collection contract when analytics is enabled.
Implementation and operations are recorded in
[`32-ANALYTICS-DASHBOARD-RUNBOOK.md`](32-ANALYTICS-DASHBOARD-RUNBOOK.md).

## Current release contract

Analytics is first party and opt in. The public build has a single endpoint,
`https://nocturne-analytics.asherbinyy.workers.dev/v1/beacon`. Nothing is
measured or sent until the visitor chooses **Allow analytics**. Rejecting sends
nothing. The choice can be changed from **Consent** in the footer.

The CV and brief are standalone HTML pages, but follow the same rule, storage
key and Worker contract as the Flutter site. Admin previews never collect.

The owner is the data controller. The service runs on Cloudflare. There is no
Google Analytics, Firebase Analytics, advertising pixel or third-party tag.

## Never collect

- Form contents, search terms, contact addresses or phone numbers.
- URL query strings or fragments, except a public Google Play application ID.
- Referrer paths or referrer query strings. Only the host may be counted.
- Raw IP addresses or user-agent strings in storage or logs.
- Session replay, pointer paths, keystrokes or continuous scroll positions.
- Demographic inference, fingerprinting or cross-site identifiers.
- Any analytics from a visitor who has not accepted or has rejected.

If a future request needs one of these, it needs a new explicit owner decision
and a privacy review. It must not be added as an ordinary dashboard field.

## What consent permits

After a grant, the site may send:

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

Page activity begins at the grant. Earlier navigation, reading time and clicks
are not buffered and are never sent later.

`section_dwell` and `scroll_depth` are sent once when a route is left. Hidden
tab time is excluded. This is aggregate engagement, not a reconstruction of a
visit.

## Identifiers and storage

The consent decision is stored at `nocturne.analyticsConsent.v2`. The version
change deliberately asks visitors who previously accepted the narrower scope
to decide again. A previous rejection remains rejected.

Interaction beacons may contain a random tab ID held in `sessionStorage`. It
dies with the tab, is cleared on withdrawal and is never stored by the Worker.
It is not derived from the visitor.

For a daily unique estimate and abuse control, the Worker briefly receives the
request IP address and user-agent string from Cloudflare. It computes:

```text
visitorHash = sha256(dailyRandomSalt + IP + userAgent)
```

The raw inputs are discarded in the same invocation. The hash is not a report
dimension. It is retained for at most two days and cannot be linked across UTC
days because the 32-byte salt changes daily. Daily unique counts must never be
summed and labelled as monthly people.

Aggregate counter rows are retained for 24 months. They hold only:

```text
date, event, route, country, input class, referrer host,
campaign, target, redacted destination, count, numeric total where applicable
```

The store contains no event log and no row per visit. Numeric totals exist only
to compute mean active seconds and mean scroll quartile.

## Consent interface

- Accept and reject have equal visual weight.
- Dismissing a privacy explanation is not consent.
- The site stays usable if the visitor rejects.
- The footer exposes the current choice on every public Flutter route and on
  both standalone HTML pages.
- Withdrawal stops future collection immediately and clears the tab ID.
- If transport or storage fails, navigation and visible content continue.

The notice must state the operator, fields, exclusions, retention and how to
change the choice. It must not claim that every visit is counted: only
consented activity can appear in the dashboard.

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

- Zero network calls before consent resolves.
- No pre-consent buffering.
- Rejection and withdrawal stop every event in the same session.
- A broadened scope does not inherit an older grant.
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
