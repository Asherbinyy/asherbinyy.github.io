import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {
  appearanceProposal,
  appearanceReady,
  blockedOn,
  fonts,
  routes,
  themes,
} from '../contracts/appearance.js';
import {editableFiles} from '../contracts/content-schema.js';
import {handleRequest} from '../src/index.js';
import {admin, environment} from './support.js';

// --- it must not look implemented ------------------------------------------

test('the appearance document is not in the editor', async () => {
  // The whole risk of this phase is a control that appears to work. It cannot
  // appear anywhere until something on the public side reads it.
  assert.ok(!editableFiles.includes('appearance.json'));
});

test('the Worker will not publish it either', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/content/appearance.json', {
      method: 'PUT',
      body: {theme: {default: 'nocturne'}},
    }),
    environment(),
  );
  assert.equal(refused.status, 400);
});

test('it is marked as a proposal', () => {
  assert.equal(appearanceProposal.status, 'proposed');
});

test('nothing has been quietly marked as unblocked', () => {
  assert.equal(appearanceReady, false);
  assert.ok(blockedOn.length > 0);
  assert.ok(blockedOn.every((entry) => entry.satisfied === false));
});

test('the panel has no appearance section', async () => {
  const page = await handleRequest(
    new Request('https://worker.example/admin'),
    environment(),
  );
  const html = await page.text();
  assert.ok(!/Appearance/.test(html));
});

// --- the identifiers have to be the app's real ones ------------------------

test('the theme ids are the keys the app actually stores', async () => {
  // The design system says Kemet and Deshret; AppTheme.storageKey says
  // nocturne and daybreak. A settings document written against the design
  // names would resolve to nothing and fall back, which looks like it half
  // worked. This fails if the enum is ever renamed.
  const source = await readFile(
    new URL('../../lib/app/theme/app_theme.dart', import.meta.url),
    'utf8',
  );
  for (const theme of themes) {
    assert.match(
      source,
      new RegExp(`'${theme.id}'`),
      `${theme.id} should exist in AppTheme`,
    );
  }
  assert.deepEqual(themes.map((theme) => theme.label), ['Kemet', 'Deshret']);
});

test('both palettes are permanent', () => {
  // R8: the base themes cannot be deleted, so there is no shape of this
  // document that leaves the site without one.
  assert.ok(themes.every((theme) => theme.permanent));
  assert.equal(themes.length, 2);
});

test('every font offered is one the app already bundles', async () => {
  const pubspec = await readFile(
    new URL('../../pubspec.yaml', import.meta.url),
    'utf8',
  );
  for (const font of fonts) {
    assert.match(pubspec, new RegExp(`family: ${font.family}`), font.family);
  }
});

test('every route offered is a real public route', async () => {
  const source = await readFile(
    new URL('../../lib/app/app_route.dart', import.meta.url),
    'utf8',
  );
  for (const route of routes) {
    assert.match(source, new RegExp(`${route.id}\\('${route.path}'\\)`), route.id);
  }
});

test('no route with a parameter is offered as a page setting', () => {
  assert.ok(routes.every((route) => !route.path.includes(':')));
  assert.ok(routes.every((route) => route.id !== 'console'));
});

test('the pattern list is empty rather than invented', () => {
  // Sixteen motifs are documented, but they are painters chosen at their call
  // sites, not a registry addressable by id. Slugs made from the document
  // headings would produce a list where choosing anything did nothing.
  const pages = appearanceProposal.fields.find((field) => field.key === 'pages');
  assert.deepEqual(pages.of.fields.find((f) => f.key === 'pattern').options, []);
  assert.equal(pages.consumer, 'pending');
});

test('every choice in the proposal offers only real values', () => {
  const walk = (field) => {
    if (field.kind === 'choice' && field.options.length > 0) {
      assert.ok(
        field.options.every((option) => typeof option.value === 'string'),
        field.key,
      );
    }
    if (field.kind === 'object') field.fields.forEach(walk);
    if (field.kind === 'list') walk(field.of);
  };
  appearanceProposal.fields.forEach(walk);
});
