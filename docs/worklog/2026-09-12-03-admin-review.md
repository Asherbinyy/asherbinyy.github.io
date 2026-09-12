# 2026-09-12-03 — Admin merge review and entrance study

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** 034d50e; reviewed Claude admin branch at fd5139a

## Goal
Answer the owner's Flutter/Astro maintenance concern and independently review Claude's admin work before integration. Prepare actionable fixes for Claude while advancing renderer-independent Egyptian art direction.

## What changed
- Explained that Astro shares the content documents, not Flutter UI implementation; a Flutter layout edit does not update an Astro page. Asked whether continued Flutter UI authoring is required. Existing Astro work remains isolated and committed; no further page migration or production change was made during this review.
- Read Claude's three latest worklogs, integration/appearance proposals and actual branch changes. Ran all 229 Worker tests independently; all pass.
- Delegated a bounded, read-only backend review to a Codex sub-agent, as the owner explicitly requested review/delegation. Did not impersonate Claude or edit his checkout.
- Reproduced nine admin defects using local synthetic fixtures: concurrent revision loss, ineffective password throttle, async upload into the wrong document, silent dirty-draft rebasing, stale rollback/withdrawal, unvalidated preview draft, snapshot reference mismatch, malformed M4A exception and incorrect idle expiry behavior.
- Wrote exact triggers, source locations, expected fixes and regression acceptance in `24-ADMIN-MERGE-REVIEW.md`, including a ready-to-paste Claude prompt. Existing preview tests use a stand-in; the real public adapter remains an integration gap.
- Generated and visually inspected a renderer-independent Egyptian limestone entrance study using the imagegen skill and built-in tool. Saved the image and full prompt in the repository. It is original concept art, not a historical reconstruction or shipped interactive scene.

## Files touched
- `docs/24-ADMIN-MERGE-REVIEW.md` — created — nine reproduced findings, integration corrections and Claude follow-up prompt.
- `docs/11-OPEN-ISSUES.md` — modified — replace outdated admin absence claims with current under-review/merge-blocked states and record the renewed Flutter authoring question.
- `docs/19-REINNOVATION-ROADMAP.md` — modified — link the review, architecture clarification and R2 material study.
- `docs/audits/2026-09-12/r2-entrance/README.md` — created — concept provenance, full generation prompt and visual limitations.
- `docs/audits/2026-09-12/r2-entrance/threshold-study-v1.png` — created — original entrance material/composition study.
- `docs/worklog/2026-09-12-03-admin-review.md` — created — this record.

## Decisions made
- A passing existing test suite is insufficient to recommend merging reproduced data-loss/auth defects. Claude fixes the admin branch; Codex reviews the corrected SHA and integrates with public work afterward. No merge to the published `main` is implied.
- No direct communication tool to the user's separate Claude session is available. Supplied the requested prompt as a repository artifact rather than claiming to have sent it.
- Preserve one eventual public UI. Do not expand the migration while the owner's concern about retaining Flutter UI authoring is unresolved. Shared content, release snapshots and preview protocol remain useful with either renderer.
- Art work is independent of that framework choice. Generated concept keeps real page text separate, uses carved figures and architectural depth, and contains no claim about an actual monument. No new production motif or existing token value was changed.
- Review worklog sequence uses 03 because Claude already wrote September 12 records 01 and 02 in the other checkout.

## Tests
- Added: no repository tests in this read-only review; exact required regressions are specified for Claude. Additional local fixture/browser reproductions live in temporary review scratch.
- Modified: none.
- Full suite: pass, 229 Worker passing, 0 failing on fd5139a. Public checkpoint already passed 676 Flutter tests and 7 Node tests; this review did not repeat unchanged Flutter tests.
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
- AR-1 through AR-9 require Claude's fixes and a re-review before merge. A5, actual public preview, field consumers and coordinated publishing remain incomplete.
- Framework direction needs the owner's answer about retaining Flutter UI authoring; the earlier delegated Astro choice did not explain that consequence clearly enough.
- The entrance study's top cornice/right edge are close to the frame. It needs composition refinement and a dedicated phone framing before use; no interactive entrance or final visual approval is claimed.
- The broader R1–R9 work remains underway. No production deployment, Search Console submission or physical-device verification occurred.

## Next
Claude fixes the merge review findings; Codex continues the public implementation once the Flutter authoring preference is clear, using one maintained UI and the documented Egyptian visual direction.
