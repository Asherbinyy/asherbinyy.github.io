import assert from 'node:assert/strict';
import test from 'node:test';

import worker, {
  aggregateSnapshot,
  currentSalt,
  handleRequest,
  relayCover,
  relayWriting,
  rotateSalt,
  sendLondonNoonDigest,
  verifySaltRotation,
} from '../src/index.js';

const siteOrigin = 'https://asherbinyy.github.io';
const consoleToken = 'a'.repeat(32);

class MemoryKv {
  values = new Map();
  writes = [];

  async get(name, type) {
    const entry = this.values.get(name);
    if (entry === undefined) return null;
    return type === 'json' ? JSON.parse(entry.value) : entry.value;
  }

  async put(name, value, options = {}) {
    this.values.set(name, {value, options});
    this.writes.push({name, value, options});
  }

  async getWithMetadata(name, type) {
    const entry = this.values.get(name);
    if (entry === undefined) return {value: null, metadata: null};
    return {
      value: type === 'arrayBuffer' ? entry.value : entry.value,
      metadata: entry.options.metadata ?? null,
    };
  }

  async delete(name) {
    this.values.delete(name);
  }

  async list({prefix = '', cursor} = {}) {
    assert.equal(cursor, undefined);
    return {
      keys: [...this.values.keys()]
        .filter((name) => name.startsWith(prefix))
        .sort()
        .map((name) => ({
          name,
          metadata: this.values.get(name).options.metadata,
        })),
      list_complete: true,
    };
  }
}

function environment(overrides = {}) {
  return {
    ANALYTICS: new MemoryKv(),
    CONSOLE_TOKEN: consoleToken,
    SITE_ID: 'asherbinyy.github.io',
    SITE_ORIGIN: siteOrigin,
    ...overrides,
  };
}

function beaconRequest(body = {}, headers = {}) {
  return new Request(`${siteOrigin}/v1/beacon`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      origin: siteOrigin,
      ...headers,
    },
    body: JSON.stringify({
      event: 'route_view',
      route: '/work',
      deviceClass: 'pointer',
      referrerHost: 'example.com',
      campaign: 'graduate-role',
      ...body,
    }),
  });
}

function withCloudflareProperties(request, properties) {
  Object.defineProperty(request, 'cf', {value: properties});
  return request;
}

test('a route view persists no raw IP or user agent', async () => {
  const env = environment();
  const address = '203.0.113.42';
  const agent = 'Private test browser';
  const request = withCloudflareProperties(
    beaconRequest({}, {'cf-connecting-ip': address, 'user-agent': agent}),
    {country: 'GB'},
  );

  const result = await handleRequest(
    request,
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 202);
  assert.equal(env.ANALYTICS.values.size, 4);
  const persisted = JSON.stringify([...env.ANALYTICS.values.entries()]);
  assert.equal(persisted.includes(address), false);
  assert.equal(persisted.includes(agent), false);
  assert.equal(
    [...env.ANALYTICS.values.keys()].filter((key) => key.startsWith('visitor|'))
      .length,
    1,
  );
});

test('the same daily visitor is counted once across route views', async () => {
  const env = environment();
  const now = new Date('2026-09-06T09:00:00Z');
  const headers = {'cf-connecting-ip': '203.0.113.9', 'user-agent': 'Browser'};

  await handleRequest(beaconRequest({}, headers), env, now);
  await handleRequest(beaconRequest({}, headers), env, now);

  const {counters} = await aggregateSnapshot(env);
  const unique = counters.find(({dimensions}) =>
    dimensions.includes('unique_visitor'),
  );
  const routeViews = counters.find(({dimensions}) =>
    dimensions.includes('route_view'),
  );
  assert.equal(unique.count, 1);
  assert.equal(routeViews.count, 2);
});

test('the active salt is younger than 24 hours', async () => {
  const env = environment();
  const now = new Date('2026-09-06T12:00:00Z');

  const salt = await currentSalt(env, now);

  assert.ok(now.getTime() - salt.createdAt < 24 * 60 * 60 * 1000);
  assert.equal(salt.value.length, 64);
});

test('rotation overwrites the previous salt without retaining it', async () => {
  const env = environment();
  const first = await rotateSalt(env, new Date('2026-09-05T00:00:00Z'));
  const second = await rotateSalt(env, new Date('2026-09-06T00:00:00Z'));

  assert.notEqual(first.value, second.value);
  assert.equal(env.ANALYTICS.values.size, 1);
  const persisted = JSON.stringify([...env.ANALYTICS.values.entries()]);
  assert.equal(persisted.includes(first.value), false);
  assert.equal(persisted.includes(second.value), true);
});

test('the midnight schedule rotates the salt', async () => {
  const env = environment();

  await worker.scheduled(
    {cron: '0 0 * * *', scheduledTime: Date.parse('2026-09-06T00:00:00Z')},
    env,
  );

  assert.equal(env.ANALYTICS.writes[0].name, 'system|salt');
});

test('an expired salt alerts and is replaced', async () => {
  const env = environment({ALERT_WEBHOOK_URL: 'https://hooks.example/alert'});
  const expired = await rotateSalt(env, new Date('2026-09-05T00:00:00Z'));
  const calls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    calls.push({url, options});
    return new Response(null, {status: 204});
  };

  try {
    const current = await verifySaltRotation(
      env,
      new Date('2026-09-06T00:00:01Z'),
    );
    const replacement = await env.ANALYTICS.get('system|salt', 'json');

    assert.equal(current, false);
    assert.equal(calls.length, 1);
    assert.notEqual(replacement.value, expired.value);
    assert.equal(
      JSON.stringify([...env.ANALYTICS.values.entries()]).includes(expired.value),
      false,
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('the London noon digest is sent once per local date', async () => {
  const env = environment({DIGEST_WEBHOOK_URL: 'https://hooks.example/digest'});
  const calls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    calls.push({url, options});
    return new Response(null, {status: 204});
  };

  try {
    const beforeNoon = await sendLondonNoonDigest(
      env,
      new Date('2026-09-06T10:00:00Z'),
    );
    const atNoon = await sendLondonNoonDigest(
      env,
      new Date('2026-09-06T11:00:00Z'),
    );
    const duplicate = await sendLondonNoonDigest(
      env,
      new Date('2026-09-06T11:30:00Z'),
    );

    assert.equal(beforeNoon, false);
    assert.equal(atNoon, true);
    assert.equal(duplicate, false);
    assert.equal(calls.length, 1);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('aggregate reads reject a missing console token', async () => {
  const env = environment();

  const result = await handleRequest(
    new Request(`${siteOrigin}/v1/aggregates`),
    env,
  );

  assert.equal(result.status, 401);
});

test('authenticated reads expose counters but not salt or visitor keys', async () => {
  const env = environment();
  await handleRequest(beaconRequest(), env, new Date('2026-09-06T09:00:00Z'));

  const result = await handleRequest(
    new Request(`${siteOrigin}/v1/aggregates`, {
      headers: {authorization: `Bearer ${consoleToken}`},
    }),
    env,
  );
  const body = await result.json();

  assert.equal(result.status, 200);
  assert.ok(body.counters.length > 0);
  assert.equal(JSON.stringify(body).includes('system|salt'), false);
  assert.equal(JSON.stringify(body).includes('visitor|'), false);
});

test('unexpected fields are rejected without writes', async () => {
  const env = environment();

  const result = await handleRequest(
    beaconRequest({ip: '203.0.113.42'}),
    env,
  );

  assert.equal(result.status, 400);
  assert.equal(env.ANALYTICS.writes.length, 0);
});

test('beacons from another origin are rejected', async () => {
  const env = environment();
  const request = beaconRequest();
  request.headers.set('origin', 'https://example.com');

  const result = await handleRequest(request, env);

  assert.equal(result.status, 403);
  assert.equal(env.ANALYTICS.writes.length, 0);
});

test('a missing KV binding fails closed', async () => {
  const result = await handleRequest(beaconRequest(), {
    CONSOLE_TOKEN: consoleToken,
    SITE_ID: 'asherbinyy.github.io',
    SITE_ORIGIN: siteOrigin,
  });

  assert.equal(result.status, 503);
});

const sampleFeed = `<?xml version="1.0"?><rss version="2.0"><channel>
<item><title>One</title><link>https://sherbini.medium.com/one</link></item>
</channel></rss>`;

function writingRequest(headers = {}) {
  return new Request(`${siteOrigin}/v1/writing`, {
    method: 'GET',
    headers: {origin: siteOrigin, ...headers},
  });
}

function stubFetch(responses) {
  const calls = [];
  const impl = async (url, init) => {
    calls.push({url, init});
    const next = responses.shift();
    if (next instanceof Error) throw next;
    return next;
  };
  impl.calls = calls;
  return impl;
}

test('the writing relay refuses a request from another origin', async () => {
  const env = environment({WRITING_FEED_URL: 'https://feed.example/feed'});

  const result = await handleRequest(
    writingRequest({origin: 'https://elsewhere.example'}),
    env,
  );

  assert.equal(result.status, 403);
});

test('the writing relay returns the feed verbatim and caches it', async () => {
  const env = environment({WRITING_FEED_URL: 'https://feed.example/feed'});
  const now = new Date('2026-09-06T09:00:00Z');
  const fetchImpl = stubFetch([new Response(sampleFeed, {status: 200})]);

  const result = await relayWriting(env, now, new Headers(), fetchImpl);

  assert.equal(result.status, 200);
  assert.equal(await result.text(), sampleFeed);
  assert.equal(result.headers.get('x-nocturne-cache'), 'miss');
  assert.equal(await env.ANALYTICS.get('writing:feed'), sampleFeed);
});

test('a cached feed is served without asking Medium again', async () => {
  const env = environment({WRITING_FEED_URL: 'https://feed.example/feed'});
  const now = new Date('2026-09-06T09:00:00Z');
  await env.ANALYTICS.put('writing:feed', sampleFeed);
  const fetchImpl = stubFetch([]);

  const result = await relayWriting(env, now, new Headers(), fetchImpl);

  assert.equal(result.headers.get('x-nocturne-cache'), 'hit');
  assert.equal(fetchImpl.calls.length, 0);
});

test('the relay reports a failed feed rather than an empty one', async () => {
  const env = environment({WRITING_FEED_URL: 'https://feed.example/feed'});
  const now = new Date('2026-09-06T09:00:00Z');
  const fetchImpl = stubFetch([new Error('network down')]);

  const result = await relayWriting(env, now, new Headers(), fetchImpl);

  // An empty 200 would be indistinguishable from "nothing published", and the
  // client decides to hide the section either way — but only one of the two is
  // worth retrying.
  assert.equal(result.status, 502);
  assert.equal(await env.ANALYTICS.get('writing:feed'), null);
});

test('the relay forwards nothing about the viewer', async () => {
  const env = environment({WRITING_FEED_URL: 'https://feed.example/feed'});
  const now = new Date('2026-09-06T09:00:00Z');
  const fetchImpl = stubFetch([new Response(sampleFeed, {status: 200})]);

  await relayWriting(env, now, new Headers(), fetchImpl);

  const [call] = fetchImpl.calls;
  const forwarded = Object.keys(call.init.headers).map((n) => n.toLowerCase());
  assert.deepEqual(forwarded, ['accept']);
});

test('the relay refuses to run without a configured feed', async () => {
  const env = environment();
  const result = await relayWriting(env, new Date(), new Headers());
  assert.equal(result.status, 503);
});

test('a Tier 1 event may carry a session identifier', async () => {
  const env = environment();
  const sessionId = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

  const result = await handleRequest(
    beaconRequest({event: 'map_node_opened', sessionId, value: null}),
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 202);
  // It deduplicates within the request and is then discarded: no stored key
  // may contain it, or a counter could be traced back to one viewer's tab.
  const stored = JSON.stringify([...env.ANALYTICS.values.keys()]);
  assert.ok(!stored.includes(sessionId));
});

test('a Tier 0 route view may not carry a session identifier', async () => {
  const env = environment();

  const result = await handleRequest(
    beaconRequest({sessionId: 'a1b2c3d4e5f60718293a4b5c6d7e8f90'}),
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 400);
});

test('a malformed session identifier is rejected', async () => {
  const env = environment();

  const result = await handleRequest(
    beaconRequest({event: 'theme_changed', sessionId: 'not-a-hash'}),
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 400);
});

test('scroll depth accumulates a total beside its counter', async () => {
  const env = environment();
  const now = new Date('2026-09-06T09:00:00Z');

  await handleRequest(
    beaconRequest({event: 'scroll_depth', value: 3, campaign: null}),
    env,
    now,
  );
  await handleRequest(
    beaconRequest({event: 'scroll_depth', value: 4, campaign: null}),
    env,
    now,
  );

  assert.equal(
    await env.ANALYTICS.get('total|2026-09-06|scroll_depth|%2Fwork'),
    '7',
  );
});

test('a value outside its event range is rejected', async () => {
  const env = environment();

  for (const value of [0, 5, 1.5]) {
    const result = await handleRequest(
      beaconRequest({event: 'scroll_depth', value}),
      env,
      new Date('2026-09-06T09:00:00Z'),
    );
    assert.equal(result.status, 400, `value ${value} should be rejected`);
  }
});

test('an event that carries no value rejects one', async () => {
  const env = environment();

  const result = await handleRequest(
    beaconRequest({event: 'theme_changed', value: 3}),
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 400);
});

test('a dwell longer than an hour is rejected as a forgotten tab', async () => {
  const env = environment();

  const result = await handleRequest(
    beaconRequest({event: 'section_dwell', value: 3601}),
    env,
    new Date('2026-09-06T09:00:00Z'),
  );

  assert.equal(result.status, 400);
});

test('the digest payload carries counters and totals at the top level', async () => {
  const posted = [];
  const env = environment({DIGEST_WEBHOOK_URL: 'https://hooks.example/digest'});
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    posted.push(JSON.parse(init.body));
    return new Response('{}', {status: 200});
  };

  try {
    await handleRequest(
      beaconRequest({event: 'scroll_depth', value: 3, campaign: null}),
      env,
      new Date('2026-09-06T09:00:00Z'),
    );
    // 12:00 in London is 11:00 UTC while British Summer Time is in effect.
    await sendLondonNoonDigest(env, new Date('2026-09-06T11:00:00Z'));
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(posted.length, 1);
  assert.ok(Array.isArray(posted[0].counters), 'counters must be an array');
  assert.ok(Array.isArray(posted[0].totals), 'totals must be an array');
  assert.ok(posted[0].generatedAt);
});

// --- /v1/cover -------------------------------------------------------------
//
// The covers come through this Worker for the same reason the feed does: so
// that visiting /writing issues no request carrying the viewer's IP to Medium.
// These tests are mostly about the endpoint NOT being an open proxy, since its
// target arrives in a query string.

const okImage = (type = 'image/jpeg', bytes = 1024) =>
  new Response('x'.repeat(bytes), {
    status: 200,
    headers: {'content-type': type, 'content-length': String(bytes)},
  });

test('a cover on an allowed host is streamed through this origin', async () => {
  const response = await relayCover(
    'https://miro.medium.com/v2/resize:fit:1400/abc.jpeg',
    new Headers(),
    async () => okImage(),
  );
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'image/jpeg');
  assert.match(response.headers.get('cache-control'), /max-age=86400/);
});

test('a cover on any other host is refused', async () => {
  for (const src of [
    'https://evil.example/pixel.png',
    'https://medium.com.evil.example/a.png',
    'https://internal.local/secret.png',
  ]) {
    const response = await relayCover(src, new Headers(), async () => {
      throw new Error('must not be fetched');
    });
    assert.equal(response.status, 403, src);
  }
});

test('a non-https cover is refused', async () => {
  const response = await relayCover(
    'http://miro.medium.com/a.jpeg',
    new Headers(),
    async () => okImage(),
  );
  assert.equal(response.status, 403);
});

test('a missing or unparseable src is a bad request', async () => {
  assert.equal((await relayCover(null, new Headers())).status, 400);
  assert.equal((await relayCover('not a url', new Headers())).status, 400);
});

test('an allowed host serving something other than an image is refused', async () => {
  const response = await relayCover(
    'https://miro.medium.com/a.jpeg',
    new Headers(),
    async () => okImage('text/html'),
  );
  assert.equal(response.status, 415);
});

test('an oversized cover is refused before it is streamed', async () => {
  const response = await relayCover(
    'https://miro.medium.com/a.jpeg',
    new Headers(),
    async () =>
      new Response('x', {
        status: 200,
        headers: {
          'content-type': 'image/jpeg',
          'content-length': String(9_000_000),
        },
      }),
  );
  assert.equal(response.status, 413);
});

test('an upstream failure is a gateway error, not an empty image', async () => {
  const response = await relayCover(
    'https://miro.medium.com/a.jpeg',
    new Headers(),
    async () => new Response('', {status: 500}),
  );
  assert.equal(response.status, 502);
});

test('a cover request from another origin is refused', async () => {
  const response = await handleRequest(
    new Request(
      'https://relay.example/v1/cover?src=https%3A%2F%2Fmiro.medium.com%2Fa.jpeg',
      {headers: {origin: 'https://not-the-site.example'}},
    ),
    {ANALYTICS: new MemoryKv(), SITE_ORIGIN: siteOrigin, CONSOLE_TOKEN: consoleToken},
    new Date(),
  );
  assert.equal(response.status, 403);
});

// --- published content, milestone 7 ----------------------------------------

const adminToken = 'b'.repeat(48);

/// An environment with the content store bound and an admin token set.
function publishing(overrides = {}) {
  return environment({
    CONTENT: new MemoryKv(),
    ADMIN_TOKEN: adminToken,
    ...overrides,
  });
}

function adminRequest(path, {method = 'GET', body, token = adminToken} = {}) {
  return new Request(`https://worker.example${path}`, {
    method,
    headers: token
      ? {authorization: `Bearer ${token}`, 'content-type': 'application/json'}
      : {'content-type': 'application/json'},
    body,
  });
}

function siteRequest(path) {
  return new Request(`https://worker.example${path}`, {
    headers: {origin: siteOrigin},
  });
}

test('a document with nothing published is not found', async () => {
  const response = await handleRequest(
    siteRequest('/v1/content/profile.json'),
    publishing(),
  );
  // The site treats this as "use the bundle", so it is the ordinary answer
  // rather than an error anyone has to handle.
  assert.equal(response.status, 404);
});

test('a published document comes back to the site', async () => {
  const env = publishing();
  const document = {
    name: {en: 'Ahmed'},
    positioning: {en: 'Mobile developer'},
    contact: {email: 'someone@example.com'},
  };
  const put = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify(document),
    }),
    env,
  );
  assert.equal(put.status, 200);

  const read = await handleRequest(siteRequest('/v1/content/profile.json'), env);
  assert.equal(read.status, 200);
  // The document itself, not an envelope: the site parses this straight into
  // its content models.
  assert.deepEqual(await read.json(), document);
});

test('withdrawing a document returns the site to its bundle', async () => {
  const env = publishing();
  await handleRequest(
    adminRequest('/v1/admin/content/career.json', {
      method: 'PUT',
      body: JSON.stringify({roles: []}),
    }),
    env,
  );
  const removed = await handleRequest(
    adminRequest('/v1/admin/content/career.json', {method: 'DELETE'}),
    env,
  );
  assert.equal(removed.status, 200);

  const read = await handleRequest(siteRequest('/v1/content/career.json'), env);
  assert.equal(read.status, 404);
});

test('only the documents on the list can be published', async () => {
  // The path segment reaches KV. Without the allowlist an admin request could
  // write any key in the namespace, including the analytics counters.
  const env = publishing();
  for (const file of ['salt', 'anything.json', 'fallback.json', 'profile']) {
    const written = await handleRequest(
      adminRequest(`/v1/admin/content/${file}`, {
        method: 'PUT',
        body: JSON.stringify({}),
      }),
      env,
    );
    assert.equal(written.status, 400, file);
  }
  assert.deepEqual(env.CONTENT.writes, []);
});

test('a path that climbs out of the content prefix is refused', async () => {
  // `URL` normalises `..` away before the handler sees it, so this lands on a
  // path that matches no route rather than on the allowlist. Asserted anyway,
  // and asserted on the write rather than the status: the guarantee that
  // matters is that nothing reached the store, and it must hold whichever of
  // the two refusals happens to catch it.
  const env = publishing();
  for (const path of [
    '/v1/admin/content/../salt',
    '/v1/admin/content/..%2Fsalt',
    '/v1/admin/content/nested/profile.json',
  ]) {
    const written = await handleRequest(
      adminRequest(path, {method: 'PUT', body: JSON.stringify({})}),
      env,
    );
    assert.ok(written.status >= 400, path);
  }
  assert.deepEqual(env.CONTENT.writes, []);
});

test('a document that is not JSON is refused at the door', async () => {
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: '{ not json',
    }),
    env,
  );
  // The site would survive this -- it falls back -- but the owner would not
  // know he had published something broken.
  assert.equal(written.status, 400);
  assert.deepEqual(env.CONTENT.writes, []);
});

test('a document that is not an object is refused', async () => {
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify([1, 2, 3]),
    }),
    env,
  );
  assert.equal(written.status, 400);
});

test('an oversized document is refused', async () => {
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify({padding: 'x'.repeat(300 * 1024)}),
    }),
    env,
  );
  assert.equal(written.status, 413);
});

test('writing without a token is refused', async () => {
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify({}),
      token: null,
    }),
    env,
  );
  assert.equal(written.status, 401);
  assert.deepEqual(env.CONTENT.writes, []);
});

test('writing with the wrong token is refused', async () => {
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify({}),
      token: 'c'.repeat(48),
    }),
    env,
  );
  assert.equal(written.status, 401);
});

test('the console token does not open the admin endpoints', async () => {
  // Two different jobs and two different secrets. The console token is handed
  // to a dashboard that only reads counters; it must not also be able to
  // rewrite what the site says about the owner.
  const env = publishing();
  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify({}),
      token: consoleToken,
    }),
    env,
  );
  assert.equal(written.status, 401);
});

test('repeated wrong tokens stop being answered', async () => {
  const env = publishing();
  for (let attempt = 0; attempt < 10; attempt++) {
    const refused = await handleRequest(
      adminRequest('/v1/admin/content', {token: 'c'.repeat(48)}),
      env,
    );
    assert.equal(refused.status, 401, `attempt ${attempt}`);
  }
  const limited = await handleRequest(
    adminRequest('/v1/admin/content', {token: 'c'.repeat(48)}),
    env,
  );
  assert.equal(limited.status, 429);

  // And the right token is refused too while the limit holds: the point is
  // that the endpoint stops answering, not that it keeps a door open.
  const correct = await handleRequest(adminRequest('/v1/admin/content'), env);
  assert.equal(correct.status, 429);
});

test('a correct token does not count against the limit', async () => {
  const env = publishing();
  for (let attempt = 0; attempt < 20; attempt++) {
    const listed = await handleRequest(adminRequest('/v1/admin/content'), env);
    assert.equal(listed.status, 200);
  }
});

test('the listing says what is currently published', async () => {
  const env = publishing();
  await handleRequest(
    adminRequest('/v1/admin/content/apps.json', {
      method: 'PUT',
      body: JSON.stringify({apps: []}),
    }),
    env,
  );
  const listed = await handleRequest(adminRequest('/v1/admin/content'), env);
  const listing = await listed.json();
  assert.deepEqual(listing.published, ['apps.json']);
  // The revision each published document is at, so the panel can name a base
  // when it publishes rather than asking per document.
  assert.equal(listing.heads['apps.json'], 1);
});

test('a site read from another origin is refused', async () => {
  const env = publishing();
  const read = await handleRequest(
    new Request('https://worker.example/v1/content/profile.json', {
      headers: {origin: 'https://example.com'},
    }),
    env,
  );
  assert.equal(read.status, 403);
});

test('with no content store bound the site simply reads its bundle', async () => {
  // The namespace has to be created by hand. Until it is, this Worker deploys
  // and behaves exactly as it did before.
  const env = environment({ADMIN_TOKEN: adminToken});
  const read = await handleRequest(siteRequest('/v1/content/profile.json'), env);
  assert.equal(read.status, 404);

  const written = await handleRequest(
    adminRequest('/v1/admin/content/profile.json', {
      method: 'PUT',
      body: JSON.stringify({}),
    }),
    env,
  );
  assert.equal(written.status, 503);
});

// --- published media, milestone 7.2 ----------------------------------------

/// The smallest byte sequence each decoder will read a size out of.
///
/// Built rather than fixtured: what is under test is the header parsing, and a
/// hand-laid header states the offsets it depends on where a binary blob
/// would hide them.
function pngBytes(width, height) {
  const bytes = new Uint8Array(32);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  const view = new DataView(bytes.buffer);
  view.setUint32(8, 13);
  bytes.set([73, 72, 68, 82], 12); // "IHDR"
  view.setUint32(16, width);
  view.setUint32(20, height);
  return bytes;
}

function jpegBytes(width, height) {
  const bytes = new Uint8Array(20);
  const view = new DataView(bytes.buffer);
  bytes.set([0xff, 0xd8, 0xff, 0xc0]);
  view.setUint16(4, 17); // segment length
  bytes[6] = 8; // sample precision
  view.setUint16(7, height);
  view.setUint16(9, width);
  return bytes;
}

function webpBytes(width, height) {
  const bytes = new Uint8Array(40);
  const encoder = new TextEncoder();
  bytes.set(encoder.encode('RIFF'), 0);
  bytes.set(encoder.encode('WEBP'), 8);
  bytes.set(encoder.encode('VP8X'), 12);
  const write24 = (at, value) => {
    bytes[at] = value & 0xff;
    bytes[at + 1] = (value >> 8) & 0xff;
    bytes[at + 2] = (value >> 16) & 0xff;
  };
  write24(24, width - 1);
  write24(27, height - 1);
  return bytes;
}

function uploadRequest(body, {type = 'image/png', token = adminToken} = {}) {
  return new Request('https://worker.example/v1/admin/media', {
    method: 'POST',
    headers: {authorization: `Bearer ${token}`, 'content-type': type},
    body,
  });
}

test('an uploaded image comes back at its own address', async () => {
  const env = publishing();
  const uploaded = await handleRequest(uploadRequest(pngBytes(320, 200)), env);
  assert.equal(uploaded.status, 200);
  const {id, url, width, height} = await uploaded.json();
  assert.match(id, /^[0-9a-f]{32}$/);
  assert.equal(url, `/v1/media/${id}`);
  assert.equal(width, 320);
  assert.equal(height, 200);

  const read = await handleRequest(
    new Request(`https://worker.example${url}`),
    env,
  );
  assert.equal(read.status, 200);
  assert.equal(read.headers.get('content-type'), 'image/png');
});

test('media is readable without an Origin header', async () => {
  // Image elements send none. Gating these the way every other read is gated
  // would 403 the only way they are ever actually fetched.
  const env = publishing();
  const uploaded = await handleRequest(uploadRequest(pngBytes(64, 64)), env);
  const {url} = await uploaded.json();

  const read = await handleRequest(
    new Request(`https://worker.example${url}`),
    env,
  );
  assert.equal(read.status, 200);
});

test('an image is cached for a year because its name is its hash', async () => {
  const env = publishing();
  const uploaded = await handleRequest(uploadRequest(pngBytes(64, 64)), env);
  const {url} = await uploaded.json();
  const read = await handleRequest(
    new Request(`https://worker.example${url}`),
    env,
  );
  assert.match(read.headers.get('cache-control'), /immutable/);
});

test('the same image twice is stored once', async () => {
  const env = publishing();
  const first = await handleRequest(uploadRequest(pngBytes(100, 100)), env);
  const second = await handleRequest(uploadRequest(pngBytes(100, 100)), env);
  assert.equal((await first.json()).id, (await second.json()).id);
  assert.equal(env.CONTENT.values.size, 1);
});

test('jpeg and webp are read as well as png', async () => {
  const env = publishing();
  const jpeg = await handleRequest(
    uploadRequest(jpegBytes(640, 480), {type: 'image/jpeg'}),
    env,
  );
  assert.deepEqual(
    {width: (await jpeg.clone().json()).width, height: (await jpeg.json()).height},
    {width: 640, height: 480},
  );

  const webp = await handleRequest(
    uploadRequest(webpBytes(800, 600), {type: 'image/webp'}),
    env,
  );
  assert.deepEqual(
    {width: (await webp.clone().json()).width, height: (await webp.json()).height},
    {width: 800, height: 600},
  );
});

test('an SVG is refused', async () => {
  // Markup that can carry script. Accepting it would be stored XSS on the
  // owner's own domain.
  const env = publishing();
  const svg = '<svg xmlns="http://www.w3.org/2000/svg"><script/></svg>';
  const refused = await handleRequest(
    uploadRequest(svg, {type: 'image/svg+xml'}),
    env,
  );
  assert.equal(refused.status, 415);
  assert.deepEqual(env.CONTENT.writes, []);
});

test('HTML is refused even when it claims to be an image', async () => {
  const env = publishing();
  const refused = await handleRequest(
    uploadRequest('<html><script>alert(1)</script></html>', {type: 'image/png'}),
    env,
  );
  // Refused on what the bytes are, not on what the request says they are.
  assert.equal(refused.status, 400);
  assert.deepEqual(env.CONTENT.writes, []);
});

test('a png that is really a jpeg is refused', async () => {
  const env = publishing();
  const refused = await handleRequest(
    uploadRequest(jpegBytes(64, 64), {type: 'image/png'}),
    env,
  );
  assert.equal(refused.status, 400);
});

test('an oversized image is refused', async () => {
  const env = publishing();
  const big = pngBytes(64, 64);
  const padded = new Uint8Array(5 * 1024 * 1024);
  padded.set(big);
  const refused = await handleRequest(uploadRequest(padded), env);
  assert.equal(refused.status, 413);
});

test('absurd dimensions are refused', async () => {
  const env = publishing();
  for (const [width, height] of [[1, 1], [9000, 100], [100, 9000], [0, 0]]) {
    const refused = await handleRequest(
      uploadRequest(pngBytes(width, height)),
      env,
    );
    assert.equal(refused.status, 400, `${width}x${height}`);
  }
  assert.deepEqual(env.CONTENT.writes, []);
});

test('an empty body is refused', async () => {
  const env = publishing();
  const refused = await handleRequest(uploadRequest(new Uint8Array(0)), env);
  assert.equal(refused.status, 400);
});

test('uploading without a token is refused', async () => {
  const env = publishing();
  const refused = await handleRequest(
    new Request('https://worker.example/v1/admin/media', {
      method: 'POST',
      headers: {'content-type': 'image/png'},
      body: pngBytes(64, 64),
    }),
    env,
  );
  assert.equal(refused.status, 401);
  assert.deepEqual(env.CONTENT.writes, []);
});

test('a media id that is not a hash is not found', async () => {
  const env = publishing();
  for (const id of ['../salt', 'nope', 'a'.repeat(31), 'A'.repeat(32)]) {
    const read = await handleRequest(
      new Request(`https://worker.example/v1/media/${id}`),
      env,
    );
    assert.equal(read.status, 404, id);
  }
});

test('media can be listed and removed', async () => {
  const env = publishing();
  const uploaded = await handleRequest(uploadRequest(pngBytes(200, 150)), env);
  const {id} = await uploaded.json();

  const listed = await handleRequest(adminRequest('/v1/admin/media'), env);
  const {media} = await listed.json();
  assert.equal(media.length, 1);
  // The fields the library draws a row from. Asserted by name rather than as
  // a whole-shape snapshot, so adding one to the listing is not a test change.
  assert.equal(media[0].id, id);
  assert.equal(media[0].kind, 'image');
  assert.equal(media[0].type, 'image/png');
  assert.equal(media[0].width, 200);
  assert.equal(media[0].height, 150);
  assert.equal(media[0].bytes, 32);
  assert.equal(media[0].url, `/v1/media/${id}`);

  const removed = await handleRequest(
    adminRequest(`/v1/admin/media/${id}`, {method: 'DELETE'}),
    env,
  );
  assert.equal(removed.status, 200);
  const gone = await handleRequest(
    new Request(`https://worker.example/v1/media/${id}`),
    env,
  );
  assert.equal(gone.status, 404);
});

// --- the panel, milestone 7.4 and 7.5 --------------------------------------

test('the panel is served at /admin', async () => {
  const page = await handleRequest(
    new Request('https://worker.example/admin'),
    publishing(),
  );
  assert.equal(page.status, 200);
  assert.match(page.headers.get('content-type'), /text\/html/);

  const html = await page.text();
  // The five documents the owner is allowed to edit, and the token gate.
  for (const file of ['profile.json', 'career.json', 'education.json']) {
    assert.ok(html.includes(file), file);
  }
  assert.ok(html.includes('Admin token'));
});

test('the panel is not indexable and cannot be framed', async () => {
  const page = await handleRequest(
    new Request('https://worker.example/admin'),
    publishing(),
  );
  assert.match(page.headers.get('x-robots-tag'), /noindex/);
  assert.match(page.headers.get('content-security-policy'), /frame-ancestors 'none'/);
  // It handles a token that can rewrite the site, so where it may talk to is
  // the header that matters most.
  assert.match(
    page.headers.get('content-security-policy'),
    /connect-src 'self' https:\/\/asherbinyy\.github\.io/,
  );
});

test('the panel warns about the documents a recruiter checks', async () => {
  const html = await (
    await handleRequest(new Request('https://worker.example/admin'), publishing())
  ).text();
  assert.match(html, /recruiter checks against your CV/);
  assert.match(html, /publishing needs a source/);
});

test('a source given for a changed figure is recorded', async () => {
  const env = publishing();
  const published = await handleRequest(
    new Request('https://worker.example/v1/admin/content/education.json', {
      method: 'PUT',
      headers: {
        authorization: `Bearer ${adminToken}`,
        'content-type': 'application/json',
        'x-change-note': encodeURIComponent('Transcript, 2026-09-09'),
      },
      body: JSON.stringify({
        entries: [
          {
            institution: {en: 'A university'},
            award: {en: 'MSc'},
            start: '2025-09',
            end: '2026-09',
            overallMark: 75,
          },
        ],
      }),
    }),
    env,
  );
  assert.equal(published.status, 200);

  const changes = await handleRequest(adminRequest('/v1/admin/changes'), env);
  const body = await changes.json();
  assert.equal(body.changes.length, 1);
  assert.equal(body.changes[0].file, 'education.json');
  assert.equal(body.changes[0].note, 'Transcript, 2026-09-09');
});

test('publishing without a note records nothing', async () => {
  // A source belongs to the act of publishing, not to the content, and an
  // empty one must not be written as though it were an answer.
  const env = publishing();
  await handleRequest(
    adminRequest('/v1/admin/content/apps.json', {
      method: 'PUT',
      body: JSON.stringify({apps: []}),
    }),
    env,
  );
  const changes = await handleRequest(adminRequest('/v1/admin/changes'), env);
  assert.deepEqual(await changes.json(), {changes: []});
});

test('the change log needs the admin token', async () => {
  const refused = await handleRequest(
    adminRequest('/v1/admin/changes', {token: null}),
    publishing(),
  );
  assert.equal(refused.status, 401);
});
