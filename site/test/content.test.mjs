import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { assetUrl, digest, loadSnapshot, metadata, publicPages, repositoryRoot, safeJson, safeUrl, validateDocuments } from '../src/lib/content.mjs';

test('one actual project per locale, with unique public paths', () => {
  const snapshot = loadSnapshot();
  const pages = publicPages(snapshot);
  const apps = snapshot.documents['apps.json'].apps;
  assert.equal(pages.length, (apps.length + 2) * 2);
  assert.equal(new Set(pages.map(page => page.path)).size, pages.length);
  for (const app of apps) {
    assert.ok(pages.some(page => page.path === `/work/${app.id}/`));
    assert.ok(pages.some(page => page.path === `/ar/work/${app.id}/`));
  }
});

test('metadata describes the same content revision and project as the route', () => {
  const snapshot = loadSnapshot();
  for (const page of publicPages(snapshot)) {
    const meta = metadata(page, snapshot);
    assert.equal(new URL(meta.canonical).pathname, page.path);
    assert.equal(meta.schema.inLanguage, page.locale);
    assert.ok(meta.title.includes(snapshot.documents['profile.json'].name[page.locale]));
    if (page.id) {
      const app = snapshot.documents['apps.json'].apps.find(app => app.id === page.id);
      assert.ok(meta.title.includes(app.name));
      assert.ok(meta.description.includes(app.role?.[page.locale] || app.role?.en || app.domain));
    }
  }
});

test('digest is stable across object key order and changes with content', () => {
  assert.equal(digest({ b: 2, a: 1 }), digest({ a: 1, b: 2 }));
  assert.notEqual(digest({ a: 1 }), digest({ a: 2 }));
  assert.notEqual(digest([1, 2]), digest([2, 1]));
});

test('explicit snapshot validation fails closed instead of mixing in the bundle', () => {
  const directory = mkdtempSync(join(tmpdir(), 'portfolio-snapshot-'));
  try {
    const file = join(directory, 'snapshot.json');
    const snapshot = loadSnapshot();
    writeFileSync(file, JSON.stringify(snapshot));
    assert.equal(loadSnapshot(file).revision, snapshot.revision);
    snapshot.documents['profile.json'].name.en = 'Fixture change';
    writeFileSync(file, JSON.stringify(snapshot));
    assert.throws(() => loadSnapshot(file), /revision mismatch/);
    writeFileSync(file, '{bad json');
    assert.throws(() => loadSnapshot(file));
    assert.throws(() => loadSnapshot(join(directory, 'missing.json')));
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test('rejects broken document shapes and unsafe or duplicate route IDs', () => {
  const snapshot = loadSnapshot();
  const documents = structuredClone(snapshot.documents);
  assert.throws(() => validateDocuments({}), /Missing document/);
  documents['apps.json'].apps[1].id = documents['apps.json'].apps[0].id;
  assert.throws(() => validateDocuments(documents), /duplicate/);
  documents['apps.json'].apps[1].id = '../admin';
  assert.throws(() => validateDocuments(documents), /Invalid/);
});

test('only safe public URLs and explicitly local asset paths are rendered', () => {
  for (const url of ['javascript:alert(1)', 'data:text/html,x', 'https://user:pass@example.org/', '//example.org']) {
    assert.equal(safeUrl(url), null);
  }
  assert.equal(safeUrl('https://example.org/project'), 'https://example.org/project');
  assert.throws(() => assetUrl('assets/../../.env'));
  assert.throws(() => assetUrl('/etc/passwd'));
  assert.equal(assetUrl('assets/media/portrait.jpg'), '/assets/media/portrait.jpg');
  assert.ok(!safeJson({ text: '</script><script>alert(1)</script>' }).includes('<'));
});

test('HTML pigments remain aligned with the existing Flutter palette', () => {
  const dart = readFileSync(resolve(repositoryRoot, 'lib/app/theme/tokens.dart'), 'utf8');
  const css = readFileSync(new URL('../src/styles/tokens.css', import.meta.url), 'utf8');
  const names = { void_: 'void', surface: 'surface', surfaceRaised: 'surface-raised', hairline: 'line', hairlineStrong: 'line-strong', beacon: 'gold', faience: 'feedback', alert: 'error', textPrimary: 'text', textSecondary: 'secondary', textMuted: 'muted' };
  for (const palette of ['nocturneTokens', 'daybreakTokens']) {
    const block = dart.split(`const ${palette} = ThemeTokens(`)[1].split(');')[0];
    for (const [name, variable] of Object.entries(names)) {
      const value = block.match(new RegExp(`${name}: Color\\(0xFF([0-9A-F]{6})\\)`))[1];
      assert.ok(css.includes(`--${variable}: #${value};`), `${palette}.${name}`);
    }
  }
});
