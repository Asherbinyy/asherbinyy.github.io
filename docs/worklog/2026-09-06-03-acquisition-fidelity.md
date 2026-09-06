# 2026-09-06-03 — Acquisition sequence fidelity

**Agent:** Codex GPT-5
**Milestone:** 1
**Started from:** c05c3b4

## Goal
Resolve the acquisition-sequence gaps in the Milestone 1 handoff: once-per-tab
behavior, distinct third and fourth beats, the name reveal, and the documented
reduced-motion fade.

## What changed
- Seeded the acquisition provider from a browser `sessionStorage` marker and
  write that marker when the sequence completes or is skipped, so a hard reload
  in the same tab does not replay it.
- Split beat three from beat four. Beat three resolves the trace/content and
  reveals the laid-out name from its leading edge; beat four fades and slides
  the header, navigation, rail, consent banner and footer from their own edges.
- Kept every component at its settled layout size during the sequence, avoiding
  a geometry change when the animation completes.
- Replaced the previous instant reduced-motion completion with the specified
  200ms fade directly to the settled frame, without scan or staged movement.

## Files touched
- `lib/features/station/domain/acquisition_session.dart` — created — conditional
  browser-session boundary.
- `lib/features/station/domain/acquisition_session_stub.dart` — created — VM
  fallback with no browser storage.
- `lib/features/station/domain/acquisition_session_web.dart` — created —
  tab-scoped played marker.
- `lib/features/station/domain/acquisition_controller.dart` — modified — seed
  and persist the played state.
- `lib/features/station/presentation/widgets/acquisition_sequence.dart` —
  modified — separate content/chrome beats and reduced-motion fade.
- `lib/app/chrome/chrome_scaffold.dart` — modified — reveal content and chrome
  through independent animations without reflow.
- `lib/app/router.dart` — modified — compose station content with both reveal
  channels.
- `lib/features/station/presentation/station_screen.dart` — modified — pass the
  first-load name reveal to resolved content.
- `lib/features/station/presentation/widgets/hero_content.dart` — modified —
  reveal the name during beat three and retain the original settled Text.
- `lib/main.dart` — modified — document the two non-identifying tab-scoped
  functional values.
- `test/widget/station/station_test.dart` — modified — assert beat order and the
  reduced-motion duration.
- `docs/worklog/2026-09-06-03-acquisition-fidelity.md` — created — this record.

## Decisions made
The once-per-session requirement is implemented as once per browser tab, using
`sessionStorage`. This matches the platform meaning of a session, dies when the
tab closes, and stores only the value `1`; it is functional animation state,
not an analytics identifier or durable preference.

Chrome uses `SlideTransition`, which transforms already-laid-out children. The
content column similarly retains its final geometry while opacity changes. The
name uses the beat-three animation as a leading-edge clip and returns the
unchanged Text widget at completion, preserving the settled goldens exactly.

## Tests
- Added: 1 acquisition beat-order test.
- Modified: the reduced-motion acquisition test now verifies it remains active
  halfway through the documented 200ms fade and completes afterward.
- Full suite: pass, 391 non-golden and 36 golden tests passing, 0 failing.
- Coverage delta: 92.64% to 92.75% (3350/3612 lines).

## Verification run
```
fvm dart format --set-exit-if-changed .            pass (195 files, 0 changed)
fvm flutter analyze --fatal-infos                   pass (no issues found)
fvm flutter test --coverage --exclude-tags golden   pass (391 passing)
fvm flutter test --tags golden                      pass (36 passing)
fvm flutter build web --wasm                        pass (built build/web)
```

## Known issues left open
The VM test target cannot emulate persistence through a browser hard reload;
the conditional web implementation is compiled by the successful WASM build.
The once-per-tab behavior still needs observation in the real browser review.

## Next
Complete the propagation map's missing geographic context and direct pan/zoom
interaction, then measure its frame cost in the real browser profile.
