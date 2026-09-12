# Semantic public-site foundation

Decision: 2026-09-12. The owner asked Codex to choose the best public-rendering approach. Use Astro 7.3.2 with Node 22.23.2, both verified before installation. The existing Flutter app stays available while public routes migrate. No production workflow switches in this increment.

## Why this approach

The public portfolio is primarily authored content with interactive scenes. Astro can emit the content, headings, links and metadata directly as HTML; the scene/game runtime becomes a progressive enhancement. This removes Flutter startup from the critical path for reading the owner's name and work. It does not guarantee a search ranking.

References: [Astro installation](https://docs.astro.build/en/install-and-setup/), [static routing](https://docs.astro.build/en/guides/routing/), [Google JavaScript SEO](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics).

## First deliverable

`site/` proves Home, Work and every actual project in English and Arabic. Use the existing localized owner content, bundled fonts and portrait; do not invent case studies, images or translations. Each page has its own title/description/canonical, language alternates and visible semantic body. Missing projects must return 404 in the preview server. Content remains readable with JavaScript disabled.

Verified locally: 32 generated public documents; 63 slashed/unslashed URL forms; three missing-page 404s; seven content/snapshot tests. Desktop and emulated phone captures cover both languages and palettes with JavaScript disabled. See [browser evidence](audits/2026-09-12/html-foundation/README.md).

This is R1's first public rendering increment, not the final Egyptian art direction or all migrated routes. Journey/About/Writing/game migration, richer media, release coordination and the real admin preview adapter remain subsequent work. Links to the existing CV/Brief use the current published documents during this isolated proof.

## Content and publication boundary

- Build from a single immutable snapshot containing the existing five content documents; default to the repository bundle for local development.
- An explicit snapshot must validate successfully; never silently fall back to different data during a release build.
- Stamp generated pages and the public release manifest with the same content digest. Do not fetch newer mutable overrides in the browser after loading that HTML.
- Do not include admin notes, bearer credentials or the raw full profile document in a client payload. Copy only explicitly referenced public assets.
- Server schemas, draft storage, auth and release coordination are Claude's scope. This increment supplies a public builder/consumer, not an alternative CMS.
- The preview message contract in `20-APP-ADMIN-CONTRACT.md` remains version 1. Astro selection does not mean its real draft adapter is implemented yet.

## Routing and rollout

Static pages use directory output and trailing-slash canonical URLs, including `/work/{id}/` and `/ar/work/{id}/`. Before launch, the host must resolve existing unslashed links to these documents, preserve existing public routes, and return real 404s for missing pages. Test the chosen host's behavior rather than relying on a development fallback.

Astro route matching uses `trailingSlash: 'ignore'` so current unslashed links also resolve in development/preview. The first `always` configuration returned 404 for those links during direct-response checks and was corrected. Canonicals continue to use the slashed form; production directory redirects remain a host-level acceptance check.

Keep the current production workflow unchanged until the full route/content revision integration passes. No host migration, production deployment, new analytics or credential changes are authorized as side effects.

## Styling and motion

The HTML foundation reuses the existing pigments and bundled font families. New HTML spacing/type/layout variables live in one token stylesheet; no existing Flutter token is changed. Baseline typography and navigation make the proof reviewable. R2 will establish the sourced architectural/relief imagery and entrance composition before those assets spread across the site.

Use semantic controls and visible focus. Native page transitions may enhance navigation; reduced motion disables them. Content never starts hidden while waiting for JavaScript or a cinematic.
