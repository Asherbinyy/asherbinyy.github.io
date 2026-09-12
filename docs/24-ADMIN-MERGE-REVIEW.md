# Admin review before integration

2026-09-12. Reviewed `phase/reinnovation-admin` at `fd5139a`, against shared base `6cfb1f1`. Codex inspected source and ran the Worker suite: **229 pass, 0 fail**. Additional fixture-only reproductions below reveal defects outside that suite. No production data or credentials were used. Claude's checkout remains unchanged.

**Do not merge this revision yet.** Fix the issues below, then integrate on the app/integration branch and run combined checks. `main` is the published site; this review does not authorize a production deployment.

## Required fixes

### AR-1 · P1 · Concurrent publication loses content and history

`worker/src/index.js:396`, `:437`: the base check and revision/content/head writes are separate KV operations. Two simultaneous PUTs for the same fixture document with base revision 0 both returned **200 and revision 1**; history retained only one entry.

Serialize authoritative content mutations through transactional storage. Apply it to publish, rollback and withdrawal, with one revision precondition and an atomic content/history/head update. An in-process mutex is insufficient across Worker isolates: [Cloudflare KV consistency documentation](https://developers.cloudflare.com/kv/concepts/how-kv-works/). Preserve the public raw-document GET shape. Validate the selected storage approach against actual provider support and cost constraints before introducing bindings; no production migration during this fix.

Acceptance: two concurrent same-base writes yield one success and one conflict, every accepted revision is retained, and injected write failures cannot leave mismatched content/head/history.

### AR-2 · P1 · Password throttling still evaluates every guess

`worker/src/index.js:895`: password derivation/comparison happens before the attempt limit. After eleven failures, another wrong password returned 429 but the ordinary correct password returned 200. A caller can keep testing guesses indefinitely; only the failure response changes.

Check a scoped throttle before ordinary password verification. Preserve a separately designed recovery path without allowing ordinary password guesses to bypass the limit or a global counter to lock the owner out. Do not add public visitor tracking.

Acceptance: a blocked ordinary attempt never invokes password derivation/comparison; recovery and legitimate session use behave as documented. Concurrent attempt accounting must also be bounded.

### AR-3 · P1 · Async upload writes into whichever document is open later

`worker/src/admin/client-fields.js:431`, `:442`; `client-state.js:172`: upload completion calls `write(path, ...)`, which resolves `current()` at completion time.

Browser reproduction: delay upload by two seconds, upload Profile's portrait, immediately open Off duty. The next validation request for `interests.json` contains an uploaded `portrait.src`. Profile was the intended target.

Capture document identity, stable item identity and field before starting an async operation. Apply results to that target only; handle reorder/removal and cancelled or superseded uploads explicitly. Audit delayed review, publish, rollback, withdrawal and media-picker callbacks for the same dependence on mutable `state.file`/`current()`.

Acceptance: navigating to another document, reordering/removing an item, or editing during an in-flight operation never changes an unintended field or marks a newer unsaved draft as published. Publish success must acknowledge the exact submitted snapshot, not whatever `entry.draft` contains when the response arrives (`client-publish.js:184`).

### AR-4 · P1 · Refreshing heads silently rebases dirty drafts

`worker/src/admin/client-publish.js:379`; called during reauthentication at `client-account.js:64`: `loadHeads()` overwrites each loaded entry's base revision without refreshing its baseline or resolving its draft.

Reproduction with the actual function and synthetic state: a dirty draft based on revision 1 receives head 2; its revision becomes 2 while baseline and draft remain unchanged. Its next publish can overwrite the intervening revision without a conflict.

Keep the document snapshot and its base revision paired. A head refresh reports divergence; it must not silently grant a dirty draft permission to overwrite it. Fetch baseline+revision consistently on initial load as well.

Acceptance: reauthentication/head refresh after another editor publishes retains the original base, reports a conflict on save, and preserves the local draft.

### AR-5 · P2 · Rollback and withdrawal ignore stale revisions

`worker/src/index.js:550`, `:698`; `client-publish.js:347`; `client-app.js:402`: rollback/withdrawal do not enforce or send the base precondition used by PUT. After revision 2 exists, rollback with `x-base-revision: 1` still returns 200 and replaces the newer content.

Make all mutations use AR-1's atomic precondition. Send the captured expected revision from the UI and surface conflicts without discarding drafts.

### AR-6 · P2 · Preview validation belongs to an earlier draft

`worker/src/admin/client-preview.js:79`; `client-state.js:301`; `client-app.js:252`: the preview gate checks the most recent issues for the file, not proof that the exact outgoing draft validated.

Browser reproduction: open a valid Off duty entry, empty its required English label and immediately switch to Arabic within the validation debounce. The stand-in receives the missing-English draft and the panel says **“Showing your draft, as the site would render it.”**

Associate validation with file + draft generation/digest. Invalidate it on every edit and only send the exact validated snapshot. A delayed validation/acknowledgement must not certify a later edit. Apply the same invariant when switching language or reconnecting.

Acceptance: the invalid draft never crosses the message boundary; delayed old results and rapid edits/navigation cannot change that.

### AR-7 · P2 · Snapshot reference checks trust caller-supplied identifiers

`worker/contracts/snapshot.js:65`; `worker/src/index.js:1775`: reference validation uses an optional external reference list instead of deriving it from the resolved documents.

Reproduction: set a fixture career role's `appIds` to `['missing-app']`. Snapshot creation still returns no problems and a digest, with references omitted or a caller-supplied list containing that nonexistent ID.

Resolve all documents first, derive allowed IDs from those documents, then validate cross-references. Never allow supplied reference hints to weaken release validation.

### AR-8 · P2 · Truncated M4A throws instead of returning a validation error

`worker/src/index.js:1314`: the atom bounds check permits 20 bytes, but version-1 `mvhd` parsing reads through 32. A synthetic 52-byte truncated file caused an uncaught `RangeError` from `DataView`.

Validate version-specific lengths against both file and enclosing atom boundaries before reads. Return a controlled 400 for malformed media; add truncated version-0/version-1 cases.

### AR-9 · P2 · Active sessions do not follow the promised idle expiry

`worker/src/index.js:779`: successful session use does not extend `expires`. A session active at hour 11 fails at hour 12:01, despite only 61 minutes of inactivity. Documentation promises twelve hours idle and seven days absolute.

Implement bounded idle renewal while retaining the absolute limit, or explicitly revise the policy consistently. Test repeated use, actual idle expiry and absolute expiry. Do not replace one stale-storage race with another.

## Integration and documentation corrections

- The real public preview adapter is still absent. The harness proves the admin-side protocol against a test double, not end-to-end rendering of the site. Keep that distinction in the status.
- `INTEGRATION.md` contradicts itself: it first says no fields were added, later lists added fields; §3.2 still describes the old outline; §3.3 asks for a decision §3.0 says was answered. Rewrite current sections; retain history only where it explains a constraint.
- Replace “nothing on the admin side” with the remaining evidenced work. A5 is still unbuilt, and accepted field editors still lack public consumers.
- Keep theme IDs `nocturne` / `daybreak` compatible; display labels may be Kemet / Deshret. This is a valid compatibility finding, not a reason to rename stored IDs.
- The pinned digest of the owner's live bundle is not a durable interoperability test: ordinary legitimate content edits change it. Use a fixed synthetic fixture with a known digest, plus a direct cross-implementation comparison in integration tests.
- The owner has now asked explicitly about maintaining Flutter. The Astro first slice is committed locally at `034d50e`; long-term rendering is being clarified. Keep Worker snapshot/protocol contracts renderer-neutral and do not edit `lib/**` or `site/**` to get ahead of that answer.

## Prompt to give Claude

```text
Continue in /Users/sherbini/Flutter Projects/nocturne-admin on phase/reinnovation-admin.
Codex independently reviewed fd5139a. Read the complete review at:
/Users/sherbini/Flutter Projects/nocturne/docs/24-ADMIN-MERGE-REVIEW.md

Fix AR-1 through AR-9 before calling the branch ready to merge. The 229 existing
tests pass, but the review contains additional reproduced failures. Add meaningful
regressions for each failure, particularly genuinely concurrent content writes,
throttle-before-password-verification, delayed uploads across navigation/reorder,
dirty drafts across reauthentication, and exact-draft preview validation.

You own all Worker/admin fixes. Keep public raw GET response shapes compatible;
do not edit Codex's lib/**, site/**, web/** or assets/content/**. For transactional
storage, choose a provider-supported approach, document local bindings/migration
and free-tier implications, and test it locally. Do not deploy or change production
bindings, credentials, content or analytics. A per-isolate mutex is not sufficient.

Correct the stale/contradictory INTEGRATION.md sections and worklog claims. Preserve
the real theme IDs nocturne/daybreak. The public renderer choice is being clarified
with the owner; keep snapshot and preview contracts renderer-neutral. Do not build
a second public UI in the admin checkout.

Run Worker and browser regressions plus the four FVM checks. Record exact results,
remaining integration gaps and commits. Commit and push your fixes on the admin
branch, then give Codex the new SHA and evidence for re-review. Codex will integrate
the corrected admin branch with the public work and resolve combined checks.
Do not merge to main: main publishes the site. Do not report live preview,
appearance or HTML publication complete until the real public integration passes.
```
