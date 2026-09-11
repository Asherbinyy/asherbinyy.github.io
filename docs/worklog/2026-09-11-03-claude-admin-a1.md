# 2026-09-11-03 — Admin A1: an editor built from a schema

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3, phase A1**
**Started from:** `6cfb1f1`, on `phase/reinnovation-admin` in the separate `nocturne-admin` checkout
**Previous worklog:** `2026-09-11-02-public-baseline-repairs.md`

## Goal

Deliver phase A1 of `docs/21-CLAUDE-ADMIN-HANDOFF.md`: replace the JSON-shaped
form with a real editing workspace — compact lists, a responsive
navigation/editor/preview layout, independent page drafts, stacked EN/AR tabs,
and accessible controls — and lay the schema foundation the rest of A2–A6 needs.
Worker only. No `lib/**`, no public content, no deployment.

## What changed

**A schema, because everything else was blocked on it.** `admin.js` drew a
control for each key a document happened to contain (A-F1). That cannot create
a field, cannot tell a URL from a caption, and cannot validate. So the first
thing built was `worker/contracts/content-schema.js`: all five documents
described field by field — type, requiredness, allowed values, ordering,
whether a field is a claim about the owner. It is derived from
`lib/content/models/*.dart`, which is the only code that actually parses this
content.

**One validator, on the server.** `worker/contracts/validate.js` checks a
document against that schema. The panel deliberately has no copy of it; it asks
`POST /v1/admin/validate` and draws the answer. `PUT /v1/admin/content/<file>`
now runs the same check and answers **422** with the failing paths, where before
it accepted anything that parsed as an object (A-F6) — so the panel could report
a successful publish for a document the app then discarded in favour of its
bundle.

**Claims are found by what a field is, not by its JavaScript type.** The old
panel asked for a source when a *number* changed. Every figure on this site that
matters is a string: `5+`, `50% retention lift`, `15,000+ downloads`. All of
them were silently publishable. The schema marks claim fields, so all of them
are caught now.

**The editor.** Sections down the left, editor in the middle, third column on
the right at desk widths; one column on a phone with the third column behind a
control in between. Long lists are compact rows that open into their own panel
with a breadcrumb back; short ones open in place. It is called Sherbini's
Portfolio.

**Independent drafts.** One draft per document, held while the owner moves
between sections. A section with unsaved work is marked in the list. Leaving the
page warns. `open(name)` overwriting the single draft (A-F2) is gone.

**Language.** English and Arabic are a stacked pair of tabs that switch the
whole panel, so a field's label is free to say what the field is rather than
"en" and "ar". Both drafts are kept, the other language is shown under each
field, Arabic is edited right to left, and neither language forces its direction
onto the other's text.

**Accessibility.** Every control has an id and an associated `<label>` or an
`aria-label` — the old panel drew labels associated with nothing (A-F5). Visible
focus ring, keyboard path through the language tabs, `aria-current` on the
section list, live region for status, 44px minimum tap targets on a phone.

**A way to actually check any of that.** `worker/dev/serve.js` runs the Worker
on localhost with an in-memory store, sanitized fixtures and a throwaway token.
`worker/dev/browser.js` speaks the Chrome DevTools protocol directly — no
automation package added. `worker/dev/verify-a1.js` signs in, types, navigates
away mid-draft and back, opens and reorders and removes list entries, switches
language, breaks a required field, publishes, and does it again at 1100px and
390px.

## Files touched

- `worker/contracts/content-schema.js` — created — the five documents, described once.
- `worker/contracts/validate.js` — created — the only validator; also claim collection and diffing.
- `worker/contracts/INTEGRATION.md` — created — what the admin needs from Codex, and what it will not do without being asked.
- `worker/contracts/fixtures/*.json`, `README.md` — created — a fictional person, valid against the schema, deliberately uneven.
- `worker/src/admin.js` — modified — now assembles the page from the modules beside it.
- `worker/src/admin/styles.js` — created — the stylesheet.
- `worker/src/admin/markup.js` — created — the static frame.
- `worker/src/admin/client-state.js` — created — drafts, network, schema walking.
- `worker/src/admin/client-fields.js` — created — one control per field kind.
- `worker/src/admin/client-app.js` — created — navigation, panel, outline, buttons.
- `worker/src/index.js` — modified — `/v1/admin/validate`, `/v1/admin/review`, schema check on publish, reference resolution, publishable files from the schema.
- `worker/test/content-schema.test.js` — created — 28 tests.
- `worker/test/admin-panel.test.js` — created — 18 tests.
- `worker/test/index.test.js` — modified — three tests published toy documents the app could never parse; they publish real ones now.
- `worker/dev/serve.js`, `browser.js`, `verify-a1.js` — created — the local harness and its browser run.
- `worker/README.md` — modified — how to run the harness, and what the validation boundary is.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — current state after A1 and an honest list of what is still missing.
- `docs/audits/2026-09-11-admin-a1/*.png` — created — 8 captures from the verification run.
- `docs/worklog/2026-09-11-03-claude-admin-a1.md` — created — this record.

## Decisions made

**The schema is data, not code, and it is one file.** The Worker imports it to
validate, the panel is handed it as JSON to draw the editor, and Codex can read
it as the written contract. Three consumers, one description. A second copy in
the browser is exactly the drift that produced A-F6.

**The panel does not validate.** It could, and it would feel faster. But the one
rule that has to hold is that the panel never calls something publishable that
the Worker would refuse, and the only way to guarantee that is to ask the thing
that decides. A round trip on blur costs nothing for one user.

**Controls come from the schema; emptying one removes the key.** That is what
makes a field the document has never contained editable. It also means tabbing
through the form does not ship a document full of empty strings.

**A key the site cannot read is an error, not a warning.** "Saved" for something
the app discards is the defect being closed, so an unknown key fails a publish
rather than being tolerated.

**References are checked against published content; the panel may declare what
it loaded.** When nothing is published the site falls back to a bundle the
Worker cannot read, so the panel — which has it — sends the identifiers it can
see, and that is used only to answer the panel's own question. A publish checks
KV alone. Considered having the Worker fetch the bundle itself and rejected it:
it puts a live network call in the publish path.

**Review compares against what the site is showing, which the panel may have to
supply.** Same reason, and marked `comparedWith: 'shipped'` when it came from
the panel rather than from KV. **This is advisory and must not be trusted when
the provenance rule is enforced in A3** — that has to compare against the
published copy or against nothing. Noted in the code at the point it matters.

**The third column is an outline of the draft and says so, in the panel.**
`20-APP-ADMIN-CONTRACT.md` forbids dressing an admin rendering up as a live
preview. It renders the draft's values, honestly labelled, and gives A3's real
adapter a container to replace.

**No package was added.** The browser driver speaks CDP over the WebSocket that
Node 22 already has. The Worker still has zero dependencies.

**Assumption, flagged for the owner:** "Stack EN/AR tab controls vertically" is
implemented as a vertical pair at desk and tablet widths and a horizontal pair
on a phone, where a stacked pair costs 88px of the scarcest dimension. The
substance of the request — one clear field context, both drafts kept, RTL
preserved — holds at every width. One CSS line reverses it if the owner meant
vertical everywhere.

## Tests

- Added: 28 in `content-schema.test.js` (schema/validator/claims/diff, including
  that every bundled document and every fixture validates clean), 18 in
  `admin-panel.test.js` (page structure, validate/review endpoints, publish
  rejection, reference enforcement).
- Modified: 3 in `index.test.js` — they published documents like `{name:
  'Ahmed'}` and `{overallMark: 75}`, which the schema check now refuses. They
  publish minimal real documents instead, which is a better test than the one
  they replaced. Nothing was skipped or deleted.
- Worker suite: **pass, 116 passing, 0 failing** (was 70).
- Browser verification: **pass, 27 of 27 checks**, `worker/dev/verify-a1.js`.
- Flutter suite: **pass, 666 passing, 0 failing** — unchanged, as expected from
  a Worker-only phase.
- Coverage delta: not measured.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 116 tests
node worker/dev/verify-a1.js               pass, 27/27 checks
```

This checkout needed `fvm flutter pub get` and `fvm dart run build_runner build
--delete-conflicting-outputs` first, exactly as the previous worklog warned:
generated Riverpod and Freezed outputs are gitignored and a fresh worktree does
not inherit them. Before running the generator, `analyze` reported 764 issues
including a genuine `Undefined name 'recruiterModeProvider'`. That was missing
codegen, not a defect, and it is worth knowing for whoever opens a new worktree
next.

Three checks failed on the first browser run and all three were fixed rather
than reinterpreted: publishing reported "nothing to publish" whenever no
override existed yet (the server was diffing against an empty KV), phone tap
targets on chip and language controls were 28–34px, and the assertion about a
cleared required field was written against the wrong message. Reading the
screenshots afterwards found two more the assertions had not: the other-language
line rendered as `شخص تجريبي:Arabic` because a whole paragraph was marked RTL,
and the outline laid English text out right to left in Arabic mode, putting full
stops in front of sentences. Both are bidi isolation, both fixed, both visible
in the captures.

## Known issues left open

- **The third column is not a preview of the site.** It is labelled as such in
  the interface. Blocked on the adapter requested in `INTEGRATION.md` §3.2.
- **Provenance is still not enforced at the Worker.** It records a note when one
  is sent and the panel now always asks for one, but a direct API call with the
  owner's token can still publish a changed claim without a source. Needs the
  revision store to have a baseline worth trusting (A3).
- **No revisions, no conflict detection, no rollback, no publish confirmation.**
  Two tabs editing the same document will still overwrite each other (A3).
- **No coordinated publication.** A publish changes the app and not the CV,
  Brief or metadata. Blocked on R1 (`INTEGRATION.md` §3.3).
- **Media is unchanged.** One image endpoint, one uploader per image field. No
  library, ordering, alt text, progress, retry, or audio path (A2).
- **Auth is unchanged.** Token in tab `sessionStorage`, no in-panel password
  change or logout, and failed attempts still share an hourly counter that can
  lock out the correct token (A4).
- **No theme, font or pattern controls (A5), and no analytics home (A6).**
- Verification is Chrome 152 headless at 1440×900, 1100×820 and 390×844 device
  emulation. Not a physical phone, and not Safari or Firefox.
- The panel has no automated screen-reader check. Labels, roles and focus were
  verified structurally and by keyboard, which is not the same thing.
- `docs/11-OPEN-ISSUES.md`, `docs/19-REINNOVATION-ROADMAP.md` and `CHANGELOG.md`
  were deliberately not edited: the contract gives Codex the central queue, and
  concurrent edits to it are how two agents produce a conflict. ADM-1 and the
  A-F1/F2/F4/F5/F6 halves of ADM-2/3/4 are addressed by this phase; the
  provenance half of ADM-4 is not.

## Next

**A2: content and media.** But `INTEGRATION.md` §3.4 asks Codex which of the
proposed fields — editable links with domain-matched logos, project media lists,
interest galleries, evidence attachments, name audio — get a public consumer and
where they render. A field with nothing reading it is the defect A1 just closed,
so the media library and the field-specific controls come first, and the new
component types follow the answer.
