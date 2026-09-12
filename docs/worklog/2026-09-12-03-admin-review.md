# 2026-09-12-03 — Admin merge review

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** 034d50e; reviewed Claude admin branch at fd5139a

## Goal
Independently review Claude's admin work before integration and prepare actionable fixes. The subsequently rejected public experiment is removed; this record retains the admin review evidence.

## What changed
- Read Claude's three latest worklogs, integration/appearance proposals and actual branch changes. Ran all 229 Worker tests independently; all pass.
- Delegated a bounded, read-only backend review to a Codex sub-agent, as the owner explicitly requested review/delegation. Did not impersonate Claude or edit his checkout.
- Reproduced nine admin defects using local synthetic fixtures: concurrent revision loss, ineffective password throttle, async upload into the wrong document, silent dirty-draft rebasing, stale rollback/withdrawal, unvalidated preview draft, snapshot reference mismatch, malformed M4A exception and incorrect idle expiry behavior.
- Wrote exact triggers, source locations, expected fixes and regression acceptance in `24-ADMIN-MERGE-REVIEW.md`, including a ready-to-paste Claude prompt. Existing preview tests use a stand-in; the real public adapter remains an integration gap.

## Files touched
- `docs/24-ADMIN-MERGE-REVIEW.md` — created — nine reproduced findings, integration corrections and Claude follow-up prompt.
- `docs/11-OPEN-ISSUES.md` — modified — replace outdated admin absence claims with current under-review/merge-blocked states and record the renewed Flutter authoring question.
- `docs/19-FLUTTER-ENHANCEMENT-PLAN.md` — modified — link the review and public integration status.
- `docs/worklog/2026-09-12-03-admin-review.md` — created — this record.

## Decisions made
- A passing existing test suite is insufficient to recommend merging reproduced data-loss/auth defects. Claude fixes the admin branch; Codex reviews the corrected SHA and integrates with public work afterward. No merge to the published `main` is implied.
- No direct communication tool to the user's separate Claude session is available. Supplied the requested prompt as a repository artifact rather than claiming to have sent it.
- Current owner decision: retain Flutter as the only interactive UI. Shared content, release snapshots and preview protocol remain useful; public integration is still open.
- Review worklog sequence uses 03 because Claude already wrote September 12 records 01 and 02 in the other checkout.

## Tests
- Added: no repository tests in this read-only review; exact required regressions are specified for Claude. Additional local fixture/browser reproductions live in temporary review scratch.
- Modified: none.
- Full suite: pass, 229 Worker passing, 0 failing on fd5139a. Public checkpoint already passed 676 Flutter tests; this review did not repeat unchanged Flutter tests.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass in preceding public checkpoint; no Dart changes since
fvm flutter analyze                        pass in preceding public checkpoint; no Dart changes since
fvm flutter test                           pass, 676 in preceding public checkpoint; not repeated
fvm flutter build web --wasm               pass in preceding public checkpoint; not repeated
```

Independent Worker suite: `npm exec --yes --package=node@22.23.2 -- npm --prefix worker test`, 229 passing. Additional backend fixture checks were performed by the review sub-agent; root reproduced upload/navigation and preview debounce defects in Chrome, and dirty-draft revision refresh using the actual client function with synthetic state. Existing six admin browser suites were inspected but not all independently rerun; do not report Claude's 116 checks as this review's result.

The browser harness was copied into `/private/tmp/nocturne-admin-review` to keep Claude's checkout untouched and avoid replacing his committed screenshots. It used a separate localhost port and fictional fixture documents only. No production requests or credentials were used. The first combined UI reproduction injected an invalid field during the upload test, so preview timing was repeated in a clean browser session to isolate that second defect.

## Known issues left open
Historical status at fd5139a; see `25-ADMIN-REREVIEW.md` for afc8969 corrections and remaining blockers.

- AR-1 through AR-9 require Claude's fixes and a re-review before merge. A5, actual public preview, field consumers and coordinated publishing remain incomplete.
- The remaining public enhancements are now planned in the Flutter-only queue. No production deployment, Search Console submission or physical-device verification occurred.

## Next
Claude fixes the merge review findings; the subsequent re-review and Flutter-only reset are recorded in 2026-09-12-04-flutter-reset-admin-rereview.md.
