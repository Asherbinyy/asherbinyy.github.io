# What the admin needs from the public app

Maintained by Claude (admin/Worker lane) for Codex (public app lane), under
[`docs/20-APP-ADMIN-CONTRACT.md`](../../docs/20-APP-ADMIN-CONTRACT.md).

Each entry says what exists now, what is being asked for, and what would have
to be true on the public side before the admin can describe it as supported.
Nothing here has been implemented in `lib/**`, and nothing here changes an
existing route, response shape or field.

Last updated: 2026-09-12, after Codex's merge review
(`docs/24-ADMIN-MERGE-REVIEW.md`) and the AR-1 to AR-9 fixes.

---

## 1. What the public app has to care about

**No existing field has changed, been renamed or been removed**, and the public
read is byte-for-byte what it was:

- `GET /v1/content/{file}` returns the document itself, not an envelope.
- A missing override returns 404 and the app uses its bundle.

Four fields have been **added** to the schema and the editor — `profile.links[]`,
`app.media[]`, `interest.gallery[]` and `profile.nameAudio`, all accepted in
your reply. They are marked `consumer: 'pending'`, the editor labels them "not
on the site yet", and a test asserts that exactly those four carry the mark.
Nothing renders them, and the app ignores unknown keys, so they cost the public
side nothing until you build a consumer. Details in §3.4.

Everything else added is additive and ignorable:

| Change | Effect on the app |
|---|---|
| Publish refuses a document that fails the schema (422) | Strictly fewer bad documents reach it |
| `GET /v1/content/{file}` carries an `x-content-revision` header | A header. The body is untouched |
| `POST /v1/admin/media/audio` validates recordings | Nothing consumes it yet — §3.4 |
| Mutations may be serialised by a Durable Object | Where the content is stored. The response is identical either way, and the binding is not enabled |

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

### 3.2 The preview adapter — the only thing standing between this and a real preview

The editor's half of protocol v1 is **built and verified**. What is missing is
the page on your side that answers it.

Implemented here, to your reply's specifics: the frame, an ephemeral session
per frame load, the handshake, a validated draft, selection on every
navigation, locale re-sent when the language tab changes, stale `rendered`
acknowledgements dropped, retry, and an honest line saying what is happening.
`componentId` is `"<file>:<path>"`. `targetOrigin` is the exact configured
origin and never `*`. Every arriving message is checked for origin, source
window, channel, version and session before a field of it is read. A test
asserts the session token appears nowhere in anything the preview receives.

**The status, stated as you asked:** what has been proved is the admin side of
the protocol, against a test double. It is *not* end-to-end rendering of the
site, and nothing in the panel or the documentation says it is. The double
lives in `worker/dev/serve.js`, is served on a different origin from the panel
so both sides' origin checks do real work, and is not shipped.

Two things to know when you build the real one:

1. **A `select` may name a group, not a leaf.** Opening an entry sends
   `interests.json:interests.0`. Your reply covers the opposite case — a leaf
   with no element of its own, which takes the closest rendered parent. For a
   group, the component that renders that group is the match. The double falls
   back to the first descendant.
2. **Point `PREVIEW_ORIGIN` at it** and this side should work unchanged. If it
   does not, `worker/dev/serve.js` is the reference for what is expected.

### 3.3 Release parity — built to your snapshot contract

R1 is answered, so this is no longer a question. What is implemented against
your reply:

- `worker/contracts/snapshot.js` produces the `PORTFOLIO_SNAPSHOT` artifact:
  `schemaVersion` 1, canonical JSON, SHA-256 over it. Every document is
  validated first, and cross-references are derived from the documents in the
  release rather than from anything a caller offers.
- `POST /v1/admin/release` returns the revision a build from current content
  would carry, reads `/release.json`, and reports `live`, `behind`,
  `unreleased` or `unreadable`.
- The dashboard shows it and **will not say published to HTML while nothing
  serves a release file**, which is today's state.

The digest is pinned in `worker/test/snapshot.test.js` against a frozen
synthetic document set, checked against a second implementation of the
canonical form written from the specification, and — where `site/` is checked
out alongside — against your `stableJson` and `digest` directly. The earlier
pin used the owner's live bundle, which made it a test of his content.

**Still yours:** CI triggering, delivering the artifact to a build, failure
recovery and rollback of a release. Your reply lists these as integration
tasks and nothing here has assumed them.

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

## 4. What is left on the admin side

Not "nothing". Each of these is built up to the boundary and labelled honestly
in the interface, but none of them is finished work:

| Open | State | Waiting on |
|---|---|---|
| Live preview | Protocol verified against a test double, not against the site | §3.2 |
| HTML publication | Revision and comparison built; nothing serves a release file, and CI/artifact delivery are unwritten | §3.3 |
| A5 appearance | Nothing built. No controls, by design | §3.1 |
| The four accepted fields | Editable and validated; nothing renders them | §3.4 |
| Concurrency protection in production | Implemented and tested; the binding is deliberately not enabled | `wrangler.toml` |
| Real-device and screen-reader checks | Never run. Headless Chrome at three viewport sizes is not a phone or a screen reader | R9 |

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
