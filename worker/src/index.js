const saltKey = 'system|salt';
const counterPrefix = 'counter|';
const totalPrefix = 'total|';
const visitorPrefix = 'visitor|';
const digestPrefix = 'system|digest|';
const saltLifetimeMs = 24 * 60 * 60 * 1000;
const shortRetentionSeconds = 2 * 24 * 60 * 60;
const maximumBodyBytes = 4096;

const allowedEvents = new Set([
  'route_view',
  'map_node_opened',
  'case_study_opened',
  'cv_opened',
  'language_changed',
  'theme_changed',
  'scroll_depth',
  'section_dwell',
  'error_reported',
]);

/// Events that carry a numeric `value`, and the range each one accepts.
const valuedEvents = new Map([
  // A quartile, 1 to 4.
  ['scroll_depth', [1, 4]],
  // Whole seconds on a route. Capped at an hour: anything longer is a tab left
  // open, not a reading, and storing it would make that visit distinctive.
  ['section_dwell', [2, 3600]],
]);

export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  },

  async scheduled(controller, env) {
    const now = new Date(controller.scheduledTime);
    if (controller.cron === '0 0 * * *') {
      await rotateSalt(env, now);
      return;
    }
    if (controller.cron === '0 1-23 * * *') {
      await verifySaltRotation(env, now);
      await sendLondonNoonDigest(env, now);
    }
  },
};

export async function handleRequest(request, env, now = new Date()) {
  const origin = request.headers.get('origin');
  const headers = corsHeaders(origin, env.SITE_ORIGIN);
  if (request.method === 'OPTIONS') {
    return origin === env.SITE_ORIGIN
      ? new Response(null, {status: 204, headers})
      : response({error: 'Origin not allowed'}, 403, headers);
  }

  if (!env.ANALYTICS) {
    return response({error: 'Analytics store is not configured'}, 503, headers);
  }

  const url = new URL(request.url);
  if (url.pathname === '/v1/beacon' && request.method === 'POST') {
    if (origin !== env.SITE_ORIGIN) {
      return response({error: 'Origin not allowed'}, 403, headers);
    }
    return receiveBeacon(request, env, now, headers);
  }
  if (url.pathname === '/v1/writing' && request.method === 'GET') {
    if (origin !== env.SITE_ORIGIN) {
      return response({error: 'Origin not allowed'}, 403, headers);
    }
    return relayWriting(env, now, headers);
  }
  if (url.pathname === '/v1/aggregates' && request.method === 'GET') {
    if (!authorised(request, env.CONSOLE_TOKEN)) {
      return response({error: 'Unauthorised'}, 401, headers);
    }
    return response(await aggregateSnapshot(env), 200, headers);
  }
  return response({error: 'Not found'}, 404, headers);
}

async function receiveBeacon(request, env, now, headers) {
  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maximumBodyBytes) {
    return response({error: 'Payload too large'}, 413, headers);
  }
  const source = await request.text();
  if (new TextEncoder().encode(source).byteLength > maximumBodyBytes) {
    return response({error: 'Payload too large'}, 413, headers);
  }

  let beacon;
  try {
    beacon = validateBeacon(JSON.parse(source));
  } catch {
    return response({error: 'Invalid beacon'}, 400, headers);
  }

  const date = isoDate(now);
  const country = validCountry(request.cf?.country) ?? 'XX';
  const dimensions = [
    date,
    beacon.event,
    beacon.route,
    country,
    beacon.deviceClass,
    beacon.referrerHost ?? '-',
    beacon.campaign ?? '-',
  ];
  await increment(env.ANALYTICS, key(counterPrefix, dimensions), now);

  // The session identifier is used to deduplicate within a tab and is then
  // discarded: it is never a stored dimension, so no counter can be traced
  // back to one viewer's tab. Section 4 allows the identifier to exist for the
  // life of a tab; nothing says it has to be written down.
  if (beacon.value !== null) {
    await accumulate(
      env.ANALYTICS,
      key(totalPrefix, [date, beacon.event, beacon.route]),
      beacon.value,
      now,
    );
  }

  if (beacon.event === 'route_view') {
    const salt = await currentSalt(env, now);
    const hash = await visitorHash(
      salt.value,
      request.headers.get('cf-connecting-ip') ?? '',
      request.headers.get('user-agent') ?? '',
      env.SITE_ID,
    );
    const visitorKey = key(visitorPrefix, [date, hash]);
    if ((await env.ANALYTICS.get(visitorKey)) === null) {
      await env.ANALYTICS.put(visitorKey, '1', {
        expirationTtl: shortRetentionSeconds,
      });
      await increment(
        env.ANALYTICS,
        key(counterPrefix, [date, 'unique_visitor']),
        now,
      );
    }
  }

  if (beacon.event === 'cv_opened' && env.ALERT_WEBHOOK_URL) {
    await postJson(env.ALERT_WEBHOOK_URL, {
      campaign: beacon.campaign,
      country,
      route: beacon.route,
      timestamp: now.toISOString(),
    });
  }
  return response({accepted: true}, 202, headers);
}

/// How long a fetched feed is served from KV before Medium is asked again.
const WRITING_TTL_SECONDS = 3600;

/// Relays the owner's Medium feed, which the browser cannot fetch itself.
///
/// Medium serves no `access-control-allow-origin`, so a first-party relay is
/// the only way a canvas app on another origin can read it. The response is
/// the feed verbatim: parsing belongs to the client, which already carries an
/// XML parser for it, and a Worker that reshaped the feed would be a second
/// place for that shape to drift.
///
/// Nothing about the viewer reaches Medium. This runs server-side with no
/// forwarded headers, so the request carries the Worker's identity, not
/// theirs — which also means the relay is not analytics and needs no consent.
export async function relayWriting(env, now, headers, fetchImpl = fetch) {
  const feedUrl = env.WRITING_FEED_URL;
  if (typeof feedUrl !== 'string' || !feedUrl.startsWith('https://')) {
    return response({error: 'No feed is configured'}, 503, headers);
  }

  const cached = await env.ANALYTICS.get(WRITING_CACHE_KEY);
  if (cached !== null) {
    return feedResponse(cached, headers, 'hit');
  }

  let body;
  try {
    const result = await fetchImpl(feedUrl, {
      headers: {accept: 'application/rss+xml, application/xml, text/xml'},
    });
    if (!result.ok) throw new Error(`Feed responded ${result.status}`);
    body = await result.text();
  } catch {
    // Section 5 of the architecture: a feed failure hides the writing section
    // rather than showing an error, so an empty 200 is wrong here — the client
    // needs to be able to tell "nothing published" from "could not ask".
    return response({error: 'Feed unavailable'}, 502, headers);
  }

  await env.ANALYTICS.put(WRITING_CACHE_KEY, body, {
    expiration: Math.floor(now.getTime() / 1000) + WRITING_TTL_SECONDS,
  });
  return feedResponse(body, headers, 'miss');
}

const WRITING_CACHE_KEY = 'writing:feed';

function feedResponse(body, headers, cacheState) {
  const feedHeaders = new Headers(headers);
  feedHeaders.set('content-type', 'application/xml; charset=utf-8');
  feedHeaders.set('cache-control', `public, max-age=${WRITING_TTL_SECONDS}`);
  feedHeaders.set('x-nocturne-cache', cacheState);
  return new Response(body, {status: 200, headers: feedHeaders});
}

export function validateBeacon(input) {
  if (!plainObject(input)) throw new TypeError('Beacon must be an object');
  const expected = new Set([
    'event',
    'route',
    'deviceClass',
    'referrerHost',
    'campaign',
    'sessionId',
    'value',
  ]);
  if (Object.keys(input).some((field) => !expected.has(field))) {
    throw new TypeError('Unexpected beacon field');
  }
  if (!allowedEvents.has(input.event)) throw new TypeError('Invalid event');
  if (!/^\/[A-Za-z0-9/_-]{0,160}$/.test(input.route)) {
    throw new TypeError('Invalid route');
  }
  if (!['touch', 'pointer'].includes(input.deviceClass)) {
    throw new TypeError('Invalid device class');
  }
  const referrerHost = optionalMatch(
    input.referrerHost,
    /^(?=.{1,253}$)[A-Za-z0-9.-]+$/,
  );
  const campaign = optionalMatch(
    input.campaign,
    /^[a-z0-9]+(?:-[a-z0-9]+)*$/,
  );
  return {
    event: input.event,
    route: input.route,
    deviceClass: input.deviceClass,
    referrerHost,
    campaign,
    sessionId: validSessionId(input.event, input.sessionId),
    value: validValue(input.event, input.value),
  };
}

/// A Tier 1 session identifier: 32 hex characters, minted in the browser tab.
///
/// Rejected outright on `route_view`, which is Tier 0 and must never carry an
/// identifier. A malformed one is an error rather than a silent drop, because
/// a client sending the wrong shape is a bug worth surfacing.
function validSessionId(event, value) {
  if (value === null || value === undefined) return null;
  if (event === 'route_view') {
    throw new TypeError('Tier 0 events carry no session identifier');
  }
  if (typeof value !== 'string' || !/^[0-9a-f]{32}$/.test(value)) {
    throw new TypeError('Invalid session identifier');
  }
  return value;
}

/// The one number an event may carry, range-checked per event.
function validValue(event, value) {
  if (value === null || value === undefined) return null;
  const range = valuedEvents.get(event);
  if (range === undefined) throw new TypeError('Event carries no value');
  if (!Number.isInteger(value) || value < range[0] || value > range[1]) {
    throw new TypeError('Value out of range');
  }
  return value;
}

export async function currentSalt(env, now = new Date()) {
  const stored = await env.ANALYTICS.get(saltKey, 'json');
  if (
    stored &&
    typeof stored.value === 'string' &&
    Number.isFinite(stored.createdAt) &&
    now.getTime() - stored.createdAt >= 0 &&
    now.getTime() - stored.createdAt < saltLifetimeMs
  ) {
    return stored;
  }
  return rotateSalt(env, now);
}

export async function rotateSalt(env, now = new Date()) {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  const salt = {
    value: bytesToHex(bytes),
    createdAt: now.getTime(),
  };
  await env.ANALYTICS.put(saltKey, JSON.stringify(salt));
  return salt;
}

export async function verifySaltRotation(env, now = new Date()) {
  const stored = await env.ANALYTICS.get(saltKey, 'json');
  const age = stored ? now.getTime() - stored.createdAt : Number.POSITIVE_INFINITY;
  if (
    stored &&
    typeof stored.value === 'string' &&
    Number.isFinite(stored.createdAt) &&
    age >= 0 &&
    age < saltLifetimeMs
  ) {
    return true;
  }
  if (env.ALERT_WEBHOOK_URL) {
    await postJson(env.ALERT_WEBHOOK_URL, {
      kind: 'salt_rotation_failed',
      detectedAt: now.toISOString(),
    });
  }
  await rotateSalt(env, now);
  return false;
}

export async function visitorHash(salt, address, agent, siteId) {
  const material = new TextEncoder().encode(
    `${salt}\u0000${address}\u0000${agent}\u0000${siteId}`,
  );
  return bytesToHex(new Uint8Array(await crypto.subtle.digest('SHA-256', material)));
}

export async function aggregateSnapshot(env) {
  return {
    counters: await readRows(env, counterPrefix, 'count'),
    // Running sums for the events that carry a number, so the console can
    // divide totals by counts for a mean without any per-visit row existing.
    totals: await readRows(env, totalPrefix, 'total'),
  };
}

/// Reads every key under [prefix], splitting its dimensions back out.
async function readRows(env, prefix, field) {
  const rows = [];
  let cursor;
  do {
    const page = await env.ANALYTICS.list({prefix, cursor});
    for (const entry of page.keys) {
      rows.push({
        dimensions: entry.name
          .slice(prefix.length)
          .split('|')
          .map((value) => decodeURIComponent(value)),
        [field]: Number(await env.ANALYTICS.get(entry.name)) || 0,
      });
    }
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);
  return rows;
}

export async function sendLondonNoonDigest(env, now = new Date()) {
  if (!env.DIGEST_WEBHOOK_URL) return false;
  const london = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/London',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  const parts = Object.fromEntries(london.map((part) => [part.type, part.value]));
  if (parts.hour !== '12') return false;
  const date = `${parts.year}-${parts.month}-${parts.day}`;
  const sentKey = `${digestPrefix}${date}`;
  if ((await env.ANALYTICS.get(sentKey)) !== null) return false;
  await postJson(env.DIGEST_WEBHOOK_URL, {
    generatedAt: now.toISOString(),
    // Spread, not nested: the snapshot is already `{counters, totals}`, and
    // wrapping it again would put a `counters.counters` in the payload the
    // digest workflow reads.
    ...(await aggregateSnapshot(env)),
  });
  await env.ANALYTICS.put(sentKey, '1', {
    expirationTtl: shortRetentionSeconds,
  });
  return true;
}

/// Adds [amount] to a running total, for events that carry a number.
///
/// Kept beside the plain counter so the console can divide one by the other
/// and get a mean — total seconds over dwell events is the median-ish figure
/// the dashboard shows — without ever storing a per-visit row.
async function accumulate(store, totalKey, amount, now) {
  const current = Number(await store.get(totalKey)) || 0;
  await store.put(totalKey, String(current + amount), {
    expiration: retentionExpiry(now),
  });
}

async function increment(store, counterKey, now) {
  const current = Number(await store.get(counterKey)) || 0;
  await store.put(counterKey, String(current + 1), {
    expiration: retentionExpiry(now),
  });
}

function retentionExpiry(now) {
  const expiry = new Date(now);
  expiry.setUTCMonth(expiry.getUTCMonth() + 24);
  return Math.floor(expiry.getTime() / 1000);
}

function authorised(request, token) {
  if (typeof token !== 'string' || token.length < 32) return false;
  return request.headers.get('authorization') === `Bearer ${token}`;
}

function corsHeaders(origin, allowedOrigin) {
  const headers = new Headers({
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    vary: 'Origin',
  });
  if (origin === allowedOrigin) {
    headers.set('access-control-allow-origin', allowedOrigin);
    headers.set('access-control-allow-methods', 'POST, GET, OPTIONS');
    headers.set('access-control-allow-headers', 'Content-Type, Authorization');
  }
  return headers;
}

function response(body, status, headers) {
  return new Response(JSON.stringify(body), {status, headers});
}

function plainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function optionalMatch(value, pattern) {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value !== 'string' || !pattern.test(value)) {
    throw new TypeError('Invalid optional field');
  }
  return value.toLowerCase();
}

function validCountry(value) {
  return typeof value === 'string' && /^[A-Z]{2}$/.test(value) ? value : null;
}

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

function key(prefix, dimensions) {
  return prefix + dimensions.map((value) => encodeURIComponent(value)).join('|');
}

function bytesToHex(bytes) {
  return Array.from(bytes, (value) => value.toString(16).padStart(2, '0')).join('');
}

async function postJson(url, body) {
  const result = await fetch(url, {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify(body),
  });
  if (!result.ok) throw new Error(`Webhook failed with ${result.status}`);
}
