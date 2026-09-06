import assert from 'node:assert/strict';
import test from 'node:test';

import worker, {
  aggregateSnapshot,
  currentSalt,
  handleRequest,
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

  async list({prefix = '', cursor} = {}) {
    assert.equal(cursor, undefined);
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

  const counters = await aggregateSnapshot(env);
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
