# 2026-09-05-14 — Work ledger, Recruiter Mode, consent and the Lighthouse gate

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 6b73120

## Goal
Complete the remaining Milestone 1 tasks in one session at the owner's request:
1.9 the work ledger, 1.10 consent and Tier 0 analytics, 1.11 Recruiter Mode,
and the outstanding part of 1.12, the Lighthouse gate.

## The store link verification, done rather than asserted
Task 1.9's definition of done says to verify each store link **manually**. All
eleven were requested with a browser user agent, following redirects:

| Result | Applications |
|---|---|
| 200 | tripster, az-courses (both stores), enjoy, malboos, tiara-beauty, tekrar, wasset, mostaqbaly, az-exams |
| **404** | **snunu** |

**`snunu` is dead.** `https://apps.apple.com/us/app/snunu/id1627473292` returns
404 in every storefront tried — us, gb, sa, eg, ae, ru — and Apple's own lookup
API returns zero results for id 1627473292, so the listing does not exist rather
than being region-restricted. The roadmap is explicit that a dead App Store link
is worse than omitting the app. **This is owner content and was not changed.**

A second thing worth the owner's eye: **`az-courses` and `az-exams` point at the
same Google Play listing** (`com.crazyidea.coursesexams`). One of them is
probably wrong.

## What changed
- **1.9** Added `features/work/`: the ledger screen and its rows. Hairline
  separated rows, not cards; hover reveals a preview on pointer, a thumbnail is
  always visible on touch; store links open externally.
- **1.11** Added `features/recruiter/recruiter_view.dart` and wired it into the
  chrome, so Recruiter Mode replaces the routed content on every route and
  suppresses the trace.
- **1.10** Added `core/analytics/`: `ConsentTier`, `AnalyticsEvent`, the
  beacon record, `AnalyticsClient` and `ConsentController`; plus
  `features/privacy/privacy_screen.dart`, the live readout.
- **1.12** Added the Lighthouse gate to the build job, asserting performance
  ≥ 0.85 and accessibility ≥ 0.9 on `/cv` and `/brief`, with the report
  uploaded as an artifact.
- Added twenty-nine ARB keys in both channels.

## Files touched
- `lib/features/work/presentation/work_screen.dart` — created.
- `lib/features/work/presentation/widgets/ledger_row.dart` — created.
- `lib/features/recruiter/presentation/recruiter_view.dart` — created.
- `lib/core/analytics/{consent,events,analytics_client,consent_controller}.dart`
  — created.
- `lib/features/privacy/presentation/privacy_screen.dart` — created.
- `lib/core/platform/preference_store.dart` — modified — the consent key.
- `lib/core/widgets/loading/station_card.dart` — modified — see below.
- `lib/content/asset_content.dart` — modified — apps and education providers.
- `lib/app/chrome/chrome_scaffold.dart` — modified — Recruiter Mode.
- `lib/app/router.dart` — modified — three new screens.
- `lib/app/l10n/app_{en,ar}.arb` — modified — twenty-nine keys.
- `.github/workflows/ci.yml` — modified — the Lighthouse gate.
- `test/support/{chrome,station}_harness.dart` — modified — warm all content.
- `test/unit/core/analytics/privacy_test.dart` — created — 12 tests.
- `test/widget/privacy/privacy_test.dart` — created — 9 tests.
- `test/widget/work/work_test.dart` — created — 10 tests.
- `docs/worklog/2026-09-05-14-milestone-one-completion.md` — created.

## Decisions made

**The analytics client is a hard no-op, not a queue.** Section 4 is explicit
and the distinction matters: a buffer that flushes on consent has still
collected from somebody who had not agreed. `record` returns whether anything
was sent, so a test asserts silence rather than inferring it.

**Tier 0 runs before the viewer answers; an explicit refusal stops it.**
Section 3's reasoning is that aggregate counters create no per-person record and
write nothing to the device, which is what puts them outside PECR consent. The
`none` tier switches even those off, per section 5's "collect nothing".

**The consent decision itself is stored.** Storing a refusal is what makes it
durable; re-asking every visit would be the dark pattern section 5 forbids. It
is the fourth and last key in a closed enum of preferences, and no identifier
accompanies it.

**The privacy table is generated from the same rules the client enforces, and a
test compares the two.** Section 9 requires the readout to match actual
collection state. Comparing the table against `AnalyticsClient` — rather than
against a second written description of the rules — is what makes that
assertion mean something.

**The station card drops its label below a derived size.** A test caught a 48px
touch thumbnail overflowing by 50px: section 11 puts the app name in display-m,
which cannot fit a thumbnail. The card now computes the smallest height that can
carry a label from the type scale itself and renders the constellation alone
below it. The name is beside it in the row anyway.

**Mokaf says plainly that it has no public listing.** It ships with an empty
store map. An absence the reader has to interpret would be worse than a line
saying so.

**The ledger heading counts what the content holds.** The screen spec's "Twelve
of twenty-five" has neither number in the data — the ledger holds eleven, and
twenty-five appears only inside the positioning prose.

## Tests
- Added: 31 — 12 privacy unit, 9 privacy widget, 10 work and recruiter.
- Modified: the two harnesses, to warm the new content providers.
- Modified: `widget_test.dart` and `chrome_test.dart`, which expected
  placeholders on routes that now have real screens, and the preference-key
  test, which counted three keys before consent added a fourth.
- Full suite: pass, 378 passing plus 36 goldens, 0 failing.
- Coverage delta: 93.20% to 92.37% (3232/3499 lines).

## Verification run
```
fvm dart format --set-exit-if-changed .            pass (0 changed)
fvm flutter analyze --fatal-infos                   pass (no issues found)
fvm flutter test --coverage --exclude-tags golden   pass (378 passing)
fvm flutter test --tags golden                      pass (36 passing)
fvm flutter build web --wasm                        pass (built build/web)
```

## Known issues left open

**Blocking the Milestone 1 merge:**
- **`snunu`'s store link is dead**, as above. Owner decision: correct the id,
  or remove the store entry so the row reads as having no public listing.
- **`az-courses` and `az-exams` share one Google Play URL.**
- **Nothing has been checked on a real phone browser.** `05-TESTING.md`
  requires it before every merge to `main`, and explicitly says a resized
  desktop window does not count.

**Not blocking, but incomplete against the specification:**
- **The Cloudflare Worker does not exist and no beacon is ever sent.** The
  client, the consent model, the tiers and the privacy page are all built and
  tested, but nothing transports anything: `06-ANALYTICS-AND-PRIVACY.md` §3
  requires a Worker with rotating-salt visitor hashing, and §9 requires the
  salt rotation job to be deployed and verified. That needs the owner's
  Cloudflare account. **The site currently collects nothing at all**, which is
  the safe direction to be incomplete in.
- `/console`, `/writing`, `/about` and case studies remain placeholders. Only
  `/console` is a Milestone 1 route, and it is auth-gated Milestone 2 work.
- The Lighthouse gate has never run; it is added but unproven, and it only runs
  on `main`.
- `profile.json` carries no `stats` block, so the hero shows no panels.
- Seventy-five agent-authored Arabic interface strings want an owner read.

## Next
The owner's decisions on the two store links, then a real phone check, then the
Milestone 1 merge to `main`. Merging is what publishes the site, so it is the
owner's to make.

---

## Addendum — consent redesigned to the standard pattern

The owner reviewed the `/privacy` live-readout table and rejected it: no
ordinary site presents a visitor with a field-by-field data dashboard, and the
recognisable pattern is three options — accept, essential only, reject. They
authorised changing the documents to match.

**A concern was raised first and then set aside, which is recorded here so a
later reader knows it was considered.** `06-ANALYTICS-AND-PRIVACY.md` §1 is
marked binding and calls the privacy design the most defensible thing on the
site, tied to the owner's dissertation on the gap between claimed and actual
governance; §5 argued a visitor watching their own data beats any badge. The
owner's judgement is that an unfamiliar interface asking about data reads as
stranger than a familiar one, which is a fair reading and is now what the docs
say.

**The owner's objection also caught a real defect.** There was no consent
prompt anywhere — the choice existed only on a page nobody visits, which is a
compliance gap rather than a design preference. The banner fixes it.

### What changed
- `docs/06-ANALYTICS-AND-PRIVACY.md` §5 rewritten: a standard banner on first
  visit, three equally weighted options, no pre-selection, and `/privacy` as a
  plain-language notice. The detailed readout is reassigned to
  `/how-it-was-built`, where it demonstrates the pipeline to somebody who came
  to read about it.
- `docs/02-SCREEN-SPECS.md` `/privacy` section rewritten to match.
- Added `ConsentBanner` and `ConsentControls`; rewrote `PrivacyScreen` as prose
  plus the same three controls, the current setting, retention and the erasure
  route.
- Removed the twelve field-readout ARB keys; added eleven for the new copy.
- Rewrote the privacy widget tests: twelve now cover the banner's appearance,
  its three options mapping to the right tiers, that it never returns once
  answered, that it does not block the page, and that the notice states
  retention and erasure. The twelve mandatory unit tests from §9 are unchanged.

### Still true
The tier model underneath is untouched: the client is still a hard no-op before
consent, "essential only" is still Tier 0, "reject" still stops even aggregate
counting, and nothing is transported anywhere because no Worker exists.
