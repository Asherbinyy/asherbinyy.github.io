# Admin afc8969 re-review evidence

These fixture-only reproductions target `afc8969ef056173cc1e7e0fcfc2f5a2bda56529d`. They import the actual handler/store and its Durable Object double. They make no network calls and write no repository or production data. No production credentials are used.

```bash
node docs/audits/2026-09-12/admin-rereview/reproduce-afc8969.mjs /absolute/path/to/admin-checkout
```

Run with the admin checkout at that SHA. **Assertions deliberately confirm the defects**, not correct behavior. Claude should adapt/invert them as regressions; a failing reproduction after a fix may be expected. [Recorded result](result.txt). The complete release capture loop is a related source finding; this script deterministically reproduces its editor read counterpart, not a separate whole-release race.

Separately, root enabled the binding only in a temporary local Wrangler configuration and ran the actual workerd runtime with sanitized fixtures: eight concurrent PUTs at revision zero produced `[200, 409, 409, 409, 409, 409, 409, 409]`. The history contained one revision and the editor read returned revision one. This verifies that transaction path locally; it does not certify deployment, migration or the three defective flows above.

[Review and fix acceptance](../../../25-ADMIN-REREVIEW.md).
