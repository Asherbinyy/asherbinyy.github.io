# Conditional password rotation — 2026-09-14

Base: `4e75259918f0f0f300085bf3191fd598b7dc4e6f`. Fix prepared in `/private/tmp/nocturne-admin-rotation-fix`; neither shared checkout's Worker sources were changed.

The previous delayed-login finding is fixed. A related delayed password-change request still used an old verifier to overwrite a password installed by recovery rotation. The patch compares the verified generation inside the rotation transaction before any write; only the supplied recovery credential itself bypasses the comparison. The KV fallback gets the same comparison but remains non-atomic and unsuitable for concurrency guarantees.

## Evidence

- Independent reproduction on original `4e75259`: owner rotation **200**; stale rotation **200**; owner's new password **401**; stale actor's replacement password **200** and newly issued session **200**.
- New regressions against original code: **2 fail**, both return 200 instead of expected 401. Scenarios use an old-session bearer and a recovery bearer with the old current password.
- Patched complete Worker suite: **280 pass, 0 fail, 0 skipped**, Node v20.2.0.
- Independent delayed login: owner rotation 200; stale login **401**, `password-rotated`, no token.
- Independent delayed rotation: owner rotation 200; stale rotation **401**, no token; owner's new password **200**; stale actor's password **401**; old session **401**.
- New tests also assert unchanged verifier, generation and session set after the rejected request.
- The existing concurrent-recovery test now actually supplies the recovery credential for each change. It verifies exactly one final session survives; an earlier successful session can correctly be revoked by a later rotation.

No browser, FVM or Cloudflare-runtime checks were repeated for this isolated JavaScript patch. No production binding, content, secrets, merge or deployment changed.

## Apply in the admin checkout

```bash
git apply --check '/Users/sherbini/Flutter Projects/nocturne/docs/audits/2026-09-14/admin-rotation-fix.patch'
git apply '/Users/sherbini/Flutter Projects/nocturne/docs/audits/2026-09-14/admin-rotation-fix.patch'
node --test worker/test/*.test.js
node '/Users/sherbini/Flutter Projects/nocturne/docs/audits/2026-09-14/verify-login-generation.mjs' "$PWD"
node '/Users/sherbini/Flutter Projects/nocturne/docs/audits/2026-09-14/verify-rotation-generation.mjs' "$PWD"
```

The verification scripts contain only fictional local fixtures and use no network. Run them before and after applying if comparing behavior: the rotation script intentionally fails its expected-rejection assertions on the base commit. Claude should run its browser and required four FVM checks before committing its integrated result.
