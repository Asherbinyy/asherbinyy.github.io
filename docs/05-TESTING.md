# Testing — NOCTURNE

> Current verification, 2026-09-25: analytics is cookieless and default-on; the public consent/privacy UI is removed. Do not recreate it to satisfy historical examples below. Keep tests of actual behavior and privacy boundaries. Visual acceptance also requires real-browser captures and interaction checks with real fonts. Phone viewport emulation is not physical-device testing. The full release matrix is [F9](19-FLUTTER-ENHANCEMENT-PLAN.md#f9--device-and-release-evidence).

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
| Privacy & analytics | **100%** | Non-negotiable |
| Overall | ≥ 80% | Enforced in CI |

---

## Test types

**Unit.** Models, JSON parsing, date formatting, `projection.dart` lat/lon conversion, trace amplitude maths, RSS parsing.

**Widget.** Default analytics startup, theme and language switching, Recruiter Mode toggle, map node selection, error and empty states.

**Golden (alchemist).** Both themes × three breakpoints × both text directions for: hero, instrument panel, work card, transmission panel and Recruiter Mode. Goldens catch the exact class of regression that matters most here — visual drift.

**Integration.** Cold load → acquisition sequence → interactive. Route navigation and deep links. Configured build → route and interaction beacons; preview and absent-endpoint builds → none.

**Manual, before every merge to `main`.** Automated tests run in a synthetic environment and will not catch these:
- Load the deployed site on a real iPhone and a real Android phone, in Safari and Chrome. Not a resized desktop window — the address bar collapsing on scroll and safe-area insets behave differently.
- Open a deep link directly, e.g. `/work`, to confirm the `404.html` fallback resolves it.
- Confirm no horizontal scroll at 320px width.

---

## Privacy tests — mandatory

These are specified in `06-ANALYTICS-AND-PRIVACY.md` §9 and are restated here because they must never be deleted:

1. A configured public client records immediately and shows no consent panel.
2. No analytics cookie, preference or browser identifier is created.
3. The Worker never writes or logs a raw IP address or user-agent string.
4. Preview, `/console` and absent-endpoint builds send nothing.
5. Destinations exclude contact values, credentials, private queries and fragments.
6. Dashboard empty, disabled and failure states remain distinguishable.

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
