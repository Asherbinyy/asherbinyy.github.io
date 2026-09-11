# Claude handoff — all admin work

Prepared 2026-09-11 at the owner's request. Claude is not running yet; the owner will launch him separately. Codex continues the public app in parallel.

## Start here

Use the dedicated `phase/reinnovation-admin` worktree, not Codex's active checkout. Read `AGENTS.md`, [brief](00-PROJECT-BRIEF.md), the required design/architecture/standards and recent worklogs, then these current documents:

1. [Independent audit](18-REINNOVATION-AUDIT.md), especially admin findings A-F1–A-F11.
2. [Re-innovation roadmap](19-REINNOVATION-ROADMAP.md): own R3 and R8 admin/backend work, plus backend support for R1/R4–R7.
3. [App/admin contract](20-APP-ADMIN-CONTRACT.md): ownership, compatibility, proposed preview and publication protocols.
4. [Current admin state](15-ADMIN-AND-MEDIA.md) and [open issues](11-OPEN-ISSUES.md).

The older handover/backlog is historical. The new audit checked actual source conversations and four annotated screenshots. Do not re-ask whether real logos are allowed: the owner already requested them. Subscribers were cancelled. Keep the daily digest dormant. Codex handles game/navigation/rendering questions.

## Your scope

Own `worker/**`: admin design and implementation, content/media/auth endpoints, schemas/fixtures under `worker/contracts/`, Worker tests and operational documentation. Use the app/admin contract for shared changes. Do not edit `lib/**`, public `web/**`, public assets, owner's bundled content or Codex's working files. Send integration needs through a committed `worker/contracts/INTEGRATION.md` and your worklog, with exact proposed fields, endpoints and fixtures. Codex will implement the public consumers/preview adapter and integrate the changes.

All the following are required; deliver in reviewable phases with real browser evidence:

| Phase | Deliverable and acceptance |
|---|---|
| A1: editing foundation | Replace giant cards with compact item lists and a responsive navigation/editor/preview layout. Remove Nocturne from visible admin branding. Preserve independent page drafts across navigation. Stack EN/AR tab controls vertically, retaining values and RTL context. Accessible field labels, focus and keyboard behavior. |
| A2: content and media | Supported custom components/fields, editable links with domain-matched logos and overrides, add/reorder/remove stats, countries, journey stops, projects, education/evidence and interests. Media library with field-specific upload controls, gallery ordering, alt text, progress/retry and dedicated name-audio support. Never invent owner data. |
| A3: preview and publishing | Real public preview integration through the contract; section selection synchronizes preview. Page-specific save, before/after confirmation, cancel, retained drafts, schema/claim validation, revision conflicts and publication state. No claim that publishing is complete until HTML and app revisions agree. |
| A4: account controls | In-panel password change, logout, stale-session handling and corrected shared-lockout behavior. No Cloudflare account credential in browser. Local/test verification before any production rotation. |
| A5: customization | Preserve Kemet/Deshret; extra theme choices, font selection, per-page background/pattern controls, preview and reset. Coordinate allowlisted renderer IDs with Codex; unsupported options must not appear to work. |
| A6: analytics home | Clear home dashboard, dates/ranges, available visits and interactions, useful empty/error states. Accurate aggregate labels. Existing collection is disabled; implement against fixtures/available data without activating tracking or inventing counts. |

R3/R8 tasks and the request-by-request matrix remain the acceptance inventory; this table is not a reduced replacement. Do not stop after cosmetic form restyling.

## Defects to account for

- `admin.js` is shape-driven, but cannot create arbitrary object fields with actual public consumers. Five documents are supported.
- Switching `open(name)` discards the draft. Publishing already targets one document; the missing parts are independent drafts and page-specific review/confirmation.
- Upload detection guesses from leaf key names and misses nested `portrait.src` / `evidence.src` and absent project-gallery properties.
- Publish validates JSON/plain-object shape, not the real schema. Provenance checks miss numeric claims in strings. Invalid notes must not fail after changing live content.
- Token is currently in `sessionStorage`, not the cookie described by old docs. Shared hourly failures can lock out the correct token too.
- Media accepts images only. Do not pass audio through the image endpoint or silently allow arbitrary active files.
- Current static CV/Brief and metadata do not consume the same remote revision as the app.
- Existing dashboard data cannot prove every desired target breakdown or cross-day unique count.

## Verification and reporting

Baseline: 70 Worker tests and 666 Flutter tests passed in the audit, with passing FVM format/analyze/Wasm build. They do not prove admin usability. The captured admin image used local fixtures, not production authentication.

Use isolated content and credentials. Exercise add/edit/reorder/delete, EN/AR switching, page switching, uploads/failures, preview synchronization, cancel, publish, stale edits, auth errors and compact layouts in an actual browser. Tests should verify behavior and validation rules, not copy spellings. Do not publish, rotate production secrets, enable analytics or merge to `main` as a side effect.

Run `node --test worker/test/*.test.js` and the repository's four FVM checks before claiming an integrated phase finished. If a separate worktree cannot run a check, record the precise limitation; never copy Codex's passing result as your own. Write a unique `docs/worklog/YYYY-MM-DD-NN-claude-admin-<phase>.md` following the required template. Include files, schema changes, screenshots, test results and unresolved public integration dependencies. Commit coherent phases on the admin branch and leave deployment to the owner.

## Prompt the owner can paste

> You own all admin-panel and Worker backend work. Codex owns the public app, SEO, visuals, animation and game concurrently. Work only in the dedicated admin worktree on `phase/reinnovation-admin`. Read `docs/21-CLAUDE-ADMIN-HANDOFF.md` and `docs/20-APP-ADMIN-CONTRACT.md`, then the linked audit/roadmap and required repository docs. Deliver admin phases A1–A6 one at a time, document and visually verify each, and coordinate shared schemas through `worker/contracts/INTEGRATION.md`. Do not edit Codex's checkout, change public content without coordination, deploy, enable tracking or merge to main. Begin with the current code audit and A1; prepare concrete schema proposals alongside it.
