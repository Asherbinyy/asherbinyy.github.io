# Changelog

Keep a Changelog format. Milestone releases are tagged `v0.1.0`, `v0.2.0`,
`v1.0.0`.

## [Unreleased]

### Fixed

- Deployed the Milestone 4 Worker from the repository root. The `/v1/cover`
  fake-image check returns the expected 502; Pages is deployed separately.

## [0.3.0] — 2026-09-07

Milestone 4, "Provenance". Everything the site says is now sourced, and there
is a person behind it. The visual language is unchanged apart from the palette;
the Egyptian redesign is milestone 5.

### Added

- **Off duty** on `/about` — six interests in the owner's own words, with the specifics he named. Legible without hovering and deliberately outside the tab order, because a tile has nowhere to go.
- **The portrait**, closing an item open since milestone 1.
- **Coursework beside two marks** — a Power BI dashboard at 94 and a research poster at 80 — as thumbnails that open full size. A mark is a number a reader takes on trust; the artefact is what makes it evidence.
- **Guardy**, and Tiara Beauty marked freelance. Germany is the owner's genuine sixth country.
- **Real article covers on `/writing`**, relayed through the Worker's new `/v1/cover` so that opening the page issues no request to Medium carrying the viewer's IP.
- **The CV as a PDF.** The hero's second action now reads *Download the CV*.
- **A screenshot pipeline** for the work ledger — drop a file in `assets/media/apps/` and point one line of `apps.json` at it.
- **`docs/14-PROVENANCE.md`**, mapping every claim to its source, with a test that fails if a published figure has no row.
- **`docs/AR-REVIEW.md`**, every Arabic string beside its English.

### Changed

- **The palette.** Kemet and Deshret replace Nocturne and Daybreak. The dark base moved from `#05070A` to `#121826` — 4.4× the relative luminance — because the owner found it too dark. Both were solved against the contrast suite rather than chosen, and `faience` joins as the interaction pigment.
- **Arabic is a translation, not a direction flip.** App roles, institutions, awards, academic status, module names and highlights could not hold Arabic at all; they are `LocalizedText` now. 44 strings across five documents.
- **The name is Sherbini** everywhere a person reads it. `/cv` and every `<title>`, Open Graph tag and JSON-LD record keep the legal name, because that is what an ATS parses and what a recruiter types into a search box.
- **The journey starts in 2015**, at Mansoura University, and ends at Salford — both already in the content, so the map gained an origin and a present with no new claim.
- **The chronology scrubber** has a continuous rail, names the stop it has selected, and is flanked by step controls.
- **The transmission panel** no longer reads as a plain white card on papyrus.
- **`/about` publishes the four strongest module marks.** `education.json` keeps all seven and `/cv` still prints them.

### Fixed

- **Text can be selected and copied.** Flutter paints to canvas, so it could not be — including the owner's email address.
- **The static pages had drifted from the app's palette**, serving milestone-1 amber and `#05070A` browser chrome while the app was Kemet. Their tests were hand-copied hex literals, so they agreed with the stale output; they derive from the tokens now.
- **`StationCard` overflowed** whenever a wrapping name met a card between its one-line and two-line heights. The threshold reserved one line while the label drew two — latent since milestone 1.
- **The README's privacy claim** said nothing is stored on the visitor's device. Theme, language and Recruiter Mode have persisted since milestone 1.
- **"Six countries" overstated the CV**, which named five plus a UK residency.
- Evri is removed, and the footer no longer introduces the owner by a latitude.

### Known at release

`/v1/cover` was written and tested but **not yet deployed at milestone completion**;
the deployment is recorded under Unreleased. Wrangler runs from the repository
root, where `wrangler.toml` points to `worker/src/index.js`. The Arabic
was written by an agent under an explicit waiver and has not had a native read.
`docs/02-SCREEN-SPECS.md` and `docs/07-CONTENT-SCHEMA.md` still describe the
ground station. Full list in `docs/11-OPEN-ISSUES.md`.

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

[0.3.0]: https://github.com/Asherbinyy/asherbinyy.github.io/releases/tag/v0.3.0
