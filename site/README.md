# Public HTML foundation

Astro 7.3.2, Node 22.23.2. This isolated R1 slice renders Home, Work and all 14 existing projects in English and Arabic. It does not replace the production Flutter deployment yet.

From the repository root:

```bash
npm exec --yes --package=node@22.23.2 -- npm ci --prefix site
npm exec --yes --package=node@22.23.2 -- npm --prefix site test
npm exec --yes --package=node@22.23.2 -- npm --prefix site run build
npm exec --yes --package=node@22.23.2 -- npm --prefix site run preview
npm exec --yes --package=node@22.23.2 -- npm --prefix site run test:http
```

Preview: `http://127.0.0.1:4321`. Use `run dev` for editing. The CLI wrapper disables Astro telemetry; the pages add no visitor analytics or preference storage.

Astro preview runs in the background. Stop it from `site/` with `npm exec --yes --package=node@22.23.2 -- node scripts/astro.mjs preview stop`. Restart after a configuration change. `test:http` checks slashed and unslashed direct links plus missing-page responses; an optional origin follows `--`.

Build verifies all 32 public documents, internal links, per-route metadata, EN/AR alternates and a shared content revision. `public/assets/` is generated from an explicit asset list. No raw owner-content bundle is copied into the public output.

Default source: the existing five files under `assets/content/`. An explicit `PORTFOLIO_SNAPSHOT` points to a validated immutable snapshot; invalid input stops the build. `/release.json` acknowledges the built revision. [Snapshot and admin integration](../docs/23-ADMIN-INTEGRATION-REPLY.md).

The full route migration, real admin preview, deployment acknowledgement, remaining page designs and Egyptian scene assets are still open. CV/Brief links currently go to the existing published HTML documents. Missing Arabic UI translations for the skip link/error page use explicit English text; no new Arabic copy was invented.
