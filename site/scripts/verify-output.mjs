import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadSnapshot, metadata, publicPages } from '../src/lib/content.mjs';

const output = fileURLToPath(new URL('../dist/', import.meta.url));
const snapshot = loadSnapshot();
const pages = publicPages(snapshot);
const manifest = JSON.parse(readFileSync(resolve(output, 'release.json'), 'utf8'));
const sitemap = readFileSync(resolve(output, 'sitemap.xml'), 'utf8');
const escape = value => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
assert.equal(manifest.revision, snapshot.revision);
assert.deepEqual(manifest.pages, pages.map(page => page.path));
for (const page of pages) {
  const html = readFileSync(resolve(output, `.${page.path}`, 'index.html'), 'utf8');
  const meta = metadata(page, snapshot);
  assert.equal((html.match(/<h1(?:\s|>)/g) ?? []).length, 1, `Single h1: ${page.path}`);
  assert.ok(html.includes('<main'), `Semantic body: ${page.path}`);
  assert.ok(html.includes(`lang="${page.locale}"`), `Language: ${page.path}`);
  assert.ok(html.includes(`dir="${page.locale === 'ar' ? 'rtl' : 'ltr'}"`), `Direction: ${page.path}`);
  assert.ok(html.includes(`<title>${escape(meta.title)}</title>`), `Title: ${page.path}`);
  assert.ok(html.includes(`content="${escape(meta.description)}"`), `Description: ${page.path}`);
  assert.ok(html.includes(`href="${meta.canonical}"`), `Canonical: ${page.path}`);
  assert.ok(html.includes('hreflang="en"') && html.includes('hreflang="ar"'), `Alternates: ${page.path}`);
  assert.ok(html.includes(`content="${snapshot.revision}"`), `Revision: ${page.path}`);
  assert.ok(sitemap.includes(`<loc>${meta.canonical}</loc>`), `Sitemap: ${page.path}`);
  const scripts = [...html.matchAll(/<script([^>]*)>/g)];
  assert.ok(scripts.every(([, attributes]) => attributes.includes('application/ld+json')), `No runtime required for content: ${page.path}`);
  assert.ok(!html.includes('flutter_bootstrap') && !html.includes('ADMIN_TOKEN'), `No app/admin bootstrap: ${page.path}`);
  if (page.kind === 'project') {
    const app = snapshot.documents['apps.json'].apps.find(app => app.id === page.id);
    assert.ok(html.includes(escape(app.name)), `Actual project title: ${page.path}`);
    if (app.role) assert.ok(html.includes(escape(app.role[page.locale] || app.role.en)), `Actual role: ${page.path}`);
  }
  for (const [, href] of html.matchAll(/href="(\/[^"#?]*)"/g)) {
    const path = resolve(output, `.${href}`, href.endsWith('/') ? 'index.html' : '');
    assert.ok(existsSync(path), `Unresolved internal link ${href} in ${page.path}`);
  }
}
assert.ok(readFileSync(resolve(output, '404.html'), 'utf8').includes('noindex'));
console.log(`Verified ${pages.length} semantic pages, language pairs, internal links, metadata and one content revision.`);
