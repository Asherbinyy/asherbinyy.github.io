# Changelog

Keep a Changelog format. Milestone releases are tagged `v0.1.0`, `v0.2.0`,
`v1.0.0`.

## [Unreleased]

### Changed

- **Direction.** The ground-station concept is retired in favour of an Egyptian
  one, drawn from where the owner is from rather than from his first degree.
  Milestones 4 (Provenance), 5 (Kemet) and 6 (The Ascent) in
  `docs/09-ROADMAP.md`. No feature code has changed yet — this release carries
  documentation only.
- **The palette rule.** Amber-only is replaced by four pigments each locked to
  one job: gold for the person and every action, faience for interaction
  feedback, carnelian for errors, graded limestone and ink for everything else.
  A fifth hue remains forbidden. Both the Kemet and Deshret palettes are solved
  against the existing contrast suite rather than chosen by eye.

### Added

- `docs/14-PROVENANCE.md` — every claim the site makes about the owner, mapped
  to the source it came from. A number without a row does not ship.
- `docs/12-MOTIF-LIBRARY.md` — the closed motif inventory and the rules that
  keep the theme from becoming costume.
- `docs/13-GAME-DESIGN.md` — The Ascent.

### Fixed

- The README's privacy claim said nothing is stored on the visitor's device.
  Theme, language and Recruiter Mode have persisted since milestone 1; the
  sentence now says what the code actually does.

## [0.2.0] — 2026-09-06

Milestone 2, "Depth". Published to GitHub Pages and tagged `v0.2.0`.
The matching analytics Worker was deployed separately on 2026-09-06.

### Added

- **`/writing`** — the Medium feed, relayed through the analytics Worker
  because Medium sends no CORS header, cached for an hour, and hidden entirely
  rather than apologising when it cannot be read.
- **`/about`** — identity, an education table with modules ranked by mark, and
  the three most recent articles.
- **`/work/:slug`** — case studies with a device frame pinned beside the
  narrative, and City Loom's prototype behind a click-to-load poster. No study
  content ships yet; the page says so.
- **Tier 1 analytics** — session events behind an explicit opt-in, with a
  tab-scoped identifier that is never stored, and scroll depth and dwell
  reported once on leaving rather than continuously.
- **`/console`** — the auth-gated dashboard, code-split so a public visitor
  downloads only the gate.
- **`/how-it-was-built`** — every measurement generated from the build's own
  artifacts, and a collection readout derived from the code that enforces it.
- **The daily digest workflow**, importable into n8n, awaiting the owner's
  accounts.
- Daybreak brought to WCAG AA, along with two Nocturne values that were below
  it on the live site.

### Fixed

- Absent optional beacon fields are omitted so Tier 0 remains compatible with
  the independently deployed Worker (PR #3).
- Deployed the matching Worker to enable the writing relay, Tier 1 validation,
  console totals and corrected digest payload.
- The digest payload double-nested its counters after `/console` needed totals.
- The engagement reporter threw during teardown, reading a disposed container.
- The footer overflowed by 148px on a phone once it carried a second link.

## [0.1.0] — 2026-09-06

Milestone 1, "Ground station online". First publish. Dark theme, English and
Arabic, the core experience, and Tier 0 analytics collecting.

### Added

- **Foundation.** Flutter 3.47.2 pinned via FVM, `material_ui` throughout, the
  full design-token set as a `ThemeExtension`, both themes, the platform
  service, reduced-motion plumbing, and every route from the brief.
- **Localisation.** English and Arabic ARB channels with full RTL, built before
  any UI so no padding needed retrofitting.
- **Content layer.** Typed models for profile, career, applications and
  education, with a tested fallback path when JSON is malformed.
- **Static routes.** `tool/generate_static.dart` emits `/cv` and `/brief` as
  hand-written HTML with JSON-LD, plus `robots.txt` and `sitemap.xml` — the
  indexable surface Flutter Web cannot provide.
- **Loading primitives.** One shared sweep controller per page, skeletons whose
  geometry matches real content, the carrier loader, the three-stage image
  resolve, and deterministic procedural station cards.
- **Global chrome.** Header, rail, footer, and persisting theme, language and
  Recruiter Mode toggles across four breakpoints.
- **Acquisition sequence.** Runs once per session, skippable by any input, and
  resolves to a 200ms fade under reduced motion.
- **The mark and favicon**, pulled from a frame of the trace's own curve.
- **Telemetry trace.** The signature element — a continuous waveform whose
  amplitude tracks scroll velocity, with bursts anchored to the measured
  positions of rendered career entries.
- **Propagation map.** Six ground stations, sequenced arcs, a touch scrubber and
  keyboard traversal, against a unit-tested projection.
- **Work ledger.** Eleven applications as hairline-separated rows, with every
  store link verified by hand.
- **Consent and Tier 0 analytics.** A standard three-option banner, a
  plain-language `/privacy` notice, and a Cloudflare Worker that resolves
  country server-side, discards the IP within the invocation, and rotates its
  visitor-hash salt daily.
- **Recruiter Mode**, rendering the same content as `/brief` with no motion.
- **CI and deploy.** `verify` on every push to the phase branch; `build` and
  `deploy` only from `main`, producing `.nojekyll` and `404.html`, with a
  Lighthouse gate on `/cv` and `/brief`.
- `docs/11-OPEN-ISSUES.md`, the standing register of what is still incomplete.

### Known at release

Published without the real-phone check that `docs/05-TESTING.md` requires, on
the owner's explicit instruction. The Lighthouse gate, live deep links, the
analytics beacon end to end, and the favicon in browser chrome had all never
run outside CI, because `main` is what publishes them. `docs/11-OPEN-ISSUES.md`
§4 and §5 carry the full list and what to check first.

[0.1.0]: https://github.com/Asherbinyy/asherbinyy.github.io/releases/tag/v0.1.0

[0.2.0]: https://github.com/Asherbinyy/asherbinyy.github.io/releases/tag/v0.2.0
