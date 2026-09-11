import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {editableFiles} from '../contracts/content-schema.js';
import {handleRequest} from '../src/index.js';

const siteOrigin = 'https://asherbinyy.github.io';
const adminToken = 'b'.repeat(48);

class MemoryKv {
  values = new Map();

  async get(name, type) {
    const held = this.values.get(name);
    if (held === undefined) return null;
    return type === 'json' ? JSON.parse(held) : held;
  }

  async put(name, value) {
    this.values.set(name, value);
  }

  async delete(name) {
    this.values.delete(name);
  }

  async list({prefix = ''} = {}) {
    return {
      keys: [...this.values.keys()]
        .filter((name) => name.startsWith(prefix))
        .sort()
        .map((name) => ({name})),
      list_complete: true,
    };
  }
}

function environment(overrides = {}) {
  return {
    ANALYTICS: new MemoryKv(),
    CONTENT: new MemoryKv(),
    ADMIN_TOKEN: adminToken,
    SITE_ORIGIN: siteOrigin,
    SITE_ID: 'asherbinyy.github.io',
    ...overrides,
  };
}

function admin(path, {method = 'GET', body, token = adminToken} = {}) {
  return new Request(`https://worker.example${path}`, {
    method,
    headers: token
      ? {authorization: `Bearer ${token}`, 'content-type': 'application/json'}
      : {'content-type': 'application/json'},
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function fixture(file) {
  return JSON.parse(
    await readFile(new URL(`../contracts/fixtures/${file}`, import.meta.url), 'utf8'),
  );
}

async function page(env = environment()) {
  const response = await handleRequest(
    new Request('https://worker.example/admin'),
    env,
  );
  return response.text();
}

// --- the page --------------------------------------------------------------

test('the panel is named after the site, not after the codebase', async () => {
  const html = await page();
  assert.match(html, /Sherbini's Portfolio/);
  // "Nocturne" is what this repository is called. The owner logging in to
  // change his own website has never had a reason to know that word.
  assert.doesNotMatch(html, /nocturne/i);
});

test('the panel is handed the schema for every document it edits', async () => {
  const html = await page();
  const found = html.match(/"file":"([a-z]+\.json)"/g) ?? [];
  for (const file of editableFiles) {
    assert.ok(found.some((entry) => entry.includes(file)), `${file} missing`);
  }
});

test('the panel has a section list, an editor and a third column', async () => {
  const html = await page();
  for (const id of ['rail', 'editor', 'outline', 'bar']) {
    assert.match(html, new RegExp(`id="${id}"`), `#${id} missing`);
  }
});

test('the third column says it is not the website', async () => {
  // The integration contract forbids presenting a differently styled admin
  // rendering as a preview of the live site. Until the real adapter exists,
  // the panel has to say so where the owner is looking.
  const html = await page();
  assert.match(html, /not<\/strong> the\s+website/);
});

test('every label in the static markup points at a control that exists', async () => {
  const html = await page();
  const body = html.slice(html.indexOf('<body'));
  const targets = [...body.matchAll(/<label[^>]*\sfor="([^"]+)"/g)].map((m) => m[1]);
  assert.ok(targets.length > 0);
  for (const target of targets) {
    assert.match(body, new RegExp(`id="${target}"`), `no control for ${target}`);
  }
});

test('the panel keeps its own script and reaches nowhere else', async () => {
  const response = await handleRequest(
    new Request('https://worker.example/admin'),
    environment(),
  );
  const policy = response.headers.get('content-security-policy');
  assert.match(policy, /default-src 'none'/);
  assert.match(policy, /frame-ancestors 'none'/);
  assert.equal(response.headers.get('x-robots-tag'), 'noindex, nofollow');
});

// --- checking a draft ------------------------------------------------------

test('checking a draft needs the admin token', async () => {
  const response = await handleRequest(
    admin('/v1/admin/validate', {method: 'POST', body: {}, token: null}),
    environment(),
  );
  assert.equal(response.status, 401);
});

test('a valid draft comes back with nothing to fix', async () => {
  const response = await handleRequest(
    admin('/v1/admin/validate', {
      method: 'POST',
      body: {file: 'interests.json', document: await fixture('interests.json')},
    }),
    environment(),
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.deepEqual(body.errors, []);
});

test('a broken draft comes back with the paths that are wrong', async () => {
  const response = await handleRequest(
    admin('/v1/admin/validate', {
      method: 'POST',
      body: {
        file: 'profile.json',
        document: {name: {en: 'A'}, contact: {email: 'not an address'}},
      },
    }),
    environment(),
  );
  const body = await response.json();
  const paths = body.errors.map((issue) => issue.path);
  assert.ok(paths.includes('positioning'));
  assert.ok(paths.includes('contact.email'));
});

test('a file nobody edits cannot be checked', async () => {
  const response = await handleRequest(
    admin('/v1/admin/validate', {
      method: 'POST',
      body: {file: 'wrangler.toml', document: {}},
    }),
    environment(),
  );
  assert.equal(response.status, 400);
});

// --- reviewing -------------------------------------------------------------

test('a review says what would change and which claims moved', async () => {
  const env = environment();
  const live = await fixture('profile.json');
  await env.CONTENT.put('content:profile.json', JSON.stringify(live));

  const draft = JSON.parse(JSON.stringify(live));
  draft.stats[0].value = '9+';
  draft.location = {en: 'Testchester'};

  const response = await handleRequest(
    admin('/v1/admin/review', {
      method: 'POST',
      body: {file: 'profile.json', document: draft},
    }),
    env,
  );
  const body = await response.json();
  assert.equal(body.comparedWith, 'published');
  // Three, not two: replacing the location with an English-only value drops
  // its Arabic, and a review that did not show that would be hiding a
  // deletion behind an edit.
  assert.deepEqual(
    body.changes.map((change) => change.path).sort(),
    ['location.ar', 'location.en', 'stats.0.value'],
  );
  assert.equal(
    body.changes.find((change) => change.path === 'location.ar').after,
    null,
  );
  assert.equal(body.claims.length, 1);
  assert.equal(body.claims[0].was, '4+');
});

test('a review with nothing published says so rather than inventing a comparison', async () => {
  const response = await handleRequest(
    admin('/v1/admin/review', {
      method: 'POST',
      body: {file: 'profile.json', document: await fixture('profile.json')},
    }),
    environment(),
  );
  const body = await response.json();
  assert.equal(body.comparedWith, 'nothing');
  assert.deepEqual(body.changes, []);
});

// --- publishing ------------------------------------------------------------

test('a document that does not match the schema is refused', async () => {
  const env = environment();
  const response = await handleRequest(
    admin('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: {name: 'Ahmed'},
    }),
    env,
  );
  assert.equal(response.status, 422);
  const body = await response.json();
  assert.ok(body.errors.length > 0);
  // And nothing was written: a refused publish must not leave the site
  // serving half a document.
  assert.equal(await env.CONTENT.get('content:profile.json'), null);
});

test('a valid document is published', async () => {
  const env = environment();
  const response = await handleRequest(
    admin('/v1/admin/content/interests.json', {
      method: 'PUT',
      body: await fixture('interests.json'),
    }),
    env,
  );
  assert.equal(response.status, 200);
  assert.notEqual(await env.CONTENT.get('content:interests.json'), null);
});

test('a missing translation does not stop a publish', async () => {
  // The fixture's third interest has no Arabic. Refusing that would mean the
  // only way to publish is to invent a translation.
  const env = environment();
  const response = await handleRequest(
    admin('/v1/admin/content/interests.json', {
      method: 'PUT',
      body: await fixture('interests.json'),
    }),
    env,
  );
  assert.equal(response.status, 200);
});

test('a stop pointing at an application that is not published is refused', async () => {
  const env = environment();
  const apps = await fixture('apps.json');
  await env.CONTENT.put('content:apps.json', JSON.stringify(apps));

  const career = await fixture('career.json');
  career.roles[1].appIds = ['example-one', 'never-existed'];

  const response = await handleRequest(
    admin('/v1/admin/content/career.json', {method: 'PUT', body: career}),
    env,
  );
  assert.equal(response.status, 422);
});

test('what the panel says it loaded cannot get a broken reference published', async () => {
  // References are checked against the published document, not against a
  // claim in the request. The panel may declare what it has loaded to answer
  // its own question; a publish does not take its word for it.
  const env = environment();
  await env.CONTENT.put(
    'content:apps.json',
    JSON.stringify(await fixture('apps.json')),
  );
  const career = await fixture('career.json');
  career.roles[1].appIds = ['never-existed'];

  const response = await handleRequest(
    new Request('https://worker.example/v1/admin/content/career.json', {
      method: 'PUT',
      headers: {
        authorization: `Bearer ${adminToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify(career),
    }),
    env,
  );
  assert.equal(response.status, 422);
});

test('the panel can check a reference against a document it loaded itself', async () => {
  // Nothing is published, so the Worker cannot see the applications. The site
  // is using its bundled copy, which the panel has and the Worker has not.
  const career = await fixture('career.json');
  const response = await handleRequest(
    admin('/v1/admin/validate', {
      method: 'POST',
      body: {
        file: 'career.json',
        document: career,
        references: {'apps.json': ['example-one', 'example-two']},
      },
    }),
    environment(),
  );
  const body = await response.json();
  assert.deepEqual(body.errors, []);
  assert.deepEqual(body.warnings, []);
});
