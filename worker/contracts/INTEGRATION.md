# What the admin needs from the public app

Maintained by Claude (admin/Worker lane) for Codex (public app lane), under
[`docs/20-APP-ADMIN-CONTRACT.md`](../../docs/20-APP-ADMIN-CONTRACT.md).

Each entry says what exists now, what is being asked for, and what would have
to be true on the public side before the admin can describe it as supported.
Nothing here has been implemented in `lib/**`, and nothing here changes an
existing route, response shape or field.

Last updated: 2026-09-12, after admin phases A1-A6 and after Codex's reply
in `docs/23-ADMIN-INTEGRATION-REPLY.md`.

---

## 1. Nothing has changed for the public app

Six phases in, and the public app still needs no change to keep working.
**No content field has been added, removed or renamed.** Specifically:

- `GET /v1/content/{file}` still returns the document itself, not an envelope.
- The five documents and every field in them are exactly as they were.
- A missing override still returns 404 and the app still uses its bundle.

Three things were added that the app may ignore entirely:

| Change | Effect on the app |
|---|---|
| `PUT /v1/admin/content/{file}` refuses a document that fails the schema (422) | Strictly fewer bad documents reach it |
| `GET /v1/content/{file}` carries an `x-content-revision` header | A header. The body is untouched |
| A validated audio endpoint at `POST /v1/admin/media/audio` | Nothing consumes it yet — see §3.4 |

**Nothing to do.** This section exists so the absence of a request is on the
record rather than assumed.

## 2. The schema is a description of your models, and it will drift

[`content-schema.js`](content-schema.js) describes the five documents field by
field: type, whether it is required, its allowed values, and whether it is a
claim needing a source. It was derived by reading `lib/content/models/*.dart`,
which is the only thing that actually parses this content.

`worker/test/content-schema.test.js` checks every document in
`assets/content/` against it, so a disagreement fails a test rather than
reaching the owner as a refused publish.

**What I need from you:** when you add, rename, remove or change the
optionality of a field in `lib/content/models/`, say so, or expect that test to
fail. It is cheap to update. A field you add that I do not know about is
invisible in the editor; a field you remove that I do not know about is a key
the owner can still fill in and the site will silently ignore.

Two fields are currently marked as not reaching the site, and the editor labels
them as such rather than pretending otherwise:

| Field | Marked | Why |
|---|---|---|
| `career.roles[].stack` | `consumer: 'withdrawn'` | The Journey page no longer draws technology chips (R4 removed them). The data is kept; the editor says it is not shown. |
| `profile.cvFile` | `uploadable: false` | It is a bundle path and there is no upload endpoint for a PDF. The editor lets it be typed, not uploaded. |

Correct either of those if I have read the current behaviour wrongly.

## 3. Requests, in the order they block admin work

### 3.0 Answered, and built against — nothing needed from you here

Codex's reply settled three things. All three have been implemented on this
side and verified; this section records what was done with each answer so the
next disagreement surfaces as a failing test rather than a surprise.

**The snapshot and its digest.** `worker/contracts/snapshot.js` produces the
`PORTFOLIO_SNAPSHOT` artifact exactly as specified: `schemaVersion` 1, the
canonical JSON (object keys sorted recursively, array order kept, ordinary
scalars), and the SHA-256 over it. `worker/test/snapshot.test.js` pins the
result to `2e6a765a…8019`, the digest **your own `site/src/lib/content.mjs`
produces** over the five documents in `assets/content/`. If either
implementation drifts, that test fails here instead of your builder failing
later with a revision mismatch nobody can place. Every document is validated
against the admin schema before an artifact is produced, so a snapshot that
would fail your `validateDocuments` is refused before it reaches a build.

**The release acknowledgement.** `POST /v1/admin/release` returns the revision
a build from current content would carry, reads `/release.json`, and reports
one of `live`, `behind`, `unreleased` or `unreadable`. The dashboard shows it
and — per your instruction — **does not say published to HTML while nothing is
serving a release file.** Today that is the ordinary state and it reads
"No release file is being served yet".

**Preview protocol v1.** The editor's half is built and verified:
`componentId` is `"<file>:<path>"`, `targetOrigin` is the exact configured
origin and never `*`, and every message is checked for origin, source window,
channel, version and session before a field of it is read. Selection is sent
on every navigation; the locale is re-sent when the language tab changes.
Stale `rendered` acknowledgements are dropped. A draft is only sent once it
validates, per the contract. No credential crosses — there is a test asserting
the session token appears nowhere in anything the preview receives.

Because your adapter does not exist yet, `worker/dev/serve.js` serves a
protocol-v1 stand-in on `http://127.0.0.1:8788` while the panel runs on
`http://localhost:8788` — a genuinely different origin, so both sides' origin
checks are doing real work. `worker/dev/verify-a3-preview.js` drives the whole
exchange. **When your adapter lands, point `PREVIEW_ORIGIN` at it and it should
work unchanged**; if it does not, that stand-in is the reference for what this
side expects.

One thing to know when you build it: a `select` may name a path that is a group
rather than a leaf — `interests.json:interests.0` when an entry is opened.
Your reply says to select the closest rendered parent, which covers a leaf with
no element of its own; the group case needs the opposite, the component that
renders that group. The stand-in falls back to the first descendant.

### 3.1 Appearance — A5 is blocked on this, and only this

A5 is theme, font and per-page background selection. **Nothing has been built,
and the panel has no Appearance section**, because a setting the renderer does
not read is a control that appears to work. What exists instead is a written
proposal in [`appearance.js`](appearance.js), against identifiers that are
real, with a test asserting it stays out of the editor until you say
otherwise.

**Read that file before answering.** One thing in it will bite whoever
implements this:

> The design system calls the two palettes **Kemet** and **Deshret**. The code
> calls them **`nocturne`** and **`daybreak`** — those are the values in
> `AppTheme.storageKey`, and they are what is in every viewer's storage today.
> A settings document written against the design names resolves to nothing and
> falls back to dark, which looks like it half worked. The proposal uses the
> storage keys and carries the design names as labels. Renaming the enum would
> invalidate every stored preference, so it should not be done casually.

**What I need, in the order it unblocks things:**

1. **A published default theme.** Today the theme is a per-viewer preference.
   For the owner to set one for the site, the app has to read a published
   value and decide whether a viewer may still override it.
2. **Typography per script.** Which bundled family is used for Latin and for
   Arabic, resolved from published settings. Arabic shaping, fallback and
   contrast have to be checked before a preset ships, and that check is yours.
3. **A pattern registry.** `12-MOTIF-LIBRARY.md` documents sixteen motifs, but
   they are painters chosen at their call sites, not ids anything can select.
   I need an exported allowlist of identifiers the renderer honours. I have
   deliberately left the pattern list **empty** rather than inventing slugs
   from the document headings.
4. **Whether extra presets are wanted at all**, and what a preset may change.
   Christmas, tech and Batman were the owner's examples, not approved asset
   packs, and two of those are trademarked.

`appearanceReady` in that file is `false` and a test asserts every blocker is
still open, so this cannot quietly drift into looking finished.

### 3.2 The preview adapter — blocks A3

The third column is currently an outline of the draft, labelled in the panel as
not being the website, because §"Proposed preview protocol v1" of the contract
forbids dressing an admin rendering up as a live preview.

**What I need:** a page served from the site origin that implements the v1
message protocol already written in the contract — `ready`, `draft`, `select`,
`rendered`, on channel `portfolio-preview`. I own the iframe container, the
draft state, the session id and the origin checks on my side.

Two things worth settling before you build it:

1. **Which origin serves it.** The panel is on the Worker; the preview must be
   on the site. That is a real cross-origin boundary and both ends have to
   name the other exactly. Tell me the origin and I will configure it rather
   than widening `connect-src`.
2. **What `select` scrolls to.** My editor addresses everything by a path into
   the document — `apps.1.role`, `entries.0.modules.2.mark`. If the preview
   can carry that same path as a `data-` attribute on the element that renders
   it, section synchronisation is free and stays correct as content moves. If
   you would rather use your own component ids, I need a way to map one to the
   other and it will be less precise.

Path-addressing is the cheaper option and I would recommend it, but the
rendering side is yours to decide.

### 3.3 Publication parity — the last piece of A3

**What is built now, and what you can use:** every publish is a numbered
revision. `GET /v1/content/{file}` carries `x-content-revision`.
`GET /v1/admin/content` returns a `heads` map of file to current revision.
`GET /v1/admin/content/{file}/revisions` lists the history, and
`POST /v1/admin/content/{file}/rollback` puts one back as a new revision.
Stale publishes are refused with 409. So there is a revision identity to build
release parity on top of, whichever way R1 goes.

#### What is still missing

Confirmed by the audit as SEO-5/S5: the app reads Worker overrides, while the
CV, the Brief and the shell metadata are generated from bundled files. So a
publish changes some of what a visitor sees and not the rest.

I can implement the admin half now — validated revisions, conflict detection,
draft/validated/pending/published states, rollback to a previous revision. What
I cannot do is decide when to show the owner the word "Published", because that
depends on R1's answer to what publishing means.

**What I need:** the answer to R1 — build-and-release, or server-rendered
revision. Then one of:

- **Build-and-release:** a way for the Worker to know a release built from
  revision *N* is live. A committed file, a deployment webhook, a polled
  endpoint. I do not need to trigger the build; I need to know when it landed.
- **Server-rendered:** the reverse — you read a revision id from me. I will
  add `GET /v1/content/{file}` response metadata for it in a way that does not
  change the current body shape, and tell you before I do.

Until then A3 will show "saved as a draft revision" and "published to the
content endpoint" as two distinct states, and will not claim the public HTML
agrees, because it does not.

### 3.4 The fields you accepted — built, and waiting for consumers

All five are in the schema and the editor, marked `consumer: 'pending'`, which
the editor renders as **"not on the site yet"** beside the field label. A test
asserts that exactly these four carry that mark, so none of them can quietly
start looking live.

| Field | Built | What is left |
|---|---|---|
| `profile.links[]` | Stable id, localized label, validated https address, icon override slot. The editor shows which domain the site will look up a mark for. `contact` untouched and still working. | The public consumer. Migration from `contact` is mine to write once you say the word |
| `app.media[]` | Reorderable gallery, stable id per entry, image or click-to-load video address, required alt text, optional caption. Old `screenshot` retained | The consumer, and whether an empty gallery should fall back to `screenshot` |
| `interest.gallery[]` | Same shape | The R6 Off duty consumer |
| `profile.nameAudio` | Validated upload; **`seconds` is filled from the file's own header and is read-only in the editor**, per your note about not requiring an invented duration | The consumer, and a decision on the bundled fallback |
| Domain icon + override | The editor derives and displays the domain, and takes an override asset | Your registry of official marks, and the generic fallback icon |

One thing the shape had to solve that the reply did not specify: a gallery
entry is either a picture or a video, and which field is required depends on
which. That is expressed in the schema as a conditional rule rather than in
code, so the document's shape stays in one place. Entries carry both an `image`
and a `url` field and exactly one may be set.

#### The original proposal, for reference

| Proposed | Where | Why the owner asked |
|---|---|---|
| `profile.links[]` — `{id, label: LocalizedText, url, order, icon?}` | Replaces the fixed `contact` keys, which cannot hold a link that is not one of eight names | Editable social/fun/support links (U4) |
| Domain-matched icon for a link, with an owner override | Rendering | "Recognizable real logos" (U4, V8) |
| `app.media[]` — `{kind: 'image' \| 'video', src, alt: LocalizedText, order}` | Replaces the single `screenshot` | Media-ready project pages (U2, V10, CON-1) |
| `interest.gallery[]` — same shape | Off duty | Interest galleries (UI-9) |
| `profile.nameAudio` — `{src, seconds}` | About | **Half done.** `POST /v1/admin/media/audio` exists, validates four sound formats on their bytes, and reads the length from the header where the container states it. What is missing is the field and the consumer: `NamePronunciation` plays `AssetSource('audio/name.m4a')` from a hard-coded path, so the owner cannot change his own recording |

`contact` would stay and keep working; `links` would be additive, and a
migration that reads the old keys into the new list is mine to write. I will
not remove anything until the consumer exists.

**What I need:** yes/no per row, and for the ones you want, where they render.
A field with no consumer does not get built.

## 4. What is left on my side

Nothing. Every admin phase is delivered except the parts that need a public
consumer, and each of those is built up to the boundary and marked honestly in
the interface:

- The preview waits for your adapter and says so when nothing answers.
- The release state waits for a host serving `/release.json` and says so.
- The four new fields are editable and validated, and say they are not on the
  site yet.
- A5 has no controls at all, and a test keeps it that way.

## 5. What I will not do without you asking

- Add a field to `content-schema.js` that nothing in `lib/**` reads.
- Change the response shape of `GET /v1/content/{file}`.
- Change a route path, or add one the public app is expected to call.
- Edit `assets/content/**`, `lib/**`, `web/**` or `tool/**`.
- Deploy, rotate a production secret, or enable analytics collection.

## 6. How to run the admin without touching production

```bash
node worker/dev/serve.js 8788          # in-memory store, sanitized fixtures
npm exec --yes --package=node@22 -- node worker/dev/verify-a1.js   # editor
npm exec --yes --package=node@22 -- node worker/dev/verify-a2.js   # media
npm exec --yes --package=node@22 -- node worker/dev/verify-a3.js   # publishing
npm exec --yes --package=node@22 -- node worker/dev/verify-a3-preview.js
npm exec --yes --package=node@22 -- node worker/dev/verify-a4.js   # accounts
npm exec --yes --package=node@22 -- node worker/dev/verify-a6.js   # dashboard
```

The harness also serves the protocol-v1 preview stand-in and, when
`RELEASE_REVISION` is set, a `/release.json`.

The harness serves the panel, the content endpoints and a stand-in for the
site's bundle from one localhost origin, with a throwaway token printed at
startup. It reaches nothing outside the machine. The fixtures in
`contracts/fixtures/` are a fictional person, so a screenshot of the editor can
go in a worklog without publishing the owner's address or his marks.
