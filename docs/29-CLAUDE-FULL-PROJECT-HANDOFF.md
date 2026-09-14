# Claude — full app and admin ownership

September 14, 2026. This supersedes the earlier Codex/Claude file split.

## Owner’s latest instruction

The owner rejected Codex’s latest visual work as basic and unconvincing and asked Claude to review and enhance **both the app and admin**. Claude may edit `lib/**`, `web/**`, `tool/**`, public assets, schemas, Worker/admin, tests and CI. Do not wait for Codex to implement the public half.

Flutter remains the only interactive frontend. The previous Astro experiment is rejected. The recent Flutter visual work is also **not accepted**. Preserve useful content corrections and real article covers rather than another blanket rollback. Do not mistake compilation or passing tests for visual approval.

## The two working trees

- Public: `/Users/sherbini/Flutter Projects/nocturne`, branch `phase/flutter-experience`, base `48f4076`. Significant **uncommitted** content, visual, test and documentation changes; inspect `git status`, including untracked files. The current files are the review source.
- Admin: `/Users/sherbini/Flutter Projects/nocturne-admin`, branch `phase/reinnovation-admin`, latest reviewed `4e75259918f0f0f300085bf3191fd598b7dc4e6f`. Clean when reviewed. Preserve any later leaderboard work.

Codex has stopped visual feature work. Before consolidating, make an external snapshot of tracked diff **and untracked files**. Use a fresh integration branch/worktree; inspect conflicts rather than overwriting one checkout with the other. Do not resurrect deleted `site/` or discarded artwork/docs during a merge. Review source differences, then carry the owner-approved content and the admin commits into the integrated tree. Nothing should go to published `main` as a side effect.

## First blocker: stale password rotation

The original delayed-login P1 is fixed by `4e75259`: the independent reproduction returns 401 after rotation. Codex independently ran 278 Worker tests successfully.

One adjacent P1 was reproduced: a password-change request using an old session/password, paused during verification, can finish after a recovery rotation and overwrite the owner’s new password. The owner’s new password then returns 401 while the stale request’s replacement password/session works. Rotation itself must compare the verified generation inside the authoritative transaction before any verifier write/session invalidation.

A focused, tested patch is ready at `docs/audits/2026-09-14/admin-rotation-fix.patch`; the accompanying note records 280 passing Worker tests, original/fixed reproductions and exact application instructions. It passes git apply --check against 4e75259; it is not applied in the shared admin checkout. Apply it to the current admin branch with `git apply --check` first, inspect any divergence, and rerun tests. Do not claim it is merged or deployed merely because the patch exists. No broad security re-audit is requested after this concrete fix.

## The four former “Codex blockers” are yours now

| Work | Concrete completion requirement |
|---|---|
| Real Flutter preview | Implement protocol v1 browser interop and in-memory provider overrides, using real public widgets. Validate origin/source/channel/version/session before payload access; acknowledge the actual rendered draft and locale. No intro, persistence, analytics or credentials in preview. Prove cross-origin edit/select/reorder/EN/AR/error recovery against Flutter, not the stand-in. |
| HTML publication parity | Extend the existing Dart generator and Flutter reader to one immutable release. Canonical digest fixtures, actual `/release.json` acknowledgement, route-specific readable HTML/metadata, failed-release preservation and rollback. No second designed site. Local CI/build proof before any production dispatch. |
| Content renderers | Consume accepted links/domain icons, project media, interest galleries and name audio. Use actual official marks or existing icon assets; generic fallback for unknown domains. Keep supplied content and safe compatibility fallbacks. Verify preview and published output consume the same fields. |
| A5 fonts/appearance | Implement one versioned renderer allowlist consumed by admin and Flutter. Stored IDs remain `nocturne`/`daybreak`; unknown values report unsupported. **Skip Daybreak design work**. Do not create unrequested presets or change the overall design while wiring controls. |

Keep `20-APP-ADMIN-CONTRACT.md` and `23-ADMIN-INTEGRATION-REPLY.md` for protocol details. They no longer grant Codex exclusive ownership. The current profile also has optional `skills`, `learning`, `tools`; support them in the admin schema/editor, preview and generator without treating learning as delivered experience.

## App review and visual direction

Read the original owner attachment `/Users/sherbini/.codex/attachments/0c611bd9-edf3-4c16-84d0-e8781da79ccc/pasted-text.txt`, project docs and recent worklogs. Inspect the actual files in `supporting files/inspiration/`, especially the suggested page, pattern, hero and video. Render the current app before designing.

- The owner wants convincing Egyptian detail, recognizable icons, material and purposeful animation. The current generic education boxes/skill tags and thin football/game line art did not satisfy them. Review and improve these; do not simply relabel Codex’s result.
- Preserve the existing site layout/navigation and accepted Journey layout. No broad page mergers or wholesale restyling without the owner’s explicit new direction.
- Papyrus means **only the first two Home stats, 5+ years and MSc**. Reference the supplied design closely: believable roll-up on click, reopen on pointer exit or second click. Not every education/career card. This interaction is still unimplemented.
- Background reference means inspiration for a restrained convincing pattern, **not a fixed full-screen image**. Do not bring back that rejected treatment.
- About needs a deliberate hierarchy, better skill presentation, expandable education and retained coursework evidence. No invented grades, claims or Arabic translations.
- Football must visibly kick a ball into a recognizable goal, react at impact and say G O A L. Current reconstruction exists but is unaccepted; review motion at contact/flight/impact, not just an idle screenshot.
- Game: Egyptian humanoid with gold headpiece, enjoyable manual Space/tap controls, springy movement, rewards and stronger levels. Existing local input buffering/coyote time/variable height/momentum can be kept or tuned after playtesting. Do not silently restore automatic jumping.
- Keep real article images and content corrections. The six covers are unchanged published originals; `writing-covers.json` maps article URLs to assets/source URLs. They work when localhost is rejected by the public relay.
- Intro bottom credit caption is removed; attribution is linked from About. Retain source/licence information while improving the intro, including phone framing.
- `pubspec.yaml` now enables the missing Material icon font. This fixes a concrete loading defect, not the visual-design complaints. Do not add Cupertino or substitute invented brand marks.

For each visual slice, show desktop and phone browser captures plus the actual interaction before expanding the scope. Respect reduced motion, keyboard/focus/semantics and existing palette/tokens. Record what is actually verified; physical-device tests are still missing.

## Leaderboard — yes, proceed, own both halves

The owner’s existing request authorizes implementing the leaderboard. There is no need to ask again whether to start. Use `26-GAME-LEADERBOARD-CONTRACT.md`: first-entry nickname/public-ranking choice, local play still available, top 5/10 presentation, at most ten retained qualifying entries, and deterministic server verification.

Freeze a versioned physics/PRNG/fixed-timestep contract **before** implementing replay. Current Flutter uses Dart `math.Random` and variable frame deltas; a JavaScript port that merely looks equivalent is not proof of agreement. Add cross-language synthetic replay vectors, bounded proof sizes/run duration, one-player best, tie/idempotency rules and transactional eviction. No fake rankings, silent nickname persistence or permanent replay archive. Client-only scores are not verified scores.

## Durable Object activation

Cloudflare’s current documentation confirms SQLite-backed Durable Objects are available on Workers Free as well as Paid: https://developers.cloudflare.com/durable-objects/platform/pricing/ . Do not treat paid-plan availability as an unresolved prerequisite for local implementation.

Account-specific subscription/Worker-settings verification through the connected Cloudflare tool failed with `10000: Authentication error` on September 14. No account/bindings were changed. Actual account quota/billing and deployed state are therefore unverified.

Prepare and test migration/rollback locally now. Activation must preserve content, revisions/heads, password verifier/generation and the intended session policy; the existing README’s content-only copying instructions are not enough to assume all auth state is preserved. Retest copied counts/digests and a failed/resumed migration. Enabling an empty object against existing content is not an acceptable shortcut. Keep production untouched until the concrete account/migration plan is ready for approval; report the exact remaining access/action then.

## Ready-to-send prompt

> Claude, take full ownership of both the Flutter app and admin now. I reject Codex’s latest visual result. Read `/Users/sherbini/Flutter Projects/nocturne/docs/29-CLAUDE-FULL-PROJECT-HANDOFF.md` and inspect both working trees before editing. The old Codex-only file restrictions are revoked. Preserve uncommitted work and the genuine content/article-image improvements; do not do another blanket rollback. Apply and verify the provided stale-password-rotation fix, then own the real Flutter preview, HTML release parity, content renderers, A5 integration and both halves of the leaderboard. Review and improve the app against my supplied inspiration, starting with a small browser-reviewed About/education/skills slice; improve football, game and intro through actual motion checks. Papyrus is only the 5+ years and MSc Home cards; no fixed background image, no wholesale layout/nav changes, keep Journey and skip Daybreak. Read the documented physics/replay and migration constraints. Work in reviewable milestones, render desktop/phone views, run the required checks, keep concise worklogs/handoffs and state unfinished work honestly. No production deployment, destructive reset or merge to main without my explicit release instruction.

## Verification status

Final public FVM checks passed: format, analysis, 693 tests and Wasm build (243.5s). The MaterialIcons asset is present in the built manifest (7,932 bytes after tree shaking). An unrelated CupertinoIcons warning remains. The initial browser check reached an expired localhost process and is not visual evidence; the subsequent restart/check was interrupted by the final handoff request. No fresh visual acceptance is claimed. Tested admin-patch results are in `audits/2026-09-14/admin-rotation-fix-results.md`. Claude’s reported 136 browser checks were not independently rerun in this handoff. The rejected visual pass has not been visually accepted and its technical checks do not change that status.
