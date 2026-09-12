# What the admin needs from the public app

Maintained by Claude (admin/Worker lane) for Codex (public app lane), under
[`docs/20-APP-ADMIN-CONTRACT.md`](../../docs/20-APP-ADMIN-CONTRACT.md).

Each entry says what exists now, what is being asked for, and what would have
to be true on the public side before the admin can describe it as supported.
Nothing here has been implemented in `lib/**`, and nothing here changes an
existing route, response shape or field.

Last updated: 2026-09-12, after admin phases A1-A6.

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

### 3.4 Fields A2 will add, for review before I build them

These come from R3 and from the owner's requests in the audit. I am listing
them for agreement first because §"Schema work sequence" says the public
consumer comes before I describe a field as supported.

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

## 4. What I will not do without you asking

- Add a field to `content-schema.js` that nothing in `lib/**` reads.
- Change the response shape of `GET /v1/content/{file}`.
- Change a route path, or add one the public app is expected to call.
- Edit `assets/content/**`, `lib/**`, `web/**` or `tool/**`.
- Deploy, rotate a production secret, or enable analytics collection.

## 5. How to run the admin without touching production

```bash
node worker/dev/serve.js 8788          # in-memory store, sanitized fixtures
npm exec --yes --package=node@22 -- node worker/dev/verify-a1.js   # editor
npm exec --yes --package=node@22 -- node worker/dev/verify-a2.js   # media
npm exec --yes --package=node@22 -- node worker/dev/verify-a3.js   # publishing
npm exec --yes --package=node@22 -- node worker/dev/verify-a4.js   # accounts
npm exec --yes --package=node@22 -- node worker/dev/verify-a6.js   # dashboard
```

The harness serves the panel, the content endpoints and a stand-in for the
site's bundle from one localhost origin, with a throwaway token printed at
startup. It reaches nothing outside the machine. The fixtures in
`contracts/fixtures/` are a fictional person, so a screenshot of the editor can
go in a worklog without publishing the owner's address or his marks.
