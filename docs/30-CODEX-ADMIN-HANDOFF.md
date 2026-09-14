# Codex — the admin panel is yours

September 14, 2026. The owner has reassigned the admin panel to Codex. Claude
keeps the Flutter app and the Worker backend contracts.

## What the owner said

He opened the panel and rejected it. In his words: **too many flaws, nothing he
asked for was implemented including all the pages, it does not look connected to
the portfolio, and there are no stats and no graphs.** He also asked for any
AI-ish content or affectation to be removed and for the whole thing to look
professional.

Treat that as the brief. Do not treat the existing 280 passing Worker tests, the
136 browser checks or any prior "phase complete" note as evidence the panel is
acceptable — none of those measured whether it is usable or whether it looks
like it belongs to this site. It is not accepted.

## The three concrete failures

### 1. It does not look like the portfolio

The panel is a generic dark admin theme: `#121826` ground, grey pills, blue-grey
hairlines, system sans. The site it administers is an Egyptian architectural
piece — limestone and silt grounds, a single gold pigment reserved for the
person and for anything actionable, faience only as interaction feedback,
carnelian only for errors, carved ornament, Space Grotesk and IBM Plex.

Read `docs/01-DESIGN-SYSTEM.md` and `lib/app/theme/tokens.dart`. The palette
roles and the type scale are already solved and measured against WCAG by
`test/unit/app/theme/contrast_test.dart`. The admin should use the same
vocabulary so that opening it feels like going backstage at the same building,
not opening a different product.

**Do not invent a fifth hue.** Do not restyle the public site to match the
admin; the site's direction is the owner's and is settled.

### 2. The pages he asked for are not there

The owner's admin requests, from his own messages, are in
`docs/15-ADMIN-AND-MEDIA.md` and the R3/R8 sections of
`docs/19-REINNOVATION-ROADMAP.md`. What exists is a schema-driven editor for
five content documents plus a media library and an account page. What he asked
for and cannot find includes the per-page editing surfaces for every page of
the site, appearance controls, and a home dashboard that actually reports
something.

Go through his requests one at a time and build the pages. Where a control
cannot work yet because the public app does not consume the field, say so in
the interface — do not ship a control that silently does nothing.

### 3. No stats, no graphs

`/v1/admin/insights` exists and returns real aggregates, honestly labelled. The
home dashboard renders them as text and bar rows. He wants a dashboard.

Constraints that are not negotiable, because they are about not lying:

- Analytics collection is **disabled** in the published build. The dashboard
  must say so rather than drawing an empty chart that implies no visitors.
- Daily unique counts **cannot be summed** into weekly or monthly uniques. The
  identifier is salted with a salt that rotates at midnight. The honest
  multi-day figure is the busiest single day, and `worker/src/insights.js`
  already returns it with the reason attached.
- Do not seed, estimate or demo-fill any number.

Within those, build real charts. `docs/06-ANALYTICS-AND-PRIVACY.md` is binding.

## Remove the AI-ish affectations

The owner named one specifically and there are others of the same kind. These
are decorations that imitate a machine readout without reporting anything:

- **The 56px rail down the left edge** (`lib/app/chrome/app_rail.dart`), with
  the section name set vertically and a "standby" state indicator. Claude is
  removing this from the site; do not reproduce it in the admin.
- Fake telemetry vocabulary anywhere in the panel: "standby", "acquiring",
  "signal", "instrument", "telemetry" as user-facing words.
- Status text that narrates rather than informs.

Write plain, specific labels. A control says what it does; a status says what
happened.

## What is already solid, and should not be rebuilt

The backend is reviewed and tested and is Claude's lane. Build on it rather than
replacing it:

- **The content schema** (`worker/contracts/content-schema.js`) describes all
  five documents field by field and drives the editor. Extending it is how new
  fields appear; a test validates every bundled document against it.
- **Validation** is server-side and authoritative (`/v1/admin/validate`), so the
  panel can never report something publishable that the Worker would refuse.
- **Revisions, conflicts, rollback, provenance** work and are covered.
- **Auth**: sessions, an authentication generation, throttled admission.
- **The transactional store** (`worker/src/store.js`) — note its binding is
  deliberately commented out in `wrangler.toml`, so a deployment today runs
  unprotected and the panel says so. Leave that switch alone.

Coordinate any backend change through `worker/contracts/INTEGRATION.md`.

## Ground rules

- Branch from `phase/reinnovation-admin` at `edfd04c`. Do not merge to `main`.
- Do not deploy, change production bindings, rotate secrets, enable analytics
  collection, or touch the owner's content in `assets/content/`.
- Do not edit `lib/**`, `web/**` or `tool/**` — that is Claude's lane now.
- Run `node --test worker/test/*.test.js` and the four FVM checks.
- Show the owner actual browser captures of each page at desktop and phone
  before calling anything finished. Passing tests are not visual acceptance;
  that mistake is what produced the current state.

## Prompt

```text
You own the admin panel. The owner has rejected the current one: too many
flaws, none of the pages he asked for, it does not look connected to his
portfolio, and no stats or graphs. Read
/Users/sherbini/Flutter Projects/nocturne/docs/30-CODEX-ADMIN-HANDOFF.md first,
then docs/01-DESIGN-SYSTEM.md, docs/15-ADMIN-AND-MEDIA.md and the R3/R8
sections of docs/19-REINNOVATION-ROADMAP.md.

Rebuild the panel so it belongs to this site: the same palette roles, type
scale and material as the Flutter app, no fifth hue, no generic dark admin
theme. Build the pages the owner actually asked for, one at a time. Build a
real dashboard on /v1/admin/insights -- with charts -- while keeping every
honesty constraint: collection is disabled and must say so, daily uniques
cannot be summed into monthly uniques, and nothing may be seeded or estimated.

Strip the AI-ish affectations. No fake telemetry vocabulary, no vertical
section rail, no status text that narrates instead of informing. Plain,
specific, professional labels.

Do not rebuild the backend: the schema, server-side validation, revisions,
conflicts, provenance, auth and the transactional store are reviewed and
tested. Extend the schema to add fields. Route backend requests through
worker/contracts/INTEGRATION.md.

Branch from phase/reinnovation-admin at edfd04c. Do not edit lib/**, web/** or
tool/**, do not touch assets/content/**, do not deploy, enable analytics or
merge to main. Run the Worker suite and the four FVM checks, and show the owner
desktop and phone captures of every page before calling anything done. Passing
tests are not visual acceptance.
```
