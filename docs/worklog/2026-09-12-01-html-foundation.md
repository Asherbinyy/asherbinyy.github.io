# 2026-09-12-01 — Semantic public HTML foundation

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** 615c6ce

## Goal
Choose the public rendering foundation after the owner delegated the decision, and deliver a reviewable first R1 increment while Claude works on admin. Make Home, Work and actual project content readable as HTML in both languages, with a consistent content revision.

## What changed
- Added an isolated Astro site: Home, Work and 14 project documents in English and Arabic, plus a noindex 404 document. Existing Flutter routes/deployment remain operational during migration.
- Each public document contains a semantic body, one main heading, per-route title/description/canonical, reciprocal language alternates, structured data and a content revision. Reused supplied content, portrait, fonts and CV; no invented case studies or translations.
- Added a fail-closed immutable snapshot consumer and public release manifest. The builder defaults to bundled documents only when no explicit snapshot is requested; a bad explicit revision cannot silently use different content.
- Copy an explicit public asset list into an ignored generated directory, clearing its previous contents so removed assets do not persist. Do not expose the raw profile/content bundle or admin credentials.
- Added baseline responsive layouts, current dark/light pigments, visible focus styles and reduced-motion handling for native page transitions. This is not the final Egyptian visual design.
- Browser inspection corrected SVG color inheritance, a mobile selector hiding the brand mark, and RTL date-range ordering. Direct HTTP verification corrected unslashed links returning 404 by selecting `trailingSlash: 'ignore'`; canonical URLs remain slashed.
- Read Claude's A1 integration note from the separate admin checkout and documented the response: build/release selection, snapshot shape, revision acknowledgement, field selection paths and additive media/link proposals. The actual preview adapter and production coordinator remain open.

## Files touched
- `site/package.json`, `site/package-lock.json`, `site/.node-version`, `site/astro.config.mjs` — created — isolated pinned frontend and static route configuration.
- `site/src/lib/content.mjs` — created — existing-content consumer, snapshot validation/digest, safe destinations, routes and metadata.
- `site/src/layouts/Page.astro` — created — semantic document, metadata, shared navigation and supplied mark.
- `site/src/components/ProjectCard.astro` — created — actual project content with future preview field hooks.
- `site/src/pages/[...page].astro` — created — EN/AR Home, Work and project documents.
- `site/src/pages/404.astro`, `release.json.js`, `robots.txt.js`, `sitemap.xml.js` — created — error document and public build endpoints.
- `site/src/styles/tokens.css`, `site/src/styles/site.css` — created — centralized HTML tokens and responsive base composition.
- `site/scripts/astro.mjs`, `prepare-assets.mjs` — created — CLI telemetry opt-out and explicit generated public assets.
- `site/scripts/verify-output.mjs`, `verify-http.mjs`, `site/test/content.test.mjs` — created — content/snapshot rules, built-document and served-response verification.
- `site/README.md` — created — exact setup/build/preview/check commands and migration limits.
- `.gitignore` — modified — exclude frontend dependencies, generated assets, build and Astro state.
- `README.md`, `CHANGELOG.md`, `docs/03-ARCHITECTURE.md`, `docs/11-OPEN-ISSUES.md`, `docs/19-REINNOVATION-ROADMAP.md` — modified — selected architecture and evidenced partial progress.
- `docs/22-HTML-FOUNDATION.md`, `docs/23-ADMIN-INTEGRATION-REPLY.md` — created — architecture and public/admin contract decisions.
- `docs/audits/2026-09-12/html-foundation/README.md` and seven PNGs — created — local no-JavaScript visual evidence.
- `docs/worklog/2026-09-12-01-html-foundation.md` — created — this record.

## Decisions made
- The owner answered the rendering-choice question with “idk do the best”. Selected Astro 7.3.2 after checking the registry/official documentation. Node 22.23.2 is isolated through `npm exec`; the machine's Node 20 is below Astro's supported minimum. No Flutter SDK or existing package was upgraded.
- Use build-and-release with a single immutable snapshot. The eventual deployed `/release.json` can acknowledge publication; a successful Worker save alone must not imply public HTML was published.
- Continue using the existing production domain. No production workflow, host, route replacement or deployment is included in this first slice.
- Legacy worklog milestone field remains 6; actual scope is the first increment of R1, not the complete milestone.
- Existing Flutter palette values are mirrored in HTML tokens and checked by a parity test. HTML-only spacing/type values are centralized; existing Dart token values are unchanged.
- Keep sparse projects sparse until real media/details exist. Existing optional role fields remain optional. Missing Arabic skip-link/error-page copy uses explicitly marked English fallback, not an invented translation.
- Claude retains exclusive ownership of Worker/admin implementation. The reply accepts proposed additive fields but explicitly marks public consumers, appearance presets and live preview as pending.

## Tests
- Added: seven Node tests covering route inventory, content-derived metadata, stable digests, fail-closed explicit snapshots, document/ID validation, safe URLs/assets/JSON encoding and Flutter palette parity.
- Modified: no existing Flutter/Worker tests. Added repeatable output and HTTP validation scripts.
- Full suite: pass, 676 Flutter passing, 0 failing; 7 Node passing, 0 failing. Worker unchanged; no new Worker suite result claimed.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 676 tests
fvm flutter build web --wasm               pass, build/web generated
```

Astro build passes and verifies 32 semantic documents, internal links, metadata, language pairs and one revision. HTTP checks pass 63 slashed/unslashed URL forms, three missing-page 404s and the served release manifest. Node tests run with the pinned Node runtime. No tests skipped or removed.

Initial failures were fixed: a test assumed every app had `role`; prerendering changed the runtime module path used to locate repository content; the first trailing-slash setting rejected existing links. The CLI initially printed its default telemetry notice; the checked-in wrapper now explicitly disables Astro CLI telemetry. No visitor analytics was added.

Rendered six page/viewport combinations in each palette with JavaScript disabled and reduced motion enabled. Inspected desktop, English/Arabic phone and project screenshots; no reported runtime exceptions or horizontal overflow. Captures are Chrome emulation only. Existing Material/Cupertino icon-font warning remains in the Flutter build. Native animated navigation and full keyboard/screen-reader acceptance remain R9 work, not certified by static captures.

## Known issues left open
- R1 is partial: Journey, About, Writing, game and CV/Brief revision integration still need migration. Current proof links CV/Brief to the existing published documents.
- Production still serves Flutter with the audited deep-link/semantic HTML problems. Local preview HTTP results do not certify GitHub Pages behavior or indexing; Search Console and name ranking are unverified.
- Snapshot artifact delivery, CI triggering, failure recovery, rollback, deployed release acknowledgement and real admin preview are not implemented by this increment.
- Appearance settings, flexible links and new galleries have documented contracts but no public consumer yet. No admin completion claim is made from reading Claude's note.
- R2 Egyptian architecture/reliefs, entrance, final visual motion and richer product presentation remain open; basic HTML layouts are not design sign-off.
- Physical phone/Safari, large text, full accessibility and performance profiling remain open. Some existing project details/media and Arabic UI copy are absent.

## Next
Build the R2 Home/entrance visual proof on the semantic foundation, with a sourced Egyptian material/composition direction, while Claude continues admin against the documented public contract.
