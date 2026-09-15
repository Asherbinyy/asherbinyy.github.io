# 2026-09-15-05 — Restore Asherbinyy without losing the migrated history

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** `lsherbini/main` at `23a9a83`

## Goal
Reverse the account move at the owner's request, preserve every branch and tag, restore the original hosting origin and detach the abandoned remote after verifying the copy.

## What changed
- Restored `https://asherbinyy.github.io` in the site shell, canonical/static generator, its tests, living reference docs, Worker config and admin bundle base.
- Started the return branch from the newest `lsherbini/main`, retaining both recent migration merge commits and all their ancestors.
- Fetched both remotes and verified a complete local bundle at `/tmp/nocturne-before-asherbinyy-return-2026-09-15.bundle`.
- Remote inventory found 41 branches and four tags on lsherbini, compared with 24 branches on Asherbinyy. Pushed the 17 missing branches and advanced the newer shared non-main branch without force. All four tags match. Main restoration is carried by this branch.
- Restored the existing deployed Worker's origin and exactly one bundle-URL literal. All other bindings, secrets, runtime settings and cron schedules were preserved.
- The deployed Worker version is `097dca7b-2c4b-4bc3-b598-907e57a5478a`. Its module hash is again `4a3fa6407bbf76b03ff8cfc7d5277bf3c8c05a91dfd6c2c7a674588b9cb90ae8`.
- The abandoned repository has no releases, issues, Actions secrets or Actions variables requiring migration. The original repository already has GitHub Actions Pages deployment and HTTPS configured, with no custom domain.
- Marked the old migration guide as historical. No owner content, claims, schema or public design was changed for the account restoration.

## Files touched
- `wrangler.toml` — modified — restore the permitted site origin.
- `worker/src/admin.js` — modified — restore the bundled-content origin.
- `tool/generate_static.dart` — modified — restore canonical, sitemap and generated-document URLs.
- `web/index.html` — modified — restore canonical, sharing-image and structured-data site URLs.
- `test/unit/tool/generate_static_test.dart` — modified — assert the restored canonical origin.
- `README.md` — modified — restore the public site link.
- `docs/00-PROJECT-BRIEF.md` — modified — current hosting origin.
- `docs/08-GIT-AND-CI.md` — modified — repository/domain setup references.
- `docs/11-OPEN-ISSUES.md` — modified — record the account reversal and pending deletion decision.
- `docs/31-MOVING-TO-A-NEW-ACCOUNT.md` — modified — mark abandoned instructions as historical.
- `docs/worklog/2026-09-15-05-codex-return-to-asherbinyy.md` — created — restoration and preservation record.

## Decisions made
Preserve source history by ancestry, never a destructive mirror or force push. Keep the admin integration on its own branch; the public release does not silently deploy the unfinished backend migration. The Worker was patched from its exact deployed module, not from either development admin branch. No custom domain was invented or configured.

The phrase “delete the lsherbini one” could mean the repository or the whole account. Asked for the scope while proceeding with the safe copy. The authenticated GitHub user is Asherbinyy and has write, not admin, permission on the abandoned repository. Deletion is not attempted until preservation is verified and scope/access is resolved.

## Tests
- Added: none.
- Modified: static generator origin assertions.
- Full suite: pass, 704 Flutter tests and 70 Worker tests passing, 0 failing.
- Coverage delta: not measured in this local run; CI retains its existing coverage gate.
- Live Worker preflight: Asherbinyy returns 204 with its exact allow-origin header; lsherbini returns 403 with no allow-origin header.
- Live admin: 200, restored bundle URL present and lsherbini URL absent.
- No valid analytics event was submitted and collection remains disabled.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 297 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

Generated ignored models/localizations, marks and static routes with FVM before the checks. The existing Cupertino icon-font warning remains in the successful build.

## Known issues left open
- Repository/account deletion requires clarified scope and access. The source is retained for now.
- A custom domain has not been selected or purchased; hosting stays on the original GitHub Pages origin.
- The separate admin integration has its own local review evidence and deployment dependencies.

## Next
Verify the restored main deployment and remote branch/tag ancestry, then remove the abandoned remote and complete the authorized deletion when scope/access permits.
