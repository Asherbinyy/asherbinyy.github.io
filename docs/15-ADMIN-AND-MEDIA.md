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
   ├──▶ Cloudflare Worker  /v1/content   published overrides, JSON  (KV)
   │                       /v1/media/*   images                      (KV)
   │
   └──▶ Cloudflare Worker  /admin        the panel, auth-gated
                           /v1/admin/*   write endpoints
```

**Why Cloudflare and not something else.** The Worker already exists, is already
deployed, already has a KV namespace bound, and is already the origin the site
talks to for the writing feed and article covers. Adding a second service would
mean a second thing to keep alive for no gain.

**Why KV and not R2.** R2 is the obvious choice for object storage and it is
rejected on purpose: enabling it requires a payment card on the Cloudflare
account even though the free tier bills nothing, and the owner asked for
whichever path involves least faff. KV needs no card, is already bound, and
holds values up to 25MiB, which is comfortably more than any screenshot.

**Video is the exception.** A real video does not fit in KV and should not.
Video is referenced by URL rather than uploaded: YouTube or Vimeo, embedded
behind a click-to-load poster the way City Loom's prototype already is. That
keeps the owner off a hosting bill and keeps a heavy asset off the first paint.
If he later wants self-hosted video, that is the point at which R2 and its card
become worth revisiting, and not before.

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

**Auth is real.** One owner, confirmed: a single long random token, a session
cookie, and a rate limit. No accounts, no roles, no invitations, because there
is exactly one person who will ever write here and building for more would be
inventing a requirement. What is not proportionate in the other direction is a
public write endpoint.

**Media is validated at the edge.** Content type on an allowlist, hard size cap,
dimensions read and rejected if absurd. An upload endpoint that accepts anything
is a free file host with the owner's name on it.

---

## 4. Tasks

### 7.1 The content source — **done**, both halves
Remote read in `ContentRepository`, behind the existing `ContentResult`, with
the bundle as fallback. **Done when:** killing the Worker changes nothing a
visitor can see, and a malformed remote document is rejected by the same parser
that guards the bundle.

Shipped. `RemoteReader` is optional on the repository, every read is timed out
at two seconds, and every failure -- a dead service, a slow one, a document
that will not parse, one that parses to the wrong shape -- returns the shipped
document. `remote_content_test.dart` walks each of those failures, and
`bootstrap_test.dart` proves it against the real production wiring, where the
test environment's refusal of outbound HTTP stands in for the Worker being
down.

A malformed override falls back to the **bundle**, not to `fallback.json`. The
task said "rejected by the same parser", which it is, but degrading a bad
override all the way to the minimum profile would make publishing a typo worse
than never publishing at all.

**One thing worth knowing before touching this.** `lib/content/providers.dart`
is a generated library and `publishedContentProvider` is declared there as null,
then overridden in `bootstrap.dart`. That is not indirection for its own sake:
importing the HTTP-speaking reader into that library pulls `package:http` into
the summary `riverpod_generator` writes, and the pinned analyser is older than
the language version parts of that graph use. It crashes, and it crashes while
reporting an unrelated file, which costs an hour to work out. The seam also
happens to be the right shape, since it lets a test build a bundle-only
repository by doing nothing.

`relayEndpointProvider` moved from the writing feature to `lib/core/net/relay.dart`
in the same change. The content layer needs it and cannot reach into a feature
for it, and it was never a writing concern.

**The server half.** `GET /v1/content/<file>` reads a published document from
KV, `PUT` and `DELETE` under `/v1/admin/content/` write and withdraw it, and
`GET /v1/admin/content` lists what is live. Only the five documents on an
allowlist can be addressed: the path segment reaches KV, so without it an admin
request could read or write any key in the namespace, including the analytics
counters that share it. A document is parsed before it is stored, so publishing
something broken is refused at the door rather than served to the site and
silently rejected there.

The `CONTENT` namespace is optional and commented out in `wrangler.toml` until
the owner creates it. Until then the Worker deploys and behaves exactly as it
did: reads 404, writes answer 503, and the site uses its bundle.

### 7.2 Media storage — **done**
A second KV namespace, `/v1/media/*` read path, long cache headers, and the
allowlist and size cap above. Images only; video is a URL. **Done when:** an
image dropped in appears on the site without a deploy, and an oversized file,
an SVG and an HTML file are all refused.

Shipped. `POST /v1/admin/media` takes PNG, JPEG or WebP up to 4MiB;
`GET /v1/media/<id>` serves it; `DELETE` removes it and `GET /v1/admin/media`
lists what is stored with its dimensions.

**Validation is on the bytes, not on the claim.** `measureImage` reads the real
container header and returns the format and dimensions, so a script renamed to
`.png` and posted as `image/png` is refused on what it is. An SVG is refused
outright at the type allowlist, because it is markup that can carry script and
accepting it would be stored XSS on the owner's own domain. Dimensions are
bounded at both ends: the floor rejects tracking pixels and decode failures
that report 1x1, the ceiling rejects a decompression bomb before a browser ever
sees it.

**Ids are content hashes.** The same image uploaded twice is one key, and a
`/v1/media/<id>` URL can never come to mean different bytes, which is what
makes the one-year immutable cache honest rather than a bet. Replacing an image
produces a new id, so nothing stale is ever served.

**Media reads are the one thing here that is not origin-gated**, and that is
deliberate: images are fetched by ordinary image elements, which send no Origin
header, so gating them would refuse the only way they are ever loaded. There is
nothing to protect — this is public artwork on a public site behind an
unguessable name.

The media lives in the same `CONTENT` namespace under its own key prefix. The
task said a second namespace; one namespace with two prefixes has the same
isolation from the expiring analytics keys, and it is one thing for the owner to
create rather than two.

### 7.3 Auth — **done**
Token issue, verification, rate limit, and a way to revoke. **Done when:** an
unauthenticated write returns 401, a wrong token returns 401, and the token can
be rotated without a code change.

Shipped with the write endpoints. `ADMIN_TOKEN` is a separate secret from
`CONSOLE_TOKEN` and a test asserts the console token does **not** open the admin
endpoints: one is handed to a dashboard that reads counters, the other can
rewrite what the site says about the owner. Rotation is `wrangler secret put`
again, with no code change, which is also how revocation works.

Ten failed attempts in an hour and the endpoint stops answering, including to
the correct token, because the guarantee is that it stops rather than that it
keeps a door open. A correct token never counts against the limit.

The write endpoints are deliberately **not** origin-gated. The panel is served
by the Worker, not by the site, so an Origin check would reject the only client
meant to reach them. The token is the guard and it is checked before any body
is read.

**The read path is origin-gated and the write path is not, which is the right
way round.** A read is the site asking for its own content back; a write is the
owner, from somewhere else entirely.

### 7.4 The panel
Served at `/admin` from the Worker. Plain HTML and a little JavaScript, not a
framework: it is a form over a JSON document, it is used by one person, and it
must not become a second frontend to maintain.

**It edits everything** on the owner's instruction: projects, career, education,
interests and profile. Career and education carry a warning in the editor, since
those are the claims a recruiter cross-checks against a CV, and the provenance
requirement in 7.5 applies to them most of all.

Editing, reordering, image upload with a preview, and a diff against what is
live before publishing. **Done when:** the owner can add a project with a
screenshot, reorder the ledger, and publish, from a phone, without an agent.

### 7.5 Provenance in the editor
Required source field on any numeric claim, and the ledger test extended to
remote content. **Done when:** a figure cannot be published without a source.

---

## 5. What this costs

Free, on Cloudflare's free tier, with **no payment card anywhere**: Workers
100k requests a day, KV 100k reads and 1k writes a day, 1GB of storage and
25MiB per value. A portfolio edited a few times a month will not approach any
of those.

The real cost is that the site gains a moving part it did not have. That is why
§3 exists, and why the fallback is the first task rather than the last.

---

## 6. Decided

| # | Question | Answer, 2026-09-08 |
|---|---|---|
| 6.1 | R2 needs a card on file. Acceptable? | **No.** KV instead, images only. Video is a URL. |
| 6.2 | Should the panel edit career and education too? | **Everything.** With a warning on the two a recruiter cross-checks. |
| 6.3 | Does anyone else need access? | **No.** One owner, one token, forever. |
