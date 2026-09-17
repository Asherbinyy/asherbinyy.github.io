/**
 * The panel the owner edits the site from.
 *
 * Assembled here from the modules beside this file, and served as one HTML
 * string. It stays a single inline document rather than a bundle of fetched
 * scripts because the panel's content-security-policy allows inline script
 * and nothing else, and this is the one page in the project that most needs
 * to be unable to load anything from anywhere.
 *
 * What changed in phase A1, against `21-CLAUDE-ADMIN-HANDOFF.md`:
 *
 * - Controls come from `worker/contracts/content-schema.js` rather than from
 *   whichever keys a document happened to contain, so a field can be added
 *   where the document has never had one.
 * - One draft per document, kept while the owner moves between sections.
 * - Sections, editor and outline are three columns on a desk and one on a
 *   phone; long lists are rows that open, not stacked forms.
 * - English and Arabic are a stacked pair of tabs, switching the whole panel,
 *   with the other language always visible underneath each field.
 * - Every control has a real label, an id, a focus ring and a keyboard path.
 * - Validation is the Worker's, asked for over `/v1/admin/validate`, so the
 *   panel cannot call something publishable that the Worker would refuse.
 *
 * Still open, and deliberately not pretended otherwise in the interface: the
 * right-hand column is an outline of the draft rather than the site (A3), the
 * media library and per-field media controls are A2, and the token still
 * lives in `sessionStorage` with no in-panel rotation (A4).
 */

import {documents, knownCountries} from '../contracts/content-schema.js';
import {clientAccount} from './admin/client-account.js';
import {clientPages} from './admin/client-pages.js';
import {clientCharts} from './admin/client-charts.js';
import {clientApp} from './admin/client-app.js';
import {clientFields} from './admin/client-fields.js';
import {clientHome} from './admin/client-home.js';
import {clientMedia} from './admin/client-media.js';
import {clientPreview} from './admin/client-preview.js';
import {clientPublish} from './admin/client-publish.js';
import {clientState} from './admin/client-state.js';
import {brandName, countryList, markup} from './admin/markup.js';
import {styles} from './admin/styles.js';

/// Where the shipped documents live.
///
/// Flutter nests its asset directory inside its own asset root, which is why
/// this path says `assets` twice. Overridable so the panel can be run against
/// a local harness without reaching the published site.
export function adminPage(env) {
  const siteOrigin = typeof env === 'string' ? env : env.SITE_ORIGIN;
  const bundleBase = (typeof env === 'string' ? null : env.BUNDLE_BASE) ??
    `${siteOrigin}/assets/assets/content`;
  // Where the preview adapter lives. The production public origin by default;
  // a separate development origin is configuration, not a default.
  const previewOrigin = (typeof env === 'string' ? null : env.PREVIEW_ORIGIN) ??
    siteOrigin;

  // Only what the panel needs to draw itself. The schema is data, so it is
  // handed over as JSON rather than as script.
  const schema = JSON.stringify({documents, knownCountries});

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="robots" content="noindex, nofollow">
<title>${brandName}</title>
<style>${styles}
</style>
</head>
<body class="locked">
${markup}
<datalist id="knownCountries">${countryList(knownCountries)}</datalist>
<script type="module">
const SITE = ${JSON.stringify(siteOrigin)};
const BUNDLE = ${JSON.stringify(bundleBase)};
const PREVIEW_ORIGIN = ${JSON.stringify(previewOrigin)};
const SCHEMA = ${schema};
${clientState}
${clientFields}
${clientMedia}
${clientPreview}
${clientPublish}
${clientAccount}
${clientCharts}
${clientPages}
${clientHome}
${clientApp}
</script>
</body>
</html>`;
}
