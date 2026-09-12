// Fixture-only review reproductions. No network, production keys or repository writes.
// Run: node reproduce-afc8969.mjs /absolute/path/to/admin-checkout
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
import {pathToFileURL} from 'node:url';
globalThis.crypto ??= webcrypto;
const checkout = process.argv[2];
if (!checkout) throw new Error('Pass the absolute path to the afc8969 admin checkout');
const source = (path) => pathToFileURL(`${checkout}/${path}`).href;
const {handleRequest} = await import(source('worker/src/index.js'));
const {ContentStore, contentBackend} = await import(source('worker/src/store.js'));
const {durableNamespace} = await import(source('worker/dev/durable-double.js'));
const {admin, adminToken, environment, fixture} = await import(source('worker/test/support.js'));
const transactional = () => environment({CONTENT_STORE: durableNamespace(ContentStore)});
const signIn = (password) => new Request('https://worker.example/v1/admin/session', {
  method: 'POST', body: JSON.stringify({password}),
});

// 1. Independent atomic counter operations do not make admission atomic.
const loginEnv = transactional();
await handleRequest(admin('/v1/admin/password', {
  method: 'POST', body: {current: adminToken, next: 'a-long-test-only-password'},
}), loginEnv);
for (let i = 0; i < 9; i++) await handleRequest(signIn('wrong'), loginEnv);
let derivations = 0;
const originalDerive = crypto.subtle.deriveBits.bind(crypto.subtle);
crypto.subtle.deriveBits = (...args) => {
  derivations++;
  return originalDerive(...args);
};
let responses;
try {
  responses = await Promise.all(Array.from({length: 30}, () =>
    handleRequest(signIn('wrong'), loginEnv)));
} finally {
  crypto.subtle.deriveBits = originalDerive;
}
const statusCounts = responses.reduce((counts, response) => {
  counts[response.status] = (counts[response.status] ?? 0) + 1;
  return counts;
}, {});
console.log('Throttle after 9 failures, then 30 concurrent guesses:', {derivations, statusCounts});
assert.ok(derivations > 1, 'Review defect reproduced: more than the one remaining attempt was admitted');

// 2. Interleave a real commit between the two real store reads.
const readEnv = transactional();
const document = await fixture('interests.json');
await contentBackend(readEnv).commit({
  file: 'interests.json', kind: 'publish', document, base: 0, at: new Date().toISOString(),
});
const namespace = readEnv.CONTENT_STORE;
const originalGet = namespace.get.bind(namespace);
let intercepted = false;
namespace.get = (...args) => {
  const stub = originalGet(...args);
  return {fetch: async (url, init) => {
    const request = JSON.parse(init.body);
    const answer = await stub.fetch(url, init);
    if (request.op === 'head' && !intercepted) {
      intercepted = true;
      const changed = structuredClone(document);
      changed.interests[0].label.en = 'Revision two';
      await stub.fetch(url, {method: 'POST', body: JSON.stringify({
        op: 'commit', file: 'interests.json', kind: 'publish', document: changed,
        base: 1, at: new Date().toISOString(),
      })});
    }
    return answer;
  }};
};
const editorRead = await (await handleRequest(admin('/v1/admin/content/interests.json'), readEnv)).json();
console.log('Editor read with intervening commit:', {
  revision: editorRead.revision, label: editorRead.document.interests[0].label.en,
});
assert.equal(editorRead.revision, 1);
assert.equal(editorRead.document.interests[0].label.en, 'Revision two');

// 3. Hold a renewal write, sign out, then allow that stale write to finish.
const sessionEnv = transactional();
const initialTime = new Date('2026-09-12T00:00:00Z');
const renewalTime = new Date('2026-09-12T11:00:00Z');
const {token} = await (await handleRequest(signIn(adminToken), sessionEnv, initialTime)).json();
const originalPut = sessionEnv.CONTENT.put.bind(sessionEnv.CONTENT);
let entered;
const renewalEntered = new Promise((resolve) => { entered = resolve; });
let release;
const renewalGate = new Promise((resolve) => { release = resolve; });
let firstRenewal = true;
sessionEnv.CONTENT.put = async (key, value, ...rest) => {
  if (firstRenewal && key.startsWith('session:')) {
    firstRenewal = false;
    entered();
    await renewalGate;
  }
  return originalPut(key, value, ...rest);
};
const inFlight = handleRequest(admin('/v1/admin/content', {token}), sessionEnv, renewalTime);
await renewalEntered;
const signedOut = await handleRequest(admin('/v1/admin/session', {
  method: 'DELETE', token,
}), sessionEnv, renewalTime);
release();
await inFlight;
const afterLogout = await handleRequest(admin('/v1/admin/content', {token}), sessionEnv, renewalTime);
console.log('Session resurrection:', {logoutStatus: signedOut.status, oldTokenStatusAfterRenewal: afterLogout.status});
assert.equal(signedOut.status, 200);
assert.equal(afterLogout.status, 200);
console.log('All three afc8969 defects reproduced. Assertions here confirm the defects, not the corrected behavior.');
