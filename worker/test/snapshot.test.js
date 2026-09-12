import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {editableFiles} from '../contracts/content-schema.js';
import {
  buildSnapshot,
  compareRelease,
  digest,
  stableJson,
} from '../contracts/snapshot.js';
import {handleRequest} from '../src/index.js';
import {admin, environment, fixture} from './support.js';

/// The digest Codex's own `site/src/lib/content.mjs` produces over the five
/// documents in `assets/content/`, captured on 2026-09-12.
///
/// This is the pin. The builder recomputes the revision and refuses to build
/// on a mismatch, so if these two implementations ever disagree the failure
/// would otherwise surface as a build error nobody can place. It surfaces
/// here instead.
const referenceDigest =
  '2e6a765a3130fa5ce5d596fffef604b7eedf07311df10cbe34212d2bcb348019';

async function bundled() {
  const documents = {};
  for (const file of editableFiles) {
    documents[file] = JSON.parse(
      await readFile(new URL(`../../assets/content/${file}`, import.meta.url), 'utf8'),
    );
  }
  return documents;
}

// --- the canonical form ----------------------------------------------------

test('the digest matches the builder reference exactly', async () => {
  assert.equal(await digest(await bundled()), referenceDigest);
});

test('object keys are sorted and array order is kept', () => {
  assert.equal(
    stableJson({b: 1, a: [3, {d: 4, c: 5}]}),
    '{"a":[3,{"c":5,"d":4}],"b":1}',
  );
});

test('two documents that differ only in key order have one revision', async () => {
  // The point of a canonical form. Re-saving a document should not rebuild the
  // site to produce identical bytes.
  const one = {a: {x: 1, y: 2}};
  const other = {a: {y: 2, x: 1}};
  assert.equal(await digest(one), await digest(other));
});

test('array order changes the revision', async () => {
  // Order is content here: it is the order things appear on the page.
  assert.notEqual(await digest({a: [1, 2]}), await digest({a: [2, 1]}));
});

test('scalars encode as ordinary JSON', () => {
  assert.equal(stableJson({a: null, b: true, c: 1.5, d: 'x"y'}),
    '{"a":null,"b":true,"c":1.5,"d":"x\\"y"}');
});

// --- building the artifact -------------------------------------------------

async function allFixtures() {
  const documents = {};
  for (const file of editableFiles) documents[file] = await fixture(file);
  return documents;
}

test('a complete valid set builds an artifact', async () => {
  const apps = await fixture('apps.json');
  const {problems, snapshot} = await buildSnapshot(await allFixtures(), {
    references: {'apps.json': apps.apps.map((entry) => entry.id)},
  });
  assert.deepEqual(problems, []);
  assert.equal(snapshot.schemaVersion, 1);
  assert.match(snapshot.revision, /^[0-9a-f]{64}$/);
  assert.deepEqual(Object.keys(snapshot.documents), editableFiles);
});

test('a missing document is refused rather than built around', async () => {
  const documents = await allFixtures();
  delete documents['education.json'];
  const {problems, snapshot} = await buildSnapshot(documents);
  assert.equal(snapshot, null);
  assert.ok(problems.some((entry) => entry.file === 'education.json'));
});

test('a document that fails the schema is refused here, not by the builder', async () => {
  const documents = await allFixtures();
  documents['profile.json'] = {name: {en: 'A'}};
  const {problems, snapshot} = await buildSnapshot(documents);
  assert.equal(snapshot, null);
  assert.ok(problems.some((entry) => entry.path === 'positioning'));
});

test('anything the site is not built from is refused', async () => {
  const documents = await allFixtures();
  documents['secrets.json'] = {token: 'nope'};
  const {problems, snapshot} = await buildSnapshot(documents);
  assert.equal(snapshot, null);
  assert.ok(problems.some((entry) => entry.file === 'secrets.json'));
});

test('nothing extra rides along into the artifact', async () => {
  const documents = await allFixtures();
  const {snapshot} = await buildSnapshot(documents, {
    references: {'apps.json': (await fixture('apps.json')).apps.map((a) => a.id)},
  });
  assert.deepEqual(Object.keys(snapshot), ['schemaVersion', 'revision', 'documents']);
});

test('the artifact is reproducible', async () => {
  const documents = await allFixtures();
  const references = {
    'apps.json': (await fixture('apps.json')).apps.map((entry) => entry.id),
  };
  const first = await buildSnapshot(documents, {references});
  const second = await buildSnapshot(documents, {references});
  assert.equal(first.snapshot.revision, second.snapshot.revision);
});

// --- is the site actually showing it ---------------------------------------

test('no release file means unreleased, not published', async () => {
  // The Astro slice is not the production host yet. Saying "published" here
  // would be the exact claim the contract forbids.
  const seen = compareRelease('abc', null);
  assert.equal(seen.state, 'unreleased');
  assert.equal(seen.live, null);
});

test('a matching revision is live', () => {
  const seen = compareRelease('abc', {schemaVersion: 1, revision: 'abc', pages: []});
  assert.equal(seen.state, 'live');
});

test('a different revision is behind, and says which', () => {
  const seen = compareRelease('abc', {schemaVersion: 1, revision: 'def', pages: []});
  assert.equal(seen.state, 'behind');
  assert.equal(seen.live, 'def');
});

test('a release file with no revision is unreadable rather than assumed', () => {
  assert.equal(compareRelease('abc', {pages: []}).state, 'unreadable');
});

// --- the endpoint ----------------------------------------------------------

test('the release view needs the admin token', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/release', {method: 'POST', body: {}, token: null}),
    environment({RELEASE_URL: ''}),
  );
  assert.equal(refused.status, 401);
});

test('the panel supplies the bundled documents and gets a revision back', async () => {
  const response = await handleRequest(
    admin('/v1/admin/release', {
      method: 'POST',
      body: {
        documents: await allFixtures(),
        references: {
          'apps.json': (await fixture('apps.json')).apps.map((entry) => entry.id),
        },
      },
    }),
    environment({RELEASE_URL: ''}),
  );
  const body = await response.json();
  assert.deepEqual(body.problems, []);
  assert.match(body.revision, /^[0-9a-f]{64}$/);
  // Nothing serves a release file yet, so it is unreleased -- never published.
  assert.equal(body.release.state, 'unreleased');
});

test('a published document beats whatever the caller supplied', async () => {
  // The panel supplies the bundle because only it can read it. It does not get
  // to describe a document this Worker is already serving.
  const env = environment({RELEASE_URL: ''});
  const published = await fixture('interests.json');
  published.interests[0].label.en = 'What the site actually shows';
  await env.CONTENT.put('content:interests.json', JSON.stringify(published));

  const documents = await allFixtures();
  documents['interests.json'].interests[0].label.en = 'What the caller claims';

  const body = await (
    await handleRequest(
      admin('/v1/admin/release', {
        method: 'POST',
        body: {
          documents,
          references: {
            'apps.json': (await fixture('apps.json')).apps.map((e) => e.id),
          },
        },
      }),
      env,
    )
  ).json();

  const {snapshot} = await buildSnapshot(
    {...documents, 'interests.json': published},
    {references: {'apps.json': (await fixture('apps.json')).apps.map((e) => e.id)}},
  );
  assert.equal(body.revision, snapshot.revision);
  assert.equal(
    body.snapshot.documents['interests.json'].interests[0].label.en,
    'What the site actually shows',
  );
});

test('content that would fail the build is reported as invalid, not as behind', async () => {
  const documents = await allFixtures();
  documents['profile.json'] = {name: {en: 'A'}};
  const body = await (
    await handleRequest(
      admin('/v1/admin/release', {method: 'POST', body: {documents}}),
      environment({RELEASE_URL: ''}),
    )
  ).json();
  assert.equal(body.state, 'invalid');
  assert.equal(body.revision, null);
  assert.ok(body.problems.length > 0);
});
