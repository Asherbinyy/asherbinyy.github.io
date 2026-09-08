# Admin and Media — Milestone 7

The owner needs to add and remove content, and upload images and video, without
an agent and without editing JSON by hand.

Nothing here is built yet. This file is the specification.

---

## 1. The problem, stated honestly

Content lives in `assets/content/*.json` and is **compiled into the bundle**.
That was the right call and `00-PROJECT-BRIEF.md` §7 still holds: content
changes a handful of times a year, and a CMS would have cost a large share of
the build to solve a problem that editing a file already solved.

It stopped being true for two reasons.

**Media.** Screenshots, project videos and photographs cannot go in a JSON file,
and committing them means a rebuild and a deploy for every image.

**The owner is not the only editor any more.** He wants to add a project at
11pm from a phone without opening an editor, and that is a reasonable thing to
want from his own site.

So the site needs a second content source that is read at runtime, without
giving up the first. **Bundled content stays the fallback.** If the admin
service is down, misconfigured or deleted, the site renders exactly what it
renders today. That is not a nicety: it is the difference between a portfolio
that can break while he is asleep and one that cannot.

---

## 2. Shape

```
Browser ──▶ GitHub Pages (the site, unchanged)
   │
   ├──▶ Cloudflare Worker  /v1/content   published overrides, JSON
   │                       /v1/media/*   images and video
   │
   └──▶ Cloudflare Worker  /admin        the panel, auth-gated
                           /v1/admin/*   write endpoints
```

**Why Cloudflare and not something else.** The Worker already exists, is already
deployed, already has a KV namespace bound, and is already the origin the site
talks to for the writing feed and article covers. Adding a second service would
mean a second thing to keep alive for no gain. R2 gives object storage on the
same free tier for the media.

**What the site does with it.** `ContentRepository` gains a remote source that
is tried first and falls back to the bundle on any failure, any timeout, or any
document that does not parse. The parser is unchanged and still validates
everything, so a malformed remote document is rejected exactly as a malformed
bundled one is.

---

## 3. Non-negotiables

These are the rules that stop an admin panel becoming the weakest part of a
site whose whole argument is care.

**The site must render with the service dead.** Every remote read is wrapped,
timed out at two seconds, and falls back. A visitor must never see a spinner
that resolves to nothing, and never a blank page.

**Nothing about a visitor is collected.** The admin path must not become the
back door through which this site starts logging people. `06-ANALYTICS-AND-PRIVACY.md`
outranks this whole milestone.

**Provenance survives.** `14-PROVENANCE.md` requires a source for every claim.
A number typed into a panel at midnight is still a claim, so the editor carries
a required source field on any figure, and the ledger test extends to remote
content rather than only the bundle.

**Auth is real.** A single owner, a long random token, and a rate limit. It is
one person's portfolio, so a session cookie and a token in a KV namespace is
proportionate. What is not proportionate is a public write endpoint.

**Media is validated at the edge.** Content type on an allowlist, hard size cap,
dimensions read and rejected if absurd. An upload endpoint that accepts anything
is a free file host with the owner's name on it.

---

## 4. Tasks

### 7.1 The content source
Remote read in `ContentRepository`, behind the existing `ContentResult`, with
the bundle as fallback. **Done when:** killing the Worker changes nothing a
visitor can see, and a malformed remote document is rejected by the same parser
that guards the bundle.

### 7.2 Media storage
R2 bucket, `/v1/media/*` read path, cache headers, and the allowlist and size
cap above. **Done when:** an image dropped in appears on the site without a
deploy, and a 40MB file, an SVG and an HTML file are all refused.

### 7.3 Auth
Token issue, verification, rate limit, and a way to revoke. **Done when:** an
unauthenticated write returns 401, a wrong token returns 401, and the token can
be rotated without a code change.

### 7.4 The panel
Served at `/admin` from the Worker. Plain HTML and a little JavaScript, not a
framework: it is a form over a JSON document, it is used by one person, and it
must not become a second frontend to maintain. Editing, reordering, media
upload with a preview, and a diff against what is live before publishing.
**Done when:** the owner can add a project with a screenshot, reorder the
ledger, and publish, from a phone, without an agent.

### 7.5 Provenance in the editor
Required source field on any numeric claim, and the ledger test extended to
remote content. **Done when:** a figure cannot be published without a source.

---

## 5. What this costs

Free, on Cloudflare's free tier: Workers 100k requests a day, KV 100k reads a
day, R2 10GB and no egress fee. The site is a personal portfolio and will not
approach any of those.

The real cost is that the site gains a moving part it did not have. That is why
§3 exists, and why the fallback is the first task rather than the last.

---

## 6. What the owner still has to decide

| # | Question |
|---|---|
| 6.1 | Cloudflare R2 needs a card on file to enable, even on the free tier. Is that acceptable, or should media go somewhere else? |
| 6.2 | Should the panel be able to edit `career.json` and `education.json`, or only projects and media? Career claims are the ones a recruiter checks. |
| 6.3 | Does anyone else ever need access, or is one owner token enough forever? |
