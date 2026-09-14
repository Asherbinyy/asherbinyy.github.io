# Continue here

Updated September 14: **the owner rejected this visual result and transferred all app/admin work to Claude.** Codex has stopped visual implementation. The inventory below describes the working tree, not an accepted design. Read [29-CLAUDE-FULL-PROJECT-HANDOFF.md](29-CLAUDE-FULL-PROJECT-HANDOFF.md) first.

## Authorized scope

The earlier rollback was too broad. The owner explicitly asked to restore football and article images, then confirmed springier game controls/Egyptian character, expandable education, better About/skills presentation and removal of the intro’s bottom credit.

Keep the existing Flutter site composition, routes, backgrounds, navigation and Journey. No fixed background image or page consolidation. Papyrus refers **only to Home’s 5+ years and MSc cards**: roll closed on click, reopen on pointer exit or another click. That interaction remains deferred. Skip Daybreak design and security review. Claude now owns app and admin; preserve uncommitted work before consolidating checkouts.

## Retained and restored locally

- All prior content corrections remain: shared positioning/skills/learning/tools, plain Home/recruiter presentation, Home Remote freelance wording and static CV/Brief content. No new owner facts or translations.
- About alone now groups supplied skills/learning/tools into readable tags. Education uses existing surface/type/radius tokens and expandable cards; original marks, highlights and full-size evidence remain. Reduced motion bypasses size animation entirely (zero-duration AnimatedSize triggered an SDK layout assertion).
- Football: grounded figure with planted foot, boot contact at 28% of the 1.4s shot, flight, net impact at 68%, actual G O A L. Tap/keyboard replay; reduced motion shows the end state. Pointer exit never rewinds the shot.
- Writing: six actual published covers in `assets/media/article-*`, keyed by canonical article URL in `assets/content/writing-covers.json`. The manifest retains original CDN source URLs. Titles/dates/tags still fall back to `writing.xml`; live nonempty feed wins. Localhost is rejected by the production relay, so bundled covers make the preview useful without changing Worker policy. These are a dated snapshot, not automatically refreshed files.
- Game: one jump per held press, 140ms input buffer/coyote grace, variable jump height, acceleration/braking, same-wall boost protection and landing squash. A small linen-clad humanoid with a gold nemes replaces the scarab. Existing tower/score/levels retained. Reduced motion skips squash/entrance effects.
- Intro bottom caption removed. Existing full source/licence record remains publicly available through Artwork credits on About.

The removed uncommitted football/game work was reconstructed from the requested behavior; this is not claimed to be a byte-for-byte recovery. Original supplied inspiration files are untouched.

## Verification / preview

Final technical checks passed: format, analysis, 693 tests and Wasm build; see the September 14 handoff worklog. No fresh successful browser acceptance was completed before the transfer. Preview serves `build/web` at http://localhost:8333 while its process runs; the page needs reloading after a build. Logs are `/private/tmp/nocturne-restore-*.log`.

## Still open

- Cloud leaderboard/nickname flow, rewards/combos and richer level patterns: proposal only in `26-GAME-LEADERBOARD-CONTRACT.md`. Best score remains memory-only for the open game stage.
- Real Flutter admin preview/release parity, galleries, platform logos and SEO remain separate work. Nothing merged/deployed; security review paused.
- New Arabic UI/content labels are literal English until approved translations exist.
- Physical phone testing and owner acceptance of restored visuals/game feel remain outstanding.

**Next:** Claude reviews/reworks this rejected visual pass and integrates app/admin under the September 14 handoff.
