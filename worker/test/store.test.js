import assert from 'node:assert/strict';
import test from 'node:test';

import {handleRequest} from '../src/index.js';
import {durableNamespace} from '../dev/durable-double.js';
import {ContentStore} from '../src/store.js';
import {admin, adminToken, environment, fixture, fromSite} from './support.js';

/// An environment whose mutations go through the Durable Object.
function transactional(overrides = {}) {
  return environment({CONTENT_STORE: durableNamespace(ContentStore), ...overrides});
}

function put(file, body, {base, note} = {}) {
  const headers = {};
  if (base !== undefined) headers['x-base-revision'] = String(base);
  if (note !== undefined) headers['x-change-note'] = encodeURIComponent(note);
  return admin(`/v1/admin/content/${file}`, {method: 'PUT', body, headers});
}

const interests = () => fixture('interests.json');

// --- AR-1: two writers -----------------------------------------------------

test('two publishes racing on the same base produce one revision', async () => {
  // The defect: both read revision 0, both decided they were current, both
  // answered "revision 1". One document and one history entry simply vanished.
  const env = transactional();
  const first = await interests();
  first.interests[0].label.en = 'First';
  const second = await interests();
  second.interests[0].label.en = 'Second';

  const [one, two] = await Promise.all([
    handleRequest(put('interests.json', first, {base: 0}), env),
    handleRequest(put('interests.json', second, {base: 0}), env),
  ]);
  const codes = [one.status, two.status].sort();
  assert.deepEqual(codes, [200, 409]);

  const history = await (
    await handleRequest(admin('/v1/admin/content/interests.json/revisions'), env)
  ).json();
  assert.equal(history.current, 1);
  assert.equal(history.revisions.length, 1);
});

test('a crowd of concurrent publishes still produces one revision each', async () => {
  const env = transactional();
  const base = await interests();
  const attempts = [];
  for (let index = 0; index < 8; index += 1) {
    const document = JSON.parse(JSON.stringify(base));
    document.interests[0].label.en = 'Attempt ' + index;
    attempts.push(handleRequest(put('interests.json', document, {base: 0}), env));
  }
  const answered = await Promise.all(attempts);
  const accepted = answered.filter((response) => response.status === 200);
  const refused = answered.filter((response) => response.status === 409);
  assert.equal(accepted.length, 1);
  assert.equal(refused.length, 7);

  const history = await (
    await handleRequest(admin('/v1/admin/content/interests.json/revisions'), env)
  ).json();
  assert.equal(history.revisions.length, 1);
});

test('every accepted revision is kept', async () => {
  const env = transactional();
  for (let revision = 0; revision < 4; revision += 1) {
    const document = await interests();
    document.interests[0].label.en = 'Version ' + revision;
    const response = await handleRequest(
      put('interests.json', document, {base: revision}),
      env,
    );
    assert.equal(response.status, 200);
  }
  const history = await (
    await handleRequest(admin('/v1/admin/content/interests.json/revisions'), env)
  ).json();
  assert.deepEqual(history.revisions.map((entry) => entry.revision), [4, 3, 2, 1]);
});

test('a failed write leaves content, history and head agreeing', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);

  // The head write fails half way through the second publish.
  env.CONTENT_STORE.state.storage.failOn = 'head:interests.json';
  const next = await interests();
  next.interests[0].label.en = 'Never landed';
  await handleRequest(put('interests.json', next, {base: 1}), env).catch(() => {});
  env.CONTENT_STORE.state.storage.failOn = null;

  const stored = env.CONTENT_STORE.state.storage.map;
  assert.equal(stored.get('head:interests.json').revision, 1);
  assert.equal(stored.get('doc:interests.json').interests[0].label.en, 'Walking');
  assert.ok(!stored.has('rev:interests.json:000002'));
});

test('the panel is told whether writes are actually protected', async () => {
  const guarded = await (
    await handleRequest(admin('/v1/admin/content'), transactional())
  ).json();
  assert.equal(guarded.atomic, true);

  // Without the binding the Worker behaves exactly as it did, and says so
  // rather than implying a protection it does not have.
  const plain = await (
    await handleRequest(admin('/v1/admin/content'), environment())
  ).json();
  assert.equal(plain.atomic, false);
});

test('the public read is unchanged by where the content lives', async () => {
  const env = transactional();
  const document = await interests();
  await handleRequest(put('interests.json', document, {base: 0}), env);
  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal(read.status, 200);
  // The document itself, not an envelope, exactly as before.
  assert.deepEqual(await read.json(), document);
  assert.equal(read.headers.get('x-content-revision'), '1');
});

// --- AR-5: rollback and withdrawal are writes too --------------------------

test('rolling back on a stale revision is refused', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);
  const second = await interests();
  second.interests[0].label.en = 'Someone else';
  await handleRequest(put('interests.json', second, {base: 1}), env);

  const refused = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 1},
      headers: {'x-base-revision': '1'},
    }),
    env,
  );
  assert.equal(refused.status, 409);

  // And the newer content is still there.
  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal((await read.json()).interests[0].label.en, 'Someone else');
});

test('rolling back on the current revision works', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);
  const second = await interests();
  second.interests[0].label.en = 'Regrettable';
  await handleRequest(put('interests.json', second, {base: 1}), env);

  const back = await handleRequest(
    admin('/v1/admin/content/interests.json/rollback', {
      method: 'POST',
      body: {revision: 1},
      headers: {'x-base-revision': '2'},
    }),
    env,
  );
  assert.equal(back.status, 200);
  assert.equal((await back.json()).revision, 3);
});

test('withdrawing on a stale revision is refused', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);
  const second = await interests();
  second.interests[0].label.en = 'Someone else';
  await handleRequest(put('interests.json', second, {base: 1}), env);

  const refused = await handleRequest(
    admin('/v1/admin/content/interests.json', {
      method: 'DELETE',
      headers: {'x-base-revision': '1'},
    }),
    env,
  );
  assert.equal(refused.status, 409);
  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  assert.equal(read.status, 200);
});

test('withdrawing on the current revision works and is recorded', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);
  const gone = await handleRequest(
    admin('/v1/admin/content/interests.json', {
      method: 'DELETE',
      headers: {'x-base-revision': '1'},
    }),
    env,
  );
  assert.equal(gone.status, 200);
  const history = await (
    await handleRequest(admin('/v1/admin/content/interests.json/revisions'), env)
  ).json();
  assert.equal(history.withdrawn, true);
  assert.equal(history.revisions[0].withdrawal, true);
});

// --- AR-4: the document and its revision arrive together -------------------

test('the editor reads a document and its revision in one answer', async () => {
  const env = transactional();
  await handleRequest(put('interests.json', await interests(), {base: 0}), env);
  const read = await handleRequest(
    admin('/v1/admin/content/interests.json'),
    env,
  );
  const body = await read.json();
  assert.equal(body.revision, 1);
  assert.equal(body.published, true);
  assert.ok(Array.isArray(body.document.interests));
});

test('an unpublished document reads as revision zero, not as an error', async () => {
  const body = await (
    await handleRequest(admin('/v1/admin/content/apps.json'), transactional())
  ).json();
  assert.equal(body.revision, 0);
  assert.equal(body.published, false);
  assert.equal(body.document, null);
});

test('reading a document for editing needs the admin token', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/content/interests.json', {token: null}),
    transactional(),
  );
  assert.equal(refused.status, 401);
});

// --- AR-2: the limit comes before the expensive part -----------------------

test('a blocked sign-in never derives a key', async () => {
  // The defect: derivation ran for every guess and only the answer changed
  // once the limit was reached, so an attacker could keep testing passwords
  // and a correct one would still have been accepted.
  const env = transactional();
  const setUp = await handleRequest(
    admin('/v1/admin/password', {
      method: 'POST',
      body: {current: adminToken, next: 'a-long-enough-fixture-password'},
    }),
    env,
  );
  assert.equal(setUp.status, 200);

  let derivations = 0;
  const real = crypto.subtle.deriveBits.bind(crypto.subtle);
  crypto.subtle.deriveBits = (...args) => {
    derivations += 1;
    return real(...args);
  };
  try {
    const signIn = (password) =>
      handleRequest(
        new Request('https://worker.example/v1/admin/session', {
          method: 'POST',
          headers: {'content-type': 'application/json'},
          body: JSON.stringify({password}),
        }),
        env,
      );

    for (let attempt = 0; attempt < 10; attempt += 1) {
      assert.equal((await signIn('wrong ' + attempt)).status, 401);
    }
    const before = derivations;

    // Over the limit. Nothing further may be derived, and the correct
    // password must not get in either -- that is what a throttle is.
    assert.equal((await signIn('wrong again')).status, 429);
    assert.equal((await signIn('a-long-enough-fixture-password')).status, 429);
    assert.equal(derivations, before, 'no key was derived while blocked');

    // The deployment secret is the way back in, and needs no derivation.
    assert.equal((await signIn(adminToken)).status, 200);
    assert.equal(derivations, before);

    // Getting in with it clears the count.
    assert.equal(
      (await signIn('a-long-enough-fixture-password')).status,
      200,
    );
  } finally {
    crypto.subtle.deriveBits = real;
  }
});

test('concurrent wrong guesses are all counted', async () => {
  // Counting in KV is a read-modify-write, so guesses arriving together used
  // to read the same number and write the same increment.
  const env = transactional();
  const signIn = () =>
    handleRequest(
      new Request('https://worker.example/v1/admin/session', {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({password: 'wrong'}),
      }),
      env,
    );
  await Promise.all(Array.from({length: 12}, signIn));
  const {count} = await env.CONTENT_STORE
    .get()
    .fetch('https://content-store/', {
      method: 'POST',
      body: JSON.stringify({op: 'attempts', scope: 'sign-in', action: 'read', now: Date.now()}),
    })
    .then((response) => response.json());
  assert.equal(count, 12);
});

test('the same race against plain key/value storage is not safe, which is why the object exists', async () => {
  // Not an assertion that the fallback is acceptable -- an assertion that this
  // test can tell the difference. If the Durable Object path ever stopped
  // serialising, the tests above would start behaving like this one.
  const env = environment();
  const first = await interests();
  first.interests[0].label.en = 'First';
  const second = await interests();
  second.interests[0].label.en = 'Second';

  const answered = await Promise.all([
    handleRequest(put('interests.json', first, {base: 0}), env),
    handleRequest(put('interests.json', second, {base: 0}), env),
  ]);
  assert.deepEqual(answered.map((response) => response.status), [200, 200]);

  const history = await (
    await handleRequest(admin('/v1/admin/content/interests.json/revisions'), env)
  ).json();
  // Two writers, one surviving revision. This is the defect, reproduced.
  assert.equal(history.revisions.length, 1);
});

// --- ARR-1: admission is one indivisible step ------------------------------

test('a burst of guesses gets exactly the slots that were left', async () => {
  // The defect: reading the count, deciding, and recording the failure
  // afterwards left a gap. Nine failures in, thirty simultaneous guesses all
  // read "nine", all passed the check, and all thirty derived a key. Codex
  // measured exactly that: 30 derivations, 30 answers of 401, no 429.
  const env = transactional();
  await handleRequest(
    admin('/v1/admin/password', {
      method: 'POST',
      body: {current: adminToken, next: 'a-long-enough-fixture-password'},
    }),
    env,
  );

  const signIn = (password) =>
    handleRequest(
      new Request('https://worker.example/v1/admin/session', {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({password}),
      }),
      env,
    );

  // Nine failures, sequentially. One slot of ten remains.
  for (let attempt = 0; attempt < 9; attempt += 1) {
    assert.equal((await signIn('wrong ' + attempt)).status, 401);
  }

  let derivations = 0;
  const real = crypto.subtle.deriveBits.bind(crypto.subtle);
  crypto.subtle.deriveBits = (...args) => {
    derivations += 1;
    return real(...args);
  };
  try {
    const burst = await Promise.all(
      Array.from({length: 30}, (_, index) => signIn('burst ' + index)),
    );
    const answered = burst.map((response) => response.status);
    // The measurement that matters: how many actually derived a key, not what
    // the counter says afterwards.
    assert.equal(derivations, 1, 'exactly the one remaining slot was admitted');
    assert.equal(answered.filter((code) => code === 401).length, 1);
    assert.equal(answered.filter((code) => code === 429).length, 29);
  } finally {
    crypto.subtle.deriveBits = real;
  }
});

test('a reservation is kept when the attempt fails', async () => {
  const env = transactional();
  const signIn = () =>
    handleRequest(
      new Request('https://worker.example/v1/admin/session', {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({password: 'wrong'}),
      }),
      env,
    );
  for (let attempt = 0; attempt < 10; attempt += 1) await signIn();
  assert.equal((await signIn()).status, 429);
});

test('recovery is not throttled, and getting in releases the hour', async () => {
  const env = transactional();
  const signIn = (password) =>
    handleRequest(
      new Request('https://worker.example/v1/admin/session', {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({password}),
      }),
      env,
    );
  await handleRequest(
    admin('/v1/admin/password', {
      method: 'POST',
      body: {current: adminToken, next: 'a-long-enough-fixture-password'},
    }),
    env,
  );
  for (let attempt = 0; attempt < 15; attempt += 1) await signIn('wrong');
  assert.equal((await signIn('a-long-enough-fixture-password')).status, 429);
  assert.equal((await signIn(adminToken)).status, 200);
  assert.equal((await signIn('a-long-enough-fixture-password')).status, 200);
});

// --- ARR-2: a renewal cannot bring back a revoked session ------------------

/// Signs in and returns the session token.
async function signedIn(env) {
  const response = await handleRequest(
    new Request('https://worker.example/v1/admin/session', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({password: adminToken}),
    }),
    env,
  );
  return (await response.json()).token;
}

/// Winds a session's clocks back so the next use renews it.
function ageSession(env, hours) {
  const storage = env.CONTENT_STORE.state.storage.map;
  const name = [...storage.keys()].find((key) => key.startsWith('session:'));
  const held = storage.get(name);
  const shift = hours * 60 * 60 * 1000;
  held.expires = new Date(Date.parse(held.expires) - shift).toISOString();
  storage.set(name, held);
}

test('a renewal held open cannot undo a logout that lands during it', async () => {
  // Codex's reproduction: hold the renewal write at hour eleven, log out, let
  // the write finish, then use the token again. It answered 200 -- the stale
  // renewal had put the revoked session back.
  const env = transactional();
  const token = await signedIn(env);
  ageSession(env, 11);

  const storage = env.CONTENT_STORE.state.storage;
  let entered;
  const renewalStarted = new Promise((resolve) => {
    entered = resolve;
  });
  let release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  storage.onPut = async (key) => {
    if (!key.startsWith('session:')) return;
    storage.onPut = null;
    entered();
    await gate;
  };

  const renewing = handleRequest(admin('/v1/admin/content', {token}), env);
  await renewalStarted;

  const signOut = handleRequest(
    admin('/v1/admin/session', {method: 'DELETE', token}),
    env,
  );
  release();
  await renewing;
  assert.equal((await signOut).status, 200);

  const after = await handleRequest(admin('/v1/admin/content', {token}), env);
  assert.equal(after.status, 401, 'the revoked session stayed revoked');
});

test('a renewal arriving after a logout does not recreate the session', async () => {
  const env = transactional();
  const token = await signedIn(env);
  ageSession(env, 11);

  await handleRequest(
    admin('/v1/admin/session', {method: 'DELETE', token}),
    env,
  );
  // The use that would have renewed it, arriving late.
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token}), env)).status,
    401,
  );
  const storage = env.CONTENT_STORE.state.storage.map;
  assert.equal(
    [...storage.keys()].filter((key) => key.startsWith('session:')).length,
    0,
    'nothing was written back',
  );
});

test('a renewal cannot survive a password change either', async () => {
  const env = transactional();
  const token = await signedIn(env);
  ageSession(env, 11);
  await handleRequest(
    admin('/v1/admin/password', {
      method: 'POST',
      body: {current: adminToken, next: 'a-long-enough-fixture-password'},
      token,
    }),
    env,
  );
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token}), env)).status,
    401,
  );
});

// --- ARR-3: a read is one fact ---------------------------------------------

/// The document a revision actually holds, read out of the store.
///
/// The listing endpoint deliberately leaves documents out, so consistency is
/// checked against what was stored rather than against what is reported.
function documentOfRevision(env, file, revision) {
  const name = `rev:${file}:${String(revision).padStart(6, '0')}`;
  return env.CONTENT_STORE.state.storage.map.get(name)?.document ?? null;
}

/// Publishes in the background the first time [key] is read.
function commitDuringRead(env, key, document) {
  const storage = env.CONTENT_STORE.state.storage;
  let started = null;
  storage.onGet = async (name) => {
    if (!name.startsWith(key)) return;
    storage.onGet = null;
    // Deliberately not awaited: it queues behind whatever is running, which
    // is exactly the interleaving being tested. The yields let it actually
    // reach the queue before the caller's next read is dispatched -- without
    // them the race is set up but never runs.
    started = handleRequest(put('interests.json', document, {base: 1}), env);
    for (let tick = 0; tick < 4; tick += 1) {
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
  };
  return () => started;
}

test('the editor never receives one revision paired with another document', async () => {
  // Codex's reproduction: commit revision two between the head read and the
  // document read, and the editor is handed revision one with revision two's
  // content -- so the draft built on it carries a base that was never true.
  const env = transactional();
  const first = await interests();
  first.interests[0].label.en = 'Revision one';
  await handleRequest(put('interests.json', first, {base: 0}), env);

  const second = await interests();
  second.interests[0].label.en = 'Revision two';
  const pending = commitDuringRead(env, 'head:interests.json', second);

  const read = await handleRequest(
    admin('/v1/admin/content/interests.json'),
    env,
  );
  const body = await read.json();
  await pending();

  // The pair has to describe one moment. Which moment it is does not matter.
  const held = documentOfRevision(env, 'interests.json', body.revision);
  assert.ok(held, `revision ${body.revision} exists`);
  assert.deepEqual(
    body.document,
    held,
    'the document is the one that revision actually holds',
  );
});

test('the public read never labels a document with another revision', async () => {
  const env = transactional();
  const first = await interests();
  first.interests[0].label.en = 'Revision one';
  await handleRequest(put('interests.json', first, {base: 0}), env);

  const second = await interests();
  second.interests[0].label.en = 'Revision two';
  const pending = commitDuringRead(env, 'head:interests.json', second);

  const read = await handleRequest(fromSite('/v1/content/interests.json'), env);
  const document = await read.json();
  const revision = Number(read.headers.get('x-content-revision'));
  await pending();

  assert.deepEqual(
    document,
    documentOfRevision(env, 'interests.json', revision),
  );
});

test('a release capture is one instant, not five reads', async () => {
  const env = transactional();
  const first = await interests();
  first.interests[0].label.en = 'Revision one';
  await handleRequest(put('interests.json', first, {base: 0}), env);

  const second = await interests();
  second.interests[0].label.en = 'Revision two';
  // Commits while the capture is part-way through the five documents.
  const pending = commitDuringRead(env, 'doc:apps.json', second);

  const documents = {};
  for (const file of ['profile.json', 'career.json', 'apps.json',
    'education.json', 'interests.json']) {
    documents[file] = await fixture(file);
  }
  const body = await (
    await handleRequest(
      admin('/v1/admin/release', {method: 'POST', body: {documents}}),
      environmentFrom(env),
    )
  ).json();
  await pending();

  const captured = body.capturedAt['interests.json'];
  assert.deepEqual(
    body.snapshot.documents['interests.json'],
    documentOfRevision(env, 'interests.json', captured),
    'the captured document is the one its reported revision holds',
  );
});

/// The same environment, with the release endpoint's own settings.
function environmentFrom(env) {
  return Object.assign({}, env, {RELEASE_URL: ''});
}

test('two separate reads can disagree, which is why there is one operation', async () => {
  // Not an assertion that separate reads are acceptable -- an assertion that
  // this suite can tell the difference. This is the shape the editor read had
  // before ARR-3, with a commit landing in the window between its two calls.
  const env = transactional();
  const backend = (await import('../src/store.js')).contentBackend(env);
  const first = await interests();
  first.interests[0].label.en = 'Revision one';
  await handleRequest(put('interests.json', first, {base: 0}), env);

  const head = await backend.head('interests.json');

  const second = await interests();
  second.interests[0].label.en = 'Revision two';
  await handleRequest(put('interests.json', second, {base: 1}), env);

  const document = await backend.readDocument('interests.json');

  assert.equal(head.revision, 1);
  assert.equal(document.interests[0].label.en, 'Revision two');
  // Revision one's number paired with revision two's document: the defect.
  assert.notDeepEqual(
    document,
    documentOfRevision(env, 'interests.json', head.revision),
  );
});

test('the one operation cannot be split the same way', async () => {
  // The same interleave, against `readWithHead`. There is no window between
  // the two values, so whatever comes back describes one moment.
  const env = transactional();
  const backend = (await import('../src/store.js')).contentBackend(env);
  const first = await interests();
  first.interests[0].label.en = 'Revision one';
  await handleRequest(put('interests.json', first, {base: 0}), env);

  const second = await interests();
  second.interests[0].label.en = 'Revision two';
  const racing = handleRequest(put('interests.json', second, {base: 1}), env);

  const {document, head} = await backend.readWithHead('interests.json');
  await racing;

  assert.deepEqual(
    document,
    documentOfRevision(env, 'interests.json', head.revision),
  );
});
