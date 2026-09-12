import assert from 'node:assert/strict';
import test from 'node:test';

import {handleRequest} from '../src/index.js';
import {admin, environment, fixture, fromSite} from './support.js';

/// Publishes a document, optionally declaring which revision it was built on.
function put(file, body, {base, note} = {}) {
  const headers = {};
  if (base !== undefined) headers['x-base-revision'] = String(base);
  if (note !== undefined) headers['x-change-note'] = encodeURIComponent(note);
  return admin(`/v1/admin/content/${file}`, {method: 'PUT', body, headers});
}

/// A document with nothing in it anyone has to take on trust.
async function unclaimed() {
  return fixture('interests.json');
}

// --- revisions -------------------------------------------------------------

test('publishing gives the document a revision number', async () => {
  const env = environment();
  const first = await handleRequest(put('interests.json', await unclaimed()), env);
  assert.equal(first.status, 200);
  assert.equal((await first.json()).revision, 1);

  const changed = await unclaimed();
  changed.interests[0].label.en = 'Hiking';
  const second = await handleRequest(put('interests.json', changed), env);
  assert.equal((await second.json()).revision, 2);
});

test('the site is told which revision it just received', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal(read.headers.get('x-content-revision'), '1');
  // And the body is still the document itself. A revision number in the body
  // would break every reader for the sake of something only the panel wants.
  assert.deepEqual(Object.keys(await read.json()), ['interests']);
});

test('the history says what happened and when, newest first', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const changed = await unclaimed();
  changed.interests.pop();
  await handleRequest(put('interests.json', changed, {base: 1}), env);

  const listed = await handleRequest(
    admin('/v1/admin/content/interests.json/revisions'),
    env,
  );
  const body = await listed.json();
  assert.equal(body.current, 2);
  assert.deepEqual(body.revisions.map((entry) => entry.revision), [2, 1]);
  assert.ok(body.revisions.every((entry) => typeof entry.at === 'string'));
});

// --- two people, one document ----------------------------------------------

test('publishing over someone else is refused, not silently won', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);

  const theirs = await unclaimed();
  theirs.interests[0].label.en = 'Theirs';
  await handleRequest(put('interests.json', theirs, {base: 1}), env);

  // Built from revision 1, arriving after revision 2 landed.
  const mine = await unclaimed();
  mine.interests[0].label.en = 'Mine';
  const refused = await handleRequest(put('interests.json', mine, {base: 1}), env);
  assert.equal(refused.status, 409);
  const body = await refused.json();
  assert.equal(body.expected, 1);
  assert.equal(body.current, 2);
  // And it hands back what is actually there, so the panel can show it rather
  // than asking the owner to go and look.
  assert.equal(body.document.interests[0].label.en, 'Theirs');
});

test('the stale publish changed nothing', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const theirs = await unclaimed();
  theirs.interests[0].label.en = 'Theirs';
  await handleRequest(put('interests.json', theirs, {base: 1}), env);

  const mine = await unclaimed();
  mine.interests[0].label.en = 'Mine';
  await handleRequest(put('interests.json', mine, {base: 1}), env);

  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal((await read.json()).interests[0].label.en, 'Theirs');
});

test('publishing on the current revision goes through', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const next = await unclaimed();
  next.interests[0].label.en = 'Hiking';
  const accepted = await handleRequest(put('interests.json', next, {base: 1}), env);
  assert.equal(accepted.status, 200);
});

test('a caller that does not track revisions still works', async () => {
  // The header is how the panel says which revision it was looking at. A
  // client that never sends one is not forced to invent a number.
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const next = await unclaimed();
  next.interests[0].label.en = 'Hiking';
  assert.equal((await handleRequest(put('interests.json', next), env)).status, 200);
});

// --- claims need a source, and the Worker is the one that insists -----------

test('a changed figure without a source is refused by the Worker', async () => {
  const env = environment();
  const profile = await fixture('profile.json');
  await handleRequest(put('profile.json', profile, {note: 'Initial import'}), env);

  const raised = JSON.parse(JSON.stringify(profile));
  raised.stats[0].value = '9+';
  const refused = await handleRequest(put('profile.json', raised, {base: 1}), env);
  assert.equal(refused.status, 422);
  const body = await refused.json();
  assert.deepEqual(body.claims.map((claim) => claim.path), ['stats.0.value']);
});

test('an empty source is not a source', async () => {
  const env = environment();
  const profile = await fixture('profile.json');
  await handleRequest(put('profile.json', profile, {note: 'Initial import'}), env);
  const raised = JSON.parse(JSON.stringify(profile));
  raised.stats[0].value = '9+';
  const refused = await handleRequest(
    put('profile.json', raised, {base: 1, note: '   '}),
    env,
  );
  assert.equal(refused.status, 422);
});

test('a changed figure with a source is published and the source kept', async () => {
  const env = environment();
  const profile = await fixture('profile.json');
  await handleRequest(put('profile.json', profile, {note: 'Initial import'}), env);

  const raised = JSON.parse(JSON.stringify(profile));
  raised.stats[0].value = '9+';
  const accepted = await handleRequest(
    put('profile.json', raised, {base: 1, note: 'Payslip, 2026-09-01'}),
    env,
  );
  assert.equal(accepted.status, 200);

  const listed = await handleRequest(
    admin('/v1/admin/content/profile.json/revisions'),
    env,
  );
  const [newest] = (await listed.json()).revisions;
  assert.equal(newest.note, 'Payslip, 2026-09-01');
  assert.deepEqual(newest.claims, ['stats.0.value']);
});

test('the first publish of a document with figures needs a source', async () => {
  // Nothing is published, so the Worker cannot see what the figures were. It
  // will not compare against a baseline the caller supplied, so it asks.
  const env = environment();
  const refused = await handleRequest(
    put('profile.json', await fixture('profile.json')),
    env,
  );
  assert.equal(refused.status, 422);
});

test('changing something that is not a figure needs no source', async () => {
  const env = environment();
  const profile = await fixture('profile.json');
  await handleRequest(put('profile.json', profile, {note: 'Initial import'}), env);
  const moved = JSON.parse(JSON.stringify(profile));
  moved.location = {en: 'Testchester', ar: 'تستشستر'};
  const accepted = await handleRequest(put('profile.json', moved, {base: 1}), env);
  assert.equal(accepted.status, 200);
});

// --- going back ------------------------------------------------------------

test('a previous revision can be put back, as a new revision', async () => {
  const env = environment();
  const first = await unclaimed();
  await handleRequest(put('interests.json', first), env);
  const second = await unclaimed();
  second.interests[0].label.en = 'Regrettable';
  await handleRequest(put('interests.json', second, {base: 1}), env);

  const back = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 1},
    }),
    env,
  );
  assert.equal(back.status, 200);
  const body = await back.json();
  // Three, not one. History is append-only: two documents sharing a revision
  // number would make the number useless.
  assert.equal(body.revision, 3);
  assert.equal(body.restoredFrom, 1);

  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal((await read.json()).interests[0].label.en, 'Walking');
});

test('going back to a revision that never existed is refused', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const missing = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 9},
    }),
    env,
  );
  assert.equal(missing.status, 404);
});

test('going back to a withdrawal is refused', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  await handleRequest(
    admin('/v1/admin/content/interests.json', {method: 'DELETE'}),
    env,
  );
  const refused = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 2},
    }),
    env,
  );
  assert.equal(refused.status, 404);
});

test('rollback needs the admin token', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 1},
      token: null,
    }),
    environment(),
  );
  assert.equal(refused.status, 401);
});

// --- withdrawing -----------------------------------------------------------

test('withdrawing is recorded in the history', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  const removed = await handleRequest(
    admin('/v1/admin/content/interests.json', {method: 'DELETE'}),
    env,
  );
  assert.equal(removed.status, 200);

  const listed = await handleRequest(
    admin('/v1/admin/content/interests.json/revisions'),
    env,
  );
  const body = await listed.json();
  assert.equal(body.withdrawn, true);
  assert.equal(body.revisions[0].withdrawal, true);
  // And the earlier revision is still there to go back to.
  assert.equal(body.revisions[1].revision, 1);
});

test('a withdrawn document can be published again', async () => {
  const env = environment();
  await handleRequest(put('interests.json', await unclaimed()), env);
  await handleRequest(
    admin('/v1/admin/content/interests.json', {method: 'DELETE'}),
    env,
  );
  const again = await handleRequest(
    put('interests.json', await unclaimed(), {base: 2}),
    env,
  );
  assert.equal(again.status, 200);
  assert.equal((await again.json()).revision, 3);
});

test('the history of a file nobody edits is refused', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/content/wrangler.toml/revisions'),
    environment(),
  );
  assert.equal(refused.status, 400);
});
