# Testing — NOCTURNE

The site's credibility partly rests on being well-built. `/how-it-was-built` will show coverage and CI status publicly, so the tests need to be real.

---

## Targets

| Layer | Target | Notes |
|---|---|---|
| Content models & parsing | 95% | Pure logic, cheap to cover, high blast radius |
| Repositories | 90% | Including malformed-JSON fallback paths |
| Controllers / providers | 85% | |
| Painters (trace, map, projection) | 80% | Geometry is unit-testable; rendering is golden-tested |
| Widgets | Critical paths | Not every widget |
| Privacy & consent | **100%** | Non-negotiable |
| Overall | ≥ 80% | Enforced in CI |

---

## Test types

**Unit.** Models, JSON parsing, date formatting, `projection.dart` lat/lon conversion, trace amplitude maths, RSS parsing.

**Widget.** Consent panel state transitions, theme and language switching, Recruiter Mode toggle, map node selection, error and empty states.

**Golden (alchemist).** Both themes × three breakpoints × both text directions for: hero, instrument panel, work card, transmission panel, consent panel, Recruiter Mode. Goldens catch the exact class of regression that matters most here — visual drift.

**Integration.** Cold load → acquisition sequence → interactive. Route navigation and deep links. Consent grant → withdraw → verify collection stopped.

**Manual, before every merge to `main`.** Automated tests run in a synthetic environment and will not catch these:
- Load the deployed site on a real iPhone and a real Android phone, in Safari and Chrome. Not a resized desktop window — the address bar collapsing on scroll and safe-area insets behave differently.
- Open a deep link directly, e.g. `/work`, to confirm the `404.html` fallback resolves it.
- Confirm no horizontal scroll at 320px width.

---

## Privacy tests — mandatory

These are specified in `06-ANALYTICS-AND-PRIVACY.md` §9 and are restated here because they must never be deleted:

1. Zero network calls occur before consent resolves.
2. `analytics_client` no-ops entirely in the ungranted state — it does not buffer.
3. The Tier 0 Worker never writes or logs an IP address.
4. Consent withdrawal halts collection within the same session.
5. No session identifier is ever written to `localStorage`.
6. The consent panel's live readout matches actual collection state.

A failing privacy test blocks merge unconditionally.

---

## Accessibility tests

- `meetsGuideline(textContrastGuideline)` in both themes
- `meetsGuideline(androidTapTargetGuideline)` — 48px minimum on touch breakpoints
- Every interactive element exposes a semantic label
- Full keyboard traversal on `/`, `/work`, `/privacy`
- Reduced-motion path renders and settles for every animated widget

---

## Conventions

- `mocktail` for doubles. No hand-rolled fakes where a mock will do.
- Arrange–Act–Assert, with the three phases visually separated.
- Test names describe behaviour: `returns fallback content when profile.json is malformed`. Not `test1`.
- One behaviour per test.
- No `skip:` without a worklog entry explaining it.
- Fixtures in `test/fixtures/`, mirroring `assets/content/` structure.

```
test/
  unit/
  widget/
  golden/
  integration/
  fixtures/
```

---

## Commands

```bash
fvm flutter test
fvm flutter test --coverage
fvm flutter test --update-goldens        # only when a change is intentional
fvm flutter test test/integration
```

Never run `--update-goldens` to make a failing test pass. If a golden fails, look at the diff and decide whether the change was intended. Blind golden updates defeat the entire purpose of having them.
