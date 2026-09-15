# 2026-09-15-02 — The site moves to `lsherbini.github.io`

**Agent:** Claude / Sonnet 5
**Milestone:** Re-innovation, full ownership
**Started from:** `cc859a9`

## Goal

Move the project to the owner's new account. He created it under the wrong
name first (`sherbini.github.io`, which cannot serve at the bare domain
because it doesn't match the owning account's username, `lsherbini`); once
that was found, he renamed the repo himself and invited `Asherbinyy` as a
collaborator.

## What changed

**Access.** The invite was sent at Write, not Admin, and was still pending.
Accepted it via the API from this session (already authenticated as
`Asherbinyy`). Write is enough to push; it is not enough to enable Pages or
rename a repo, both of which need Admin — the owner did the rename himself
before this, so only the Pages toggle remains his.

**History.** Every branch and tag mirrored across, not just the ones checked
out locally. `git push --all` only pushes local `refs/heads/*`, and most of
this repository's 37 branches existed only as `origin/*` remote-tracking
refs — never checked out in this working copy. Pushing all 37 and then
diffing branch-for-branch against the new remote caught 13 that `--all` had
silently skipped; each was checked out locally and pushed individually.
Confirmed by diffing the full branch and tag lists on both remotes until
nothing was missing on either side.

**The domain, in the files that state it as an ongoing fact.** Six files:
the generator's `baseUrl` (which the sitemap, the canonical links and the
static CV/Brief pages are all built from), the canonical/`og:url`/icon URLs
and the JSON-LD `url` field in `web/index.html`, the test asserting all of
that, and three living reference docs (`README.md`,
`docs/00-PROJECT-BRIEF.md`, `docs/08-GIT-AND-CI.md`).

**What was deliberately left alone.** The dated handoff docs, the worklogs,
`CHANGELOG.md`'s release-tag links and `START-HERE.md` all describe what was
literally true at a point in time — rewriting the domain in them would
misrepresent history that is still accurate about when it happened. The
`sameAs` GitHub profile link in the JSON-LD (`github.com/Asherbinyy`) also
stayed: it names the owner's coding identity, which is a fact about him, not
about which account is currently hosting the site, and nobody asked for that
to change.

## Files touched

- `tool/generate_static.dart`, `web/index.html`,
  `test/unit/tool/generate_static_test.dart` — the domain, functionally.
- `README.md`, `docs/00-PROJECT-BRIEF.md`, `docs/08-GIT-AND-CI.md` — the
  domain, as living reference fact.
- `web/sitemap.xml`, `web/robots.txt` — regenerated; gitignored build
  artifacts, not committed.

## Decisions made

**The old repository is frozen, not migrated in place.** `origin` keeps
serving `asherbinyy.github.io` exactly as it was at `8f74a8b`. This commit
only goes to the new remote — pushing it to `origin` too would point the
still-live old site's own sitemap and canonical links at a domain it isn't
served from. The two remotes now legitimately diverge in these few files,
and will keep diverging in them for as long as both sites exist.

**Only the functional and living-reference occurrences moved.** A worklog
saying the site was at the old domain on the day it was written is not made
wrong by the site moving later.

## Verification run

```
fvm dart run tool/generate_static.dart    pass, sitemap/robots regenerated
fvm dart format --set-exit-if-changed .   pass, 297 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

## Known issues left open

- **Pages is not yet enabled** on the new repo. Needs Admin, which the owner
  has not granted; he can either enable it himself (Settings → Pages →
  Source → GitHub Actions) or grant Admin so it can be done here.
- **The Cloudflare Worker's `SITE_ORIGIN`** still points at the old domain.
  A prompt for Codex, who has Cloudflare access, is provided separately.
- **The old repository's fate is undecided** — left exactly as it was,
  still serving, until the owner says what happens to it.
- **Every external link to the old domain** (CV, Linktree, LinkedIn, Medium)
  is unchanged; those are the owner's to update.
