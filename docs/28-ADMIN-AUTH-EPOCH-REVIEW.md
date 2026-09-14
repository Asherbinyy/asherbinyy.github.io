# Admin re-review — cb13007

2026-09-13. Read-only review of Claude's `cb13007` on `phase/reinnovation-admin`. **The original ARR-1/2/3 reproductions are fixed. One related P1 auth race still blocks merge.** Independently ran 270 Worker tests; all pass. No production action or checkout mutation.

## Remaining P1: stale password verification can issue a new session

Login reads the old password verifier at `worker/src/index.js:937`. If password rotation and session invalidation complete at `:1025–1036` before this login finishes, its delayed verification still creates a session (`worker/src/store.js:217`). Session creation does not check that the password generation is still current.

Deterministic reproduction: hold an old-password login after the verifier read; complete password rotation; release that login. Rotation returns 200, old-password login returns 200, and the new token authenticates with 200. [Fixture-only script](audits/2026-09-13/admin-rereview/reproduce-cb13007.mjs) and [result](audits/2026-09-13/admin-rereview/result.txt).

```bash
node docs/audits/2026-09-13/admin-rereview/reproduce-cb13007.mjs /absolute/path/to/admin-checkout
```

The assertions reproduce defective behavior on cb13007; adapt them into expected-rejection regressions for the fix. No network, production keys or repository writes.

Use a versioned verifier/authentication epoch. Password rotation and epoch advance must be atomic. Session issuance must compare the epoch actually verified against the current epoch within the authoritative serialized operation. Session use must reject superseded epochs. Cover delayed login, concurrent password changes and injected rotation failure; another sequence of independent calls will retain a race.

Original fixes and this finding were reviewed with the actual Worker and its local Durable Object double. This does not independently repeat a production migration or all Claude's browser checks. The commented production binding/migration remains a separate operational gate.

## Claude prompt

```text
Continue from cb13007 in your admin checkout. Original ARR-1/2/3 are fixed;
Codex independently ran 270 passing Worker tests. Read the new P1 review:
/Users/sherbini/Flutter Projects/nocturne/docs/28-ADMIN-AUTH-EPOCH-REVIEW.md

Fix stale password verification issuing a session after password rotation.
Use an authoritative auth epoch: atomic verifier+epoch rotation, conditional
session issuance against the verified epoch, and rejection of old epochs.
Add delayed-login, concurrent-rotation and interrupted-rotation regressions.
Run Worker/browser and four FVM checks; return the corrected SHA. No main
merge, deployment or production binding/secret/content changes.

Flutter remains Codex's scope. After auth is cleared, review the new requested
leaderboard contract in docs/26-GAME-LEADERBOARD-CONTRACT.md in Codex's checkout.
You own its Worker/replay/ten-entry storage implementation; propose interface
changes through worker/contracts/INTEGRATION.md. Do not build a second UI or
claim the public ranking, draft preview or appearance connected before real
Flutter integration passes.
```
