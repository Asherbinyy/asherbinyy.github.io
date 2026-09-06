# Changelog

Keep a Changelog format. Milestone releases are tagged `v0.1.0`, `v0.2.0`,
`v1.0.0`.

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
