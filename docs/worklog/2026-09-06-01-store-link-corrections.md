# 2026-09-06-01 — Store link corrections

**Agent:** GPT-5 / Codex
**Milestone:** 1
**Started from:** 2026-09-05-14-milestone-one-completion.md

## Goal
Resolve the dead Snunu link and ambiguous duplicate AZ Courses/AZ Exams link identified in the Milestone 1 handoff without inventing replacement listings.

## What changed
- Removed the dead Snunu App Store URL while retaining the application in the work ledger.
- Removed the duplicate AZ Exams Play Store URL while retaining the independently verified AZ Courses listing and the AZ Exams application record.
- Made duplicate nonempty store URLs a content validation failure.
- Updated ledger tests to require eight App Store links, one Play Store link, and three explicit no-listing labels.
- Rechecked all nine remaining URLs. Six returned HTTP 200 directly; Apple's lookup API returned one result for each of the three listings temporarily rate-limited by the storefront.

## Files touched
- `assets/content/apps.json` — modified — removed one dead and one ambiguous duplicate store URL.
- `lib/content/content_parser.dart` — modified — reject duplicate public store links.
- `test/unit/content/content_models_test.dart` — modified — cover duplicate store-link rejection.
- `test/widget/work/work_test.dart` — modified — assert the verified listing and no-listing counts.
- `docs/worklog/2026-09-06-01-store-link-corrections.md` — created — record the release-blocker resolution and evidence.

## Decisions made
No replacement IDs were guessed. An empty store map renders the existing localized “No public store listing” state, which is accurate until the owner supplies an independently verifiable URL. The Google Play URL remains attached only to AZ Courses because that record already has the corresponding iOS AZ Courses listing and the duplicate provided no evidence that the same Play listing represented AZ Exams.

## Tests
- Added: duplicate nonempty store URL validation case.
- Modified: work-ledger store and no-listing counts.
- Full suite: pass, 382 non-golden and 36 golden tests, 0 failing.
- Coverage delta: 92.82% (3231/3481 lines); no meaningful change expected from this correction.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (184 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage --exclude-tags golden   pass (382 tests)
fvm flutter test --tags golden             pass (36 tests)
fvm flutter build web --wasm               pass
```

## Known issues left open
- Snunu and AZ Exams have no public listing until the owner supplies corrected URLs.
- The source still contains eleven applications although the design documents refer to twelve.
- Real-device, deployed deep-link, Worker transport, performance profiling, map interaction and visual review items from the handoff remain open.

## Next
Implement and test the Cloudflare Worker transport, retaining a disabled client default until a deployed endpoint is configured.
