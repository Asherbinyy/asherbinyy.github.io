# 2026-09-06-08 — Milestone 2, all seven tasks

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 2
**Started from:** 753d38f

## Goal
Complete Milestone 2 at the owner's instruction: 2.1 case studies, 2.3 writing,
2.4 Tier 1 analytics, 2.5 `/console`, 2.6 the digest and 2.7
`/how-it-was-built`. 2.2 was finished in the previous session.

## What changed, by task

**2.3 — writing, with `/about` folded in.** Medium sends no
`access-control-allow-origin`, so the browser cannot read the feed. Added a
first-party `/v1/writing` relay on the existing Worker: origin-gated like the
beacon, cached in KV for an hour, returning the feed verbatim. `/about` renders
the identity the content actually has, reserves the portrait's 4:5 geometry,
and withholds the MSc overall mark while the award is unconfirmed.

**2.1 — case studies.** Four sections in the spec's order, device frame pinned
beside the narrative on wide viewports and stacked above it when narrow, and
City Loom's prototype behind a poster and an explicit press. **No study files
are shipped** — see Decisions.

**2.4 — Tier 1.** The tiers, the consent model and the hard no-op client
existed from Milestone 1; this wires the events §4 lists, adds the session
identifier and the two measurements, and teaches the Worker to validate and
aggregate them.

**2.5 — `/console`.** Stat tiles, a monochrome daily ramp with only the busiest
day in amber, and the campaign table. Code-split behind the token gate.

**2.7 — `/how-it-was-built`.** Every measurement generated; the collection
readout derived from the client that enforces it.

**2.6 — the digest.** The importable n8n workflow, its summary logic and its
message, all version controlled. The two accounts remain the owner's.

## Files touched
- `worker/src/index.js` — modified — writing relay, Tier 1 validation and totals, digest payload fix.
- `wrangler.toml` — modified — `WRITING_FEED_URL`.
- `lib/features/writing/**` — created — article record, RSS parser, repository, providers, screen, list and row.
- `lib/features/about/**` — created — screen, education table, portrait frame.
- `lib/features/work/presentation/case_study_screen.dart` — created — the four sections and the pinned frame.
- `lib/features/work/presentation/widgets/{device_frame,prototype_embed,embed_view,embed_view_stub,embed_view_web}.dart` — created.
- `lib/features/work/data/study_providers.dart` — created.
- `lib/content/models/study.dart` — modified — optional `prototype`.
- `lib/app/chrome/chrome_scaffold.dart` — modified — `ChromeScrollScope`.
- `lib/core/analytics/{events,analytics_client,beacon_sender,browser_analytics_context*}.dart` — modified — Tier 1 fields and the session identifier.
- `lib/core/analytics/{interactions,engagement_reporter}.dart` — created.
- `lib/features/station/presentation/widgets/cv_button.dart` — created.
- `lib/features/console/**` — created — summary, repository, providers, gate, dashboard, sparkline.
- `lib/features/colophon/**` — created — build facts, collection rules, screen.
- `tool/generate_build_facts.dart` — created; `assets/build_facts.json` — generated.
- `automation/{digest-workflow.json,README.md}` — created.
- `lib/app/{router,app_route,route_title}.dart`, `lib/app/chrome/app_footer.dart` — modified — five new routes and the colophon link.
- `lib/app/theme/{tokens,token_values}.dart` — modified — `consoleTileWidth`.
- `.github/workflows/ci.yml` — modified — regenerates build facts before publishing.
- `docs/{06,07,11}` — modified — Tier 1 shapes, the `prototype` field, the register.
- Tests: `test/unit/features/{writing,console,colophon}/`, `test/widget/{writing,about,console,colophon}/`, `test/widget/work/case_study_test.dart`, `test/unit/core/analytics/tier_one_test.dart`, plus worker tests.
- `test/golden/console_gate_test.dart` — renamed from `locale_placeholder_test.dart`.

## Decisions made

**No placeholder case-study prose was shipped, against the approved plan.** The
owner chose "machinery plus clearly-marked placeholder entries". The machinery
is complete and proven against fixtures, but nothing was written into
`assets/content/studies/`: placeholder prose about real client work would be a
claim the owner never made, on a page a recruiter reads as fact, and
`AGENTS.md` §3 forbids exactly that. Production says "not written yet". This is
recorded as open issue 2.5 so the deviation is visible rather than assumed;
writing the three studies needs no code change.

**The relay returns the feed verbatim.** The client already carries an XML
parser — `03-ARCHITECTURE.md` §4 lists `xml` for exactly this — and a Worker
that reshaped the feed would be a second place for that shape to drift. It
answers 502 rather than an empty 200 on failure, because the client hides the
section either way but only one of the two is worth retrying.

**The session identifier is minted inside `AnalyticsClient`.** The only path to
one runs through a tier check, so a viewer on aggregate-only cannot cause an
identifier to exist. It is used to deduplicate within a request and discarded;
no stored counter carries it as a dimension, and the Worker rejects a
`route_view` that carries one at all.

**Scroll depth and dwell are reported once, on leaving.** A stream of offsets
would describe reading motion frame by frame, which is nearer the session
replay §2 bans than a depth metric. A quartile answers "did they reach the
work" and nothing else. Dwell is floored at two seconds and capped at an hour,
so neither a glance nor a forgotten tab becomes a distinguishing record.

**The console token is memory-only.** It is a bearer credential for the
analytics store, and a site whose argument is about not writing to visitors'
devices should not make an exception for its own secret.

**The colophon measures rather than describes.** `AnalyticsClient.permits` is
now public so the collection table asks the enforcing code; a second written
description would eventually disagree with it. Build figures are generated by
`tool/generate_build_facts.dart` and regenerated in CI.

**A token was added:** `consoleTileWidth`, 120px. Not from
`01-DESIGN-SYSTEM.md`, which predates the console; §6 bans the raw value, so it
is named and documented in `tokens.dart`.

## Defects found and fixed along the way
- **The digest payload was double-nested.** Changing `aggregateSnapshot` to
  return `{counters, totals}` for the console left the digest wrapping it
  again, producing `counters.counters`. Fixed and covered by a test.
- **The engagement reporter threw on teardown.** The provider container
  disposes before its widgets, and a dispose-time read of a disposed container
  throws. Analytics must never surface, least of all during teardown.
- **The colophon's footer link overflowed a phone footer by 148px.** The
  decorative coordinate readout now yields on narrow viewports — a flourish
  should give way before a navigational link — and the link moves to `/about`
  below the medium breakpoint, where the label does not fit at all.

## Tests
- Added: 51 Dart (writing parser and repository, article and about widgets,
  case study and prototype, Tier 1 client, console summary and dashboard,
  collection rules and build facts, colophon widgets) and 9 Worker.
- Modified: `widget_test.dart`'s route map, the beacon fixtures for the two new
  record fields, `station_harness.dart` (overrides, path parameters, study
  warming), and 24 goldens for the footer link.
- Renamed: `locale_placeholder_test.dart` to `console_gate_test.dart` — every
  framed route now has a screen, so the placeholder it photographed no longer
  exists; it covers the console gate at the same theme × direction spread.
- Full suite: pass, 537 passing / 0 failing. Worker: 26 passing / 0 failing.
- Coverage delta: 93.44% to 90.88% (4496/4947). The floor CI enforces is 80%.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (244 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test                           pass (537 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```
Also `node --test worker/test/*.test.js`: pass, 26 tests.

## Known issues left open
`docs/11-OPEN-ISSUES.md` carries the register. New this session:

- **2.5** — no placeholder case-study prose shipped, as above.
- **2.6** — `07-CONTENT-SCHEMA.md` names Tripster as the third study where
  `02-SCREEN-SPECS.md` and `09-ROADMAP.md` both say City Loom.
- **2.7** — `studies/{slug}.json` gained an optional `prototype` field.
- **3.10** — the console's code-split lands in the JS output but not the WasmGC
  one, which emits a single `main.dart.wasm`. Roadmap 2.5's requirement is met
  on one of the two outputs; this is an SDK limitation, not application code.
- **3.11** — the console token is memory-only, by choice.

Still open from before: the real-phone check, the twelfth application, the
Arabic review, the CV PDF, the portrait, the case-study prose and screenshots,
and the n8n and Resend accounts.

**Nothing in Milestone 2 has been seen in a browser.** Goldens render without
fonts, and the embed, the deferred load and the relay all behave differently
against a real network.

## Next
Merge `phase/2-depth` to `main` — which needs the real-phone check that
Milestone 1 shipped without, now that there is a live site to check against.
Then Milestone 3.
