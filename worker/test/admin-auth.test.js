import assert from 'node:assert/strict';
import test from 'node:test';

import {handleRequest} from '../src/index.js';
import {admin, adminToken, environment} from './support.js';

const password = 'a-long-enough-fixture-password';

function signIn(secret) {
  return new Request('https://worker.example/v1/admin/session', {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({password: secret}),
  });
}

async function sessionFor(env, secret = adminToken) {
  const response = await handleRequest(signIn(secret), env);
  assert.equal(response.status, 200, 'signing in should work');
  return (await response.json()).token;
}

function setPassword(token, current, next) {
  return admin('/v1/admin/password', {
    method: 'POST',
    body: {current, next},
    token,
  });
}

// --- signing in ------------------------------------------------------------

test('the deployment secret signs in and gets a session back', async () => {
  const env = environment();
  const response = await handleRequest(signIn(adminToken), env);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.match(body.token, /^[0-9a-f]{64}$/);
  // Not the deployment secret. What the browser holds from here on is a
  // session that can be ended, not the credential that can rewrite the site.
  assert.notEqual(body.token, adminToken);
  assert.ok(Date.parse(body.expires) > Date.now());
});

test('a session works on the endpoints behind the gate', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const listed = await handleRequest(admin('/v1/admin/content', {token}), env);
  assert.equal(listed.status, 200);
});

test('the wrong password gets nothing', async () => {
  const response = await handleRequest(signIn('not the password'), environment());
  assert.equal(response.status, 401);
});

test('a session token is never stored as itself', async () => {
  // A dump of the namespace should not hand anyone a working credential.
  const env = environment();
  const token = await sessionFor(env);
  const stored = [...env.CONTENT.values.entries()]
    .filter(([name]) => name.startsWith('session:'));
  assert.equal(stored.length, 1);
  assert.ok(!stored[0][0].includes(token));
  assert.ok(!stored[0][1].value.includes(token));
});

// --- signing out -----------------------------------------------------------

test('signing out stops the session working', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const out = await handleRequest(
    admin('/v1/admin/session', {method: 'DELETE', token}),
    env,
  );
  assert.equal(out.status, 200);

  const after = await handleRequest(admin('/v1/admin/content', {token}), env);
  assert.equal(after.status, 401);
});

test('signing out of one session leaves the others alone', async () => {
  const env = environment();
  const phone = await sessionFor(env);
  const desk = await sessionFor(env);
  await handleRequest(
    admin('/v1/admin/session', {method: 'DELETE', token: phone}),
    env,
  );
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token: desk}), env)).status,
    200,
  );
});

test('an expired session is refused and says it is signed out', async () => {
  const env = environment();
  const token = await sessionFor(env);
  // Wind the stored session back past its own expiry.
  const name = [...env.CONTENT.values.keys()].find((k) => k.startsWith('session:'));
  const held = JSON.parse(env.CONTENT.values.get(name).value);
  held.expires = new Date(Date.now() - 1000).toISOString();
  await env.CONTENT.put(name, JSON.stringify(held));

  const response = await handleRequest(admin('/v1/admin/content', {token}), env);
  assert.equal(response.status, 401);
  // The panel needs to tell "your session ended" apart from "that was wrong",
  // so it can offer to sign in again instead of throwing the drafts away.
  assert.equal((await response.json()).reason, 'signed-out');
});

test('a session that has been alive too long is refused however recently used', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const name = [...env.CONTENT.values.keys()].find((k) => k.startsWith('session:'));
  const held = JSON.parse(env.CONTENT.values.get(name).value);
  held.absoluteExpiry = new Date(Date.now() - 1000).toISOString();
  await env.CONTENT.put(name, JSON.stringify(held));
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token}), env)).status,
    401,
  );
});

// --- the password ----------------------------------------------------------

test('a password can be set from inside the panel', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const set = await handleRequest(setPassword(token, adminToken, password), env);
  assert.equal(set.status, 200);

  // And it works on its own from then on.
  const signedIn = await handleRequest(signIn(password), env);
  assert.equal(signedIn.status, 200);
});

test('the password is stored stretched, never as itself', async () => {
  const env = environment();
  const token = await sessionFor(env);
  await handleRequest(setPassword(token, adminToken, password), env);
  const record = JSON.parse(env.CONTENT.values.get('auth:password').value);
  assert.ok(!JSON.stringify(record).includes(password));
  assert.match(record.hash, /^[0-9a-f]{64}$/);
  assert.match(record.salt, /^[0-9a-f]{32}$/);
  // Recorded with the hash rather than fixed in code, so the count can be
  // raised later without making every existing password unverifiable.
  assert.ok(record.iterations >= 10000);
});

test('changing the password needs the current one', async () => {
  const env = environment();
  const first = await handleRequest(
    setPassword(await sessionFor(env), adminToken, password),
    env,
  );
  // The change signed every session out, including the one that made it, and
  // handed back a replacement. Anything else would sign the owner out of the
  // tab he is standing in.
  const token = (await first.json()).token;
  const refused = await handleRequest(
    setPassword(token, 'not the password', 'another-long-password'),
    env,
  );
  assert.equal(refused.status, 403);
});

test('a password that is too short is refused', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const refused = await handleRequest(setPassword(token, adminToken, 'short'), env);
  assert.equal(refused.status, 400);
});

test('changing the password signs the other sessions out', async () => {
  // The reason for changing a password is usually that somebody else has one.
  // Leaving their session alive changes nothing for them.
  const env = environment();
  const phone = await sessionFor(env);
  const desk = await sessionFor(env);
  const changed = await handleRequest(setPassword(desk, adminToken, password), env);
  assert.equal(changed.status, 200);

  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token: phone}), env)).status,
    401,
  );
  // And the one that did it is handed a fresh session rather than being
  // thrown out along with the rest.
  const replacement = (await changed.json()).token;
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token: replacement}), env)).status,
    200,
  );
});

test('the deployment secret still works after a password is set', async () => {
  // It is the way back in when the password is forgotten, and the reason a
  // slow or unreachable password store cannot lock the owner out.
  const env = environment();
  const token = await sessionFor(env);
  await handleRequest(setPassword(token, adminToken, password), env);
  assert.equal((await handleRequest(signIn(adminToken), env)).status, 200);
});

test('the panel is told which credential it is signed in with', async () => {
  const env = environment();
  const token = await sessionFor(env);
  const described = await handleRequest(admin('/v1/admin/session', {token}), env);
  const body = await described.json();
  assert.equal(body.kind, 'session');
  assert.equal(body.passwordSet, false);

  await handleRequest(setPassword(token, adminToken, password), env);
  const after = await handleRequest(
    admin('/v1/admin/session', {token: adminToken}),
    env,
  );
  const seen = await after.json();
  assert.equal(seen.kind, 'recovery');
  assert.equal(seen.recovery, true);
  assert.equal(seen.passwordSet, true);
});

// --- being locked out ------------------------------------------------------

test('wrong passwords stop being answered', async () => {
  const env = environment();
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const refused = await handleRequest(signIn('wrong'), env);
    assert.equal(refused.status, 401, `attempt ${attempt}`);
  }
  assert.equal((await handleRequest(signIn('wrong'), env)).status, 429);
});

test('being guessed at does not lock the owner out', async () => {
  const env = environment();
  for (let attempt = 0; attempt < 15; attempt += 1) {
    await handleRequest(signIn('wrong'), env);
  }
  // The whole point. Someone hammering the endpoint used to take the site's
  // own admin down with them.
  assert.equal((await handleRequest(signIn(adminToken), env)).status, 200);
});

test('getting in clears the count', async () => {
  const env = environment();
  for (let attempt = 0; attempt < 11; attempt += 1) {
    await handleRequest(signIn('wrong'), env);
  }
  await handleRequest(signIn(adminToken), env);
  assert.equal((await handleRequest(signIn('wrong'), env)).status, 401);
});

test('signing in needs a password in the body', async () => {
  const empty = await handleRequest(
    new Request('https://worker.example/v1/admin/session', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({}),
    }),
    environment(),
  );
  assert.equal(empty.status, 400);
});

test('the session endpoints are behind the gate', async () => {
  const env = environment();
  for (const request of [
    admin('/v1/admin/session', {token: null}),
    admin('/v1/admin/session', {method: 'DELETE', token: null}),
    admin('/v1/admin/password', {
      method: 'POST',
      body: {current: 'x', next: 'a-long-enough-password'},
      token: null,
    }),
  ]) {
    assert.equal((await handleRequest(request, env)).status, 401);
  }
});

// --- AR-9: twelve hours idle means idle ------------------------------------

/// Moves a session's clocks back, the way waiting would.
function agedBy(env, hours) {
  const name = [...env.CONTENT.values.keys()].find((k) => k.startsWith('session:'));
  const held = JSON.parse(env.CONTENT.values.get(name).value);
  const shift = hours * 60 * 60 * 1000;
  held.expires = new Date(Date.parse(held.expires) - shift).toISOString();
  held.absoluteExpiry = new Date(Date.parse(held.absoluteExpiry) - shift).toISOString();
  env.CONTENT.values.set(name, {value: JSON.stringify(held)});
  return held;
}

function sessionRecord(env) {
  const name = [...env.CONTENT.values.keys()].find((k) => k.startsWith('session:'));
  return JSON.parse(env.CONTENT.values.get(name).value);
}

test('using a session pushes the idle clock back', async () => {
  // The defect: a session that had been in use all day still died twelve
  // hours after it began, because nothing extended it.
  const env = environment();
  const token = await sessionFor(env);
  const before = sessionRecord(env).expires;

  agedBy(env, 11);
  const used = await handleRequest(admin('/v1/admin/content', {token}), env);
  assert.equal(used.status, 200);

  const after = sessionRecord(env).expires;
  assert.ok(Date.parse(after) > Date.parse(before) - 11 * 3600 * 1000);
  assert.ok(Date.parse(after) > Date.now() + 11 * 3600 * 1000);
});

test('a session kept in use keeps working past the idle window', async () => {
  const env = environment();
  const token = await sessionFor(env);
  // Eleven hours, use it, eleven hours again, use it. Under the old rule the
  // second one failed.
  for (const round of [1, 2]) {
    agedBy(env, 11);
    const used = await handleRequest(admin('/v1/admin/content', {token}), env);
    assert.equal(used.status, 200, `round ${round}`);
  }
});

test('a session nobody touches still expires', async () => {
  const env = environment();
  const token = await sessionFor(env);
  agedBy(env, 13);
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token}), env)).status,
    401,
  );
});

test('renewal never pushes past the absolute limit', async () => {
  const env = environment();
  const token = await sessionFor(env);
  // Six days in: renewal may extend the idle clock, but not beyond the seven
  // day ceiling.
  agedBy(env, 6 * 24);
  await handleRequest(admin('/v1/admin/content', {token}), env);
  const held = sessionRecord(env);
  assert.ok(Date.parse(held.expires) <= Date.parse(held.absoluteExpiry));
});

test('the absolute limit still ends a session that is in constant use', async () => {
  const env = environment();
  const token = await sessionFor(env);
  agedBy(env, 8 * 24);
  assert.equal(
    (await handleRequest(admin('/v1/admin/content', {token}), env)).status,
    401,
  );
});

test('an ordinary request does not rewrite the session every time', async () => {
  // Renewal is worth one write, not one per request.
  const env = environment();
  const token = await sessionFor(env);
  const before = sessionRecord(env).expires;
  for (let round = 0; round < 5; round += 1) {
    await handleRequest(admin('/v1/admin/content', {token}), env);
  }
  assert.equal(sessionRecord(env).expires, before);
});
