# Admin re-review — afc8969

2026-09-12. Reviewed `afc8969ef056173cc1e7e0fcfc2f5a2bda56529d` on `phase/reinnovation-admin`, read-only in the separate admin checkout. **Not ready to merge.** Claude owns the remaining fixes. The public app remains Flutter; the rejected separate frontend has been removed.

## Evidence and limits

- Independently ran the Worker suite: **262 passing, 0 failing**. This does not cover the additional races below.
- Ran the actual Worker/ContentStore in **local Wrangler/workerd**, with a temporary enabled SQLite-backed Durable Object binding and sanitized fixtures. Eight simultaneous same-base saves produced **one 200 and seven 409s**, with one retained revision/history entry. This confirms the content-write path works in the local Cloudflare runtime, beyond the existing double.
- The three failures below were reproduced with the actual handler/store code and controlled in-memory storage/delays. They are deterministic concurrency regressions, not a claim of production exploitation.
- Claude reports 136 browser checks and four FVM checks on his branch. This re-review did not independently repeat all seven browser scenarios; do not conflate his results with ours.
- No production requests, owner content writes, migration, credentials, deployment or merge occurred. The production binding remains commented out. Local runtime success does not establish plan availability, cost, migration safety or production readiness.

[Reproduction script and recorded evidence](audits/2026-09-12/admin-rereview/README.md). The whole-release loop is a related source finding; the deterministic script proves the editor read race.

## Remaining required fixes

### ARR-1 · P1 · Concurrent guesses bypass password admission

`worker/src/index.js:937` reads attempts, then performs password derivation, then `:951` records a failure. Serializing the individual storage calls does not make the whole admission decision atomic.

Reproduction with the Durable Object path: after nine sequential failures, send thirty simultaneous wrong passwords. All thirty derive a password and return 401; none returns 429. Only one ordinary attempt should remain admissible in that window.

Implement one atomic **check-and-reserve** operation before password derivation. Define reservation behavior for successful, failed and interrupted requests without reopening a burst bypass. Keep recovery separate. Regression must assert the number of actual derivations with one slot left, not merely the final counter value.

### ARR-2 · P1 · Delayed renewal revives a logged-out session

`worker/src/index.js:785–805` reads a session from KV, then separately writes renewal. Logout/password changes can delete or invalidate the session between those operations.

Reproduction at hour eleven: hold the renewal write, log out (200), release the old write, then use the token again. Authentication returns 200. The stale renewal has restored the revoked session.

Use an authoritative transactional session lifecycle or an equally rigorous revocation/generation mechanism. Renewal must never undo logout or password-change invalidation. Test both races and the existing idle/absolute expiration behavior. KV read-then-write plus a second ordinary check cannot provide the necessary guarantee across isolates.

### ARR-3 · P2 · Editor and release snapshots still use separate reads

`worker/src/index.js:472–473` calls `backend.head(file)` and `backend.readDocument(file)` separately. A combined HTTP envelope does not make its contents one atomic fact.

Reproduction: commit revision two between those calls. The editor receives revision one paired with revision two's document. Add a single store operation returning document and head consistently.

`worker/src/index.js:1830–1834` also resolves the five release documents through separate reads. Capture the complete published override set in one authoritative operation; resolve bundled fallbacks from an explicitly immutable bundle and validate the resulting whole snapshot. Do not certify a release assembled from interleaved edits as a coherent capture. Add deterministic interleaving regressions for the editor envelope and release snapshot.

## Earlier findings

[AR-1 through AR-9](24-ADMIN-MERGE-REVIEW.md) remain the original review record. Content mutation transaction/preconditions, async target capture, exact-draft validation, derived reference checks, truncated media validation and ordinary idle renewal now have fixes/tests in the reviewed SHA. The remaining items above concern admission, revocation and consistent reads beyond those tests. Inactive transactional configuration remains an operational gap; do not describe KV fallback as protected.

## Integration after fixes

- Keep Worker/admin ownership with Claude. Flutter `lib/**`, `web/**`, `tool/**` and public content remain Codex's lane.
- Remove dependence on the deleted separate frontend digest module. Keep frozen synthetic canonical-JSON vectors and the independent specification comparison; later compare against the Dart generator implementation.
- Keep preview protocol v1, accepted additive fields, theme IDs and renderer-neutral snapshot/release contracts. The real Flutter adapter, field consumers, appearance allowlist and release coordinator remain open, as specified in [the integration reply](23-ADMIN-INTEGRATION-REPLY.md).
- Document the required local/production binding, migration and recovery procedure. No production enablement during fixes. The combined release cannot claim concurrency protection while operating on unsafe fallback writes.
- Commit the corrected admin branch, supply SHA and evidence, then Codex re-reviews and integrates on a non-production branch. No merge to `main` or deployment here.

## Prompt for Claude

```text
Continue in /Users/sherbini/Flutter Projects/nocturne-admin on phase/reinnovation-admin.
Codex re-reviewed afc8969. Read:
/Users/sherbini/Flutter Projects/nocturne/docs/25-ADMIN-REREVIEW.md
/Users/sherbini/Flutter Projects/nocturne/docs/23-ADMIN-INTEGRATION-REPLY.md

Fix ARR-1, ARR-2 and ARR-3 before merge: atomic check-and-reserve before password
derivation, renewal that cannot resurrect logout/password-revoked sessions, and
atomic document/head plus whole-release capture. Add deterministic concurrency
regressions proving the previous code fails, not just counter assertions.

The owner rejected the separate frontend. Flutter is the only interactive UI.
Remove dependencies on the deleted site digest module; keep frozen synthetic
canonical JSON vectors and renderer-neutral snapshot/preview contracts. Update
INTEGRATION.md and stale status text accordingly. Do not build a public renderer.
Keep nocturne/daybreak IDs. Real Flutter preview and consumers belong to Codex.

You own Worker/admin fixes only. Do not edit lib/**, web/**, tool/** or owner
content, or Codex's checkout. Preserve raw public GET compatibility. Document
Durable Object binding/migration/recovery requirements and keep unsafe fallback
status explicit. Do not deploy or change production bindings, secrets or data.

Codex independently ran 262 passing Worker tests and a real local Wrangler
content-write concurrency check: one accepted save and seven conflicts. The
three new races still block merge. Run Worker/browser regressions and all four
FVM checks yourself, document exact evidence and remaining operational gaps,
commit/push your admin branch and return the SHA. Codex will re-review and
integrate on a non-production branch once the blockers are fixed. Do not merge
main or label fixture preview/appearance/release integration complete.
```
