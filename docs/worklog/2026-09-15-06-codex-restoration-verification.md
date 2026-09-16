# 2026-09-15-06 — Verify the restored account and preserve the admin work

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** `eae42f4` (restoration PR #39 merged into Asherbinyy/main)

## Goal
Verify the repository copy after merging the restoration, detach the abandoned remote, and record the final deployment and preserved admin branch.

## What changed
- Verified all 41 source branches and four tags on Asherbinyy by exact tag hashes and branch ancestry. The source repository had not changed since the initial snapshot. Its latest main `23a9a83` is an ancestor of restored main `eae42f4`.
- Preserved the newer local admin implementation and evidence on `phase/codex-admin-ui` at `18b8af4`. Its CI run `35008636790` passed. The 47 real-browser checks pass; the local admin uses current owner content and the actual Flutter app.
- Preserved the separate Worker hotfix branch, restored the local public branch to the merged main, and removed the `lsherbini` remote. All configured upstream remotes and the default push target are now `origin` on Asherbinyy.
- Aligned the temporary Worker checkout to restored main so it does not retain the abandoned origin as an active deployment configuration.
- Saved the source-copy, CORS, test and CI evidence in `docs/audits/2026-09-15-account-return/verification.json`.

## Files touched
- `docs/audits/2026-09-15-account-return/verification.json` — created — exact preserved source/main refs and verification evidence.
- `docs/worklog/2026-09-15-06-codex-restoration-verification.md` — created — post-merge restoration record.

## Decisions made
Merge rather than squash the restoration PR so the source main remains in the published branch’s history. Preserve experimental/admin code on its existing branches; restoring the account does not authorize merging every development branch into the published app. Keep the abandoned repository until the requested deletion scope and owner authentication are available. No force push, tag rewrite or source deletion was used.

## Tests
- Added: none.
- Modified: none in this verification follow-up.
- Full suite: pass, 704 Flutter tests and 70 Worker tests for the public restoration; 710 Flutter tests, 289 Worker tests and 47 browser checks for the preserved admin branch.
- Coverage delta: public restoration measured 86.06% (7435/8639 lines), above the required 80%; delta not measured.
- Both restoration PR verification and visual-comparison jobs passed, as did the corresponding main verification jobs.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 297 public / 309 admin files
fvm flutter analyze                        pass, no issues in either candidate
fvm flutter test                           pass, 704 public / 710 admin tests
fvm flutter build web --wasm               pass in both candidates
```

These are the completed candidate runs recorded in worklogs 04 and 05; this follow-up changes documentation only. The additional public `fvm flutter test --coverage` also passed. The existing Cupertino icon-font build warning remains.

## Known issues left open
- Source deletion is pending. The owner was asked whether this means the repository or the entire account. The authenticated account has write, not admin, access to `Lsherbini/lsherbini.github.io`; no deletion was attempted.
- The custom domain has not been supplied. The restored site continues using the original GitHub Pages domain.
- The redesigned admin remains a separate local/branch implementation, with the production integration limits documented in its review.

## Next
Complete the requested source deletion after the owner clarifies the scope and supplies owner-authorized access.
