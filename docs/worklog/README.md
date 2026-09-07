# Worklog

One file per agent session. Format in `AGENTS.md` §5.

**Nothing here is ever deleted or rewritten.** A worklog is what it was true to
say at the time, and the value of the series is that it shows how decisions were
actually reached — including the ones later reversed. `11-OPEN-ISSUES.md` is the
file that says what is *still* true; if the two disagree, that one wins.

The owner asked on 2026-09-07 whether to wipe the series and start fresh at the
change of direction. Kept, for three reasons: `AGENTS.md` §1 requires every new
agent to read the three most recent, so wiping breaks onboarding; several
worklogs are the only record of why something was *not* done, which is exactly
what a new agent would otherwise redo; and the concept changed, not the
engineering, so most of it still applies.

This index is the fast path instead.

---

## Milestone 4 — Provenance · 2026-09-07 onward

| File | What it settled |
|---|---|
| `2026-09-07-01-milestone-four-planning.md` | Direction change. Docs rewritten for the Egyptian concept, palettes solved, milestones 4–6 specified. |

## Milestone 3 — Edge · `v0.2.x`

| File | What it settled |
|---|---|
| `2026-09-06-10-milestone-three.md` | Campaign links, performance pass, accessibility audit, easter egg. The a11y audit found the whole nav announcing nothing to a screen reader. Consent and `/privacy` removed along with the collection they existed for. |

## Milestone 2 — Depth · `v0.2.0`

| File | What it settled |
|---|---|
| `2026-09-06-09-milestone-two-worker-release.md` | Worker deployed; the writing relay went live. |
| `2026-09-06-08-milestone-two.md` | Case studies, Tier 1, `/console`, digest, `/how-it-was-built`. |
| `2026-09-06-07-daybreak-contrast.md` | Seven palette values moved to reach WCAG AA. **The method used again for the Kemet and Deshret palettes: lightness only, hue and saturation untouched.** |

## Milestone 1 — Ground station · `v0.1.0`

| File | What it settled |
|---|---|
| `2026-09-06-06-milestone-one-release.md` | First publish. |
| `2026-09-06-05-measured-trace-anchors-handoff.md` | Trace bursts anchored to measured positions of rendered entries. Reused by the wall in 5.3. |
| `2026-09-06-04-propagation-map-fidelity.md` | Map projection and arc sequencing. Reused by the atlas in 5.4. |
| `2026-09-06-03-acquisition-fidelity.md` | Once-per-session opening sequence. |
| `2026-09-06-02-tier-zero-worker.md` | Cloudflare Worker, rotating-salt visitor hashing. |
| `2026-09-06-01-store-link-corrections.md` | Store links verified by hand; two found dead. |
| `2026-09-05-14-milestone-one-completion.md` | Milestone 1 closed out. |
| `2026-09-05-13-propagation-map.md` | Custom map instead of an SDK — ~30KB against ~900KB. |
| `2026-09-05-12-telemetry-trace.md` | The trace. Velocity engine reused by the wall. |
| `2026-09-05-11-mark-and-favicon.md` | Mark pulled from a frame of the trace's own curve. **Superseded in 5.5 by the ankh.** |
| `2026-09-05-10-hero-and-acquisition.md` | Hero and first-load sequence. |
| `2026-09-05-09-global-chrome.md` | Header, rail, footer, three persisting toggles. |
| `2026-09-05-08-loading-primitives.md` | One shared sweep per page, skeletons matching real geometry, deterministic station cards. **The pattern 5.1 follows.** |
| `2026-09-05-07-static-routes.md` | `/cv` and `/brief` as hand-written HTML — the indexable surface. |
| `2026-09-05-06-content-layer.md` | Typed models, tested fallback path. |
| `2026-09-05-05-localisation.md` | ARB channels and RTL, before any UI. |
| `2026-09-05-04-foundation-verification.md` | Foundation verified. |
| `2026-09-05-03-ci-and-remote-setup.md` | CI pulled forward deliberately. |
| `2026-09-05-02-foundation.md` | Skeleton, tokens, theming, routing. |
| `2026-09-05-01-download-fonts.md` | Fonts subset and bundled locally. |

---

## What survives the change of concept

Milestone 5 replaces the skin, not the structure. Still current, and not to be
rebuilt: the content layer and its fallback, localisation and RTL, the platform
service, reduced-motion plumbing, the loading primitives' architecture, the map
projection and coastline data, the trace's velocity engine and anchor registry,
the deterministic card seeding, the static route generator, Recruiter Mode, the
Worker, and CI.

What is replaced: the palette (4.10), every painter's *paint* (5.1–5.8), the
mark (5.5), and the concept language throughout the docs.
