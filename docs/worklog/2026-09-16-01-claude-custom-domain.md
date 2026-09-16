# 2026-09-16-01 — The custom domain, in the code

**Agent:** Claude / Sonnet 5
**Milestone:** Re-innovation, full ownership
**Started from:** `eae42f4`

## Goal

The owner set up `sherbini.uk` as a custom domain for the (restored)
`Asherbinyy/asherbinyy.github.io` repository — verified, certificate
approved, `asherbinyy.github.io` now 301s there. Nothing in the code knew
about it yet.

## What changed

Checked what the live site actually served before touching anything:
`sherbini.uk` returned the real page (200), but its own canonical link,
`og:url` and sitemap all still said `asherbinyy.github.io`, and there was no
`web/CNAME` in the deployed output — so a future rebuild had nothing telling
GitHub Pages to keep serving the custom domain except the dashboard setting
already stored there.

Also checked the Worker, since it enforces an origin allowlist: a live CORS
preflight from `https://sherbini.uk` to the analytics beacon returned 403.
`wrangler.toml`'s tracked `SITE_ORIGIN` still said the old domain — this file
is source-controlled, but changing it here does not redeploy the Worker,
which needs Cloudflare access this session doesn't have.

Same categorisation as the account move on the 14th: functional URLs and
living reference docs updated, dated worklogs and audit records left
untouched as accurate history.

- `tool/generate_static.dart`'s `baseUrl`, `web/index.html`'s
  canonical/`og:url`/icons/JSON-LD `url` (not the `sameAs` GitHub profile
  link — that names the owner's coding identity, unrelated to which domain
  serves the site), and the test asserting both.
- `web/CNAME` — new, so the domain survives the next deploy without relying
  solely on the dashboard.
- `wrangler.toml`'s `SITE_ORIGIN` — the tracked value, so Codex's redeploy
  applies the correct one. `SITE_ID` stays `asherbinyy.github.io`: it's the
  historical analytics identity, and changing a hosting domain doesn't
  require renaming existing records — the same call this project made
  moving the other way on the 15th.
- `README.md`, `docs/00-PROJECT-BRIEF.md`, `docs/08-GIT-AND-CI.md` — living
  reference. The git-and-CI guide keeps `asherbinyy.github.io` where it's
  actually about the *repository* name (still true, unchanged), and only
  updates the DNS target to the custom domain, naming both correctly rather
  than replacing one true fact with another.
- `docs/11-OPEN-ISSUES.md` — its own status note said "no custom domain has
  been selected yet," which stopped being true; appended rather than
  rewrote, so the restoration record stays intact.

## Files touched

`tool/generate_static.dart`, `web/index.html`,
`test/unit/tool/generate_static_test.dart`, `web/CNAME` (new),
`wrangler.toml`, `README.md`, `docs/00-PROJECT-BRIEF.md`,
`docs/08-GIT-AND-CI.md`, `docs/11-OPEN-ISSUES.md`.

## Decisions made

**Checked the live site before writing anything.** The gap here was found by
curling the actual domain, not by reading the repo and assuming it matched.

**The repo name and the served domain are two different facts now**, and
both get to stay true in the docs that describe each.

## Verification run

```
fvm dart run tool/generate_static.dart    pass, sitemap/robots regenerated
fvm dart format --set-exit-if-changed .   pass, 297 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

## Known issues left open

- **The Worker is still refusing the real domain.** `SITE_ORIGIN` in the
  deployed Worker has not been redeployed to match `wrangler.toml`'s tracked
  value; a prompt for Codex is in the handoff. Until that redeploy, the
  analytics beacon and the admin preview both 403 for anyone actually
  visiting `sherbini.uk`.
- **Not pushed yet.** Sitting on `phase/flutter-experience`, checks green,
  ready to merge once reviewed.
