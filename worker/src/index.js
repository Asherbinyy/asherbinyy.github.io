import {editableFiles} from '../contracts/content-schema.js';
import {
  changedClaims,
  collectClaims,
  differences,
  validateDocument,
} from '../contracts/validate.js';
import {adminPage} from './admin.js';

const saltKey = 'system|salt';
const counterPrefix = 'counter|';
const totalPrefix = 'total|';
const visitorPrefix = 'visitor|';
const adminFailurePrefix = 'admin-failures|';
const changeLogPrefix = 'change-log|';
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

  // The panel itself. Unauthenticated on purpose: it is a form, and the form
  // is useless without the token that every endpoint behind it demands. Gating
  // the HTML would mean inventing a session before there is anything to hold
  // one for.
  if (url.pathname === '/admin' && request.method === 'GET') {
    return new Response(adminPage(env), {
      status: 200,
      headers: new Headers({
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-store',
        // Its own script and styles only, and it may reach this Worker and the
        // site's asset bundle and nothing else. The panel handles a token that
        // can rewrite the site, so it is the one page here that most needs to
        // be unable to talk to anywhere unexpected.
        'content-security-policy': [
          "default-src 'none'",
          "script-src 'unsafe-inline'",
          "style-src 'unsafe-inline'",
          `img-src 'self' data: ${env.SITE_ORIGIN}`,
          `connect-src 'self' ${env.SITE_ORIGIN}`,
          "form-action 'none'",
          "base-uri 'none'",
          "frame-ancestors 'none'",
        ].join('; '),
        'referrer-policy': 'no-referrer',
        'x-content-type-options': 'nosniff',
        'x-robots-tag': 'noindex, nofollow',
      }),
    });
  }

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
  if (url.pathname === '/v1/cover' && request.method === 'GET') {
    if (origin !== env.SITE_ORIGIN) {
      return response({error: 'Origin not allowed'}, 403, headers);
    }
    return relayCover(url.searchParams.get('src'), headers);
  }
  // Content the owner has published, read by the site in place of its bundle.
  // Origin-gated like every other read: this is the site's own content coming
  // back to it, not a public API.
  if (url.pathname.startsWith('/v1/content/') && request.method === 'GET') {
    if (origin !== env.SITE_ORIGIN) {
      return response({error: 'Origin not allowed'}, 403, headers);
    }
    const file = url.pathname.slice('/v1/content/'.length);
    return readPublished(file, env, headers);
  }

  // The write half. Deliberately not origin-gated: the owner publishes from a
  // panel served by this Worker, not from the site, so an Origin check would
  // reject the only client that is supposed to reach it. The token is what
  // guards these, and it is checked before anything else is read.
  // Published imagery. Deliberately **not** origin-gated, unlike every other
  // read here: these are loaded by ordinary image elements, which send no
  // Origin header, so gating them would 403 the only way they are ever
  // fetched. There is nothing to protect either -- this is public artwork on a
  // public site, and the id is a content hash rather than a guessable name.
  if (url.pathname.startsWith('/v1/media/') && request.method === 'GET') {
    return readMedia(url.pathname.slice('/v1/media/'.length), env, origin);
  }

  if (url.pathname.startsWith('/v1/admin/')) {
    const refusal = await refuseUnauthorisedAdmin(request, env, now, headers);
    if (refusal) return refusal;

    if (url.pathname === '/v1/admin/content' && request.method === 'GET') {
      return listPublished(env, headers);
    }
    if (url.pathname === '/v1/admin/changes' && request.method === 'GET') {
      return listChanges(env, headers);
    }
    if (url.pathname === '/v1/admin/validate' && request.method === 'POST') {
      return checkDraft(request, env, headers, false);
    }
    if (url.pathname === '/v1/admin/review' && request.method === 'POST') {
      return checkDraft(request, env, headers, true);
    }
    if (url.pathname === '/v1/admin/media' && request.method === 'GET') {
      return listMedia(env, headers);
    }
    if (url.pathname === '/v1/admin/media' && request.method === 'POST') {
      return uploadMedia(request, env, headers);
    }
    // Its own path, not a flag on the image endpoint. The image endpoint's
    // whole argument is that it decodes enough of each container to know it is
    // a raster image; widening it to "or some audio" would throw that away.
    if (url.pathname === '/v1/admin/media/audio' && request.method === 'POST') {
      return uploadAudio(request, env, headers);
    }
    if (url.pathname.startsWith('/v1/admin/media/') && request.method === 'DELETE') {
      return removeMedia(url.pathname.slice('/v1/admin/media/'.length), env, headers);
    }
    if (url.pathname.startsWith('/v1/admin/content/')) {
      const rest = url.pathname.slice('/v1/admin/content/'.length);
      const [file, action] = rest.split('/');
      if (action === 'revisions' && request.method === 'GET') {
        return listRevisions(file, env, headers);
      }
      if (action === 'rollback' && request.method === 'POST') {
        return rollback(file, request, env, now, headers);
      }
      if (action === undefined && request.method === 'PUT') {
        return publish(file, request, env, now, headers);
      }
      if (action === undefined && request.method === 'DELETE') {
        return withdraw(file, env, now, headers);
      }
    }
    return response({error: 'Not found'}, 404, headers);
  }

  if (url.pathname === '/v1/aggregates' && request.method === 'GET') {
    if (!authorised(request, env.CONSOLE_TOKEN)) {
      return response({error: 'Unauthorised'}, 401, headers);
    }
    return response(await aggregateSnapshot(env), 200, headers);
  }
  return response({error: 'Not found'}, 404, headers);
}

/// Content documents the owner is allowed to override.
///
/// A closed list, checked before the key is built. The path segment reaches
/// KV, so without this an admin request could read or write any key in the
/// namespace, including the analytics counters sharing it.
const publishableFiles = new Set(editableFiles);

/// How long a published document may be, in bytes.
///
/// The largest bundled document is a few kilobytes. This is generous enough
/// that the owner will never meet it and small enough that the endpoint is not
/// a file host.
const maximumDocumentBytes = 256 * 1024;

/// Failed admin attempts allowed per hour before the endpoint stops answering.
const maximumFailedAttempts = 10;

function contentKey(file) {
  return `content:${file}`;
}

/// Where the history of a document lives.
///
/// Separate keys from the document itself, so `/v1/content/<file>` keeps
/// answering with the document and nothing else. The site parses that
/// response straight into its content models, and wrapping it in an envelope
/// to carry a revision number would break every reader for the sake of a
/// number only the panel needs.
function revisionKey(file, number) {
  return `revision:${file}:${String(number).padStart(6, '0')}`;
}

function revisionHeadKey(file) {
  return `revision-head:${file}`;
}

/// What the document is at now, and how it got there.
async function revisionHead(file, env) {
  const store = contentStore(env);
  if (!store) return null;
  return store.get(revisionHeadKey(file), 'json');
}

/// The number a new revision of [file] will take.
async function nextRevision(file, env) {
  const head = await revisionHead(file, env);
  return (head?.revision ?? 0) + 1;
}

/// Whether the store that holds published content is configured at all.
///
/// It is optional on purpose. The namespace has to be created by hand, and
/// until it is, this Worker deploys and runs exactly as before: reads 404 and
/// the site uses its bundle, which is the behaviour it already handles.
function contentStore(env) {
  return env.CONTENT ?? null;
}

async function readPublished(file, env, headers) {
  if (!publishableFiles.has(file)) {
    return response({error: 'Not found'}, 404, headers);
  }
  const store = contentStore(env);
  if (!store) return response({error: 'Not found'}, 404, headers);

  const document = await store.get(contentKey(file));
  if (document === null) return response({error: 'Not found'}, 404, headers);

  const published = new Headers(headers);
  published.set('content-type', 'application/json; charset=utf-8');
  // Short, because the point of publishing is that a correction is live
  // quickly, and the site falls back to its bundle if this is slow anyway.
  published.set('cache-control', 'public, max-age=60');
  // Additive, and in a header rather than the body: the body is the document
  // the app parses, and it stays that way.
  const head = await revisionHead(file, env);
  if (head?.revision) published.set('x-content-revision', String(head.revision));
  return new Response(document, {status: 200, headers: published});
}

async function listPublished(env, headers) {
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  const listing = await store.list({prefix: 'content:'});
  const published = listing.keys.map((entry) => entry.name.slice('content:'.length));
  // The revision each document is at, so the panel can declare a base when it
  // publishes without asking five more times.
  const heads = {};
  for (const file of publishableFiles) {
    const head = await revisionHead(file, env);
    if (head) heads[file] = head.revision;
  }
  return response({published, heads}, 200, headers);
}

/// Every source the owner has given for a figure, newest first.
async function listChanges(env, headers) {
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  const listing = await store.list({prefix: changeLogPrefix});
  const entries = await Promise.all(
    listing.keys.map((entry) => store.get(entry.name, 'json')),
  );
  return response({changes: entries.reverse()}, 200, headers);
}

async function publish(file, request, env, now, headers) {
  if (!publishableFiles.has(file)) {
    return response({error: 'Not a publishable document'}, 400, headers);
  }
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }

  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maximumDocumentBytes) {
    return response({error: 'Payload too large'}, 413, headers);
  }
  const source = await request.text();
  if (new TextEncoder().encode(source).byteLength > maximumDocumentBytes) {
    return response({error: 'Payload too large'}, 413, headers);
  }

  // Parsed here so a document that cannot be read is refused at the door
  // rather than served to the site and rejected there. The site would survive
  // it -- it falls back to the bundle -- but the owner would have no idea he
  // had published something broken.
  let document;
  try {
    document = JSON.parse(source);
  } catch {
    return response({error: 'Document is not valid JSON'}, 400, headers);
  }
  if (!plainObject(document)) {
    return response({error: 'Document must be an object'}, 400, headers);
  }

  // The real schema, not just "it is an object" (A-F6). Before this, a
  // document the app could not parse was accepted here, reported to the owner
  // as published, and then silently discarded by the site in favour of its
  // bundle -- so the panel said the change was live and the change was not.
  const verdict = validateDocument(file, document, {
    references: await referenceSets(file, env),
  });
  if (verdict.errors.length > 0) {
    return response(
      {error: 'The document does not match the schema', errors: verdict.errors},
      422,
      headers,
    );
  }

  // Two people, or one person in two tabs, editing the same page. Whoever
  // arrives second is told rather than silently winning: the base revision is
  // the one the draft was built from, and if the document has moved on since,
  // publishing would erase whatever moved it.
  const head = await revisionHead(file, env);
  const current = head?.revision ?? 0;
  const declaredBase = request.headers.get('x-base-revision');
  const base = declaredBase === null ? null : Number(declaredBase);
  if (base !== null && Number.isFinite(base) && base !== current) {
    return response(
      {
        error: 'This page has changed since you started editing it',
        expected: base,
        current: current,
        document: await store.get(contentKey(file), 'json'),
        changedAt: head?.at ?? null,
      },
      409,
      headers,
    );
  }

  // A figure is a claim and a claim needs a source. Enforced here rather than
  // only asked for in the browser (A-F7): a note that the panel prompts for
  // and the Worker does not require is a convention, not a rule.
  //
  // The comparison is against the published copy, or against nothing. Never
  // against a baseline the caller supplied, which is the whole point of doing
  // it here.
  const live = await store.get(contentKey(file), 'json');
  const claims = live === null
    ? collectClaims(file, document)
    : changedClaims(file, live, document);
  const note = decodeURIComponent(request.headers.get('x-change-note') ?? '').trim();
  if (claims.length > 0 && note === '') {
    return response(
      {
        error: 'A claim cannot be published without a source',
        claims: claims.map((claim) => ({path: claim.path, label: claim.label})),
      },
      422,
      headers,
    );
  }

  const revision = current + 1;
  // Stored re-serialised rather than as received, so the bytes in KV are
  // exactly what was parsed and nothing rides along outside the JSON.
  const body = JSON.stringify(document);
  await store.put(contentKey(file), body);
  await store.put(revisionKey(file, revision), JSON.stringify({
    revision,
    file,
    at: now.toISOString(),
    note,
    claims: claims.map((claim) => claim.path),
    document,
  }));
  await store.put(revisionHeadKey(file), JSON.stringify({
    revision,
    at: now.toISOString(),
    note,
    withdrawn: false,
  }));

  // Kept as it was: the change log is the ledger the provenance practice
  // already reads, and moving it would orphan what is in there.
  if (note) {
    await store.put(
      key(changeLogPrefix, [now.toISOString(), file]),
      JSON.stringify({file, note, at: now.toISOString()}),
    );
  }
  return response({published: file, revision}, 200, headers);
}

/// Every revision of a document, newest first.
///
/// The stored document is left out of the listing: five of these would be most
/// of a response for something the panel only needs when rolling back.
async function listRevisions(file, env, headers) {
  if (!publishableFiles.has(file)) {
    return response({error: 'Not a publishable document'}, 400, headers);
  }
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  const listing = await store.list({prefix: `revision:${file}:`});
  const entries = await Promise.all(
    listing.keys.map((entry) => store.get(entry.name, 'json')),
  );
  const head = await revisionHead(file, env);
  return response(
    {
      current: head?.revision ?? 0,
      withdrawn: head?.withdrawn ?? false,
      revisions: entries
        .filter(Boolean)
        .map((entry) => ({
          revision: entry.revision,
          at: entry.at,
          note: entry.note,
          claims: entry.claims ?? [],
          withdrawal: entry.withdrawal === true,
        }))
        .reverse(),
    },
    200,
    headers,
  );
}

/// Puts a previous revision back, as a new revision.
///
/// Append-only. Rewinding the counter would make two different documents
/// share a revision number, and a number that does not identify one document
/// is worse than no number.
async function rollback(file, request, env, now, headers) {
  if (!publishableFiles.has(file)) {
    return response({error: 'Not a publishable document'}, 400, headers);
  }
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  let asked;
  try {
    asked = JSON.parse(await request.text());
  } catch {
    return response({error: 'Request is not valid JSON'}, 400, headers);
  }
  const wanted = Number(asked?.revision);
  if (!Number.isInteger(wanted) || wanted < 1) {
    return response({error: 'Which revision?'}, 400, headers);
  }
  const stored = await store.get(revisionKey(file, wanted), 'json');
  if (!stored || stored.withdrawal === true) {
    return response({error: 'No such revision to go back to'}, 404, headers);
  }

  // Checked again on the way back in. A revision that was valid when it was
  // published can stop being valid when the schema tightens, and restoring
  // one the app can no longer parse would be a new outage, not a recovery.
  const verdict = validateDocument(file, stored.document, {
    references: await referenceSets(file, env),
  });
  if (verdict.errors.length > 0) {
    return response(
      {
        error: 'That revision no longer matches the schema',
        errors: verdict.errors,
      },
      422,
      headers,
    );
  }

  const revision = (await nextRevision(file, env));
  await store.put(contentKey(file), JSON.stringify(stored.document));
  await store.put(revisionKey(file, revision), JSON.stringify({
    revision,
    file,
    at: now.toISOString(),
    note: `Went back to revision ${wanted}`,
    claims: stored.claims ?? [],
    restoredFrom: wanted,
    document: stored.document,
  }));
  await store.put(revisionHeadKey(file), JSON.stringify({
    revision,
    at: now.toISOString(),
    note: `Went back to revision ${wanted}`,
    withdrawn: false,
  }));
  return response({published: file, revision, restoredFrom: wanted}, 200, headers);
}

/// Checks a draft, and for a review also says what would change.
///
/// The panel has no validator of its own. It asks this, so there is exactly
/// one answer to "would this be accepted" and the panel cannot disagree with
/// the endpoint that decides.
async function checkDraft(request, env, headers, full) {
  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maximumDocumentBytes) {
    return response({error: 'Payload too large'}, 413, headers);
  }
  let body;
  try {
    body = JSON.parse(await request.text());
  } catch {
    return response({error: 'Request is not valid JSON'}, 400, headers);
  }
  if (!plainObject(body) || !publishableFiles.has(body.file)) {
    return response({error: 'Not a document this panel edits'}, 400, headers);
  }

  const verdict = validateDocument(body.file, body.document, {
    references: await referenceSets(body.file, env, body.references),
  });
  if (!full) return response(verdict, 200, headers);

  // What the site is showing right now, which is not always something this
  // Worker can read. Where nothing has been published the site falls back to
  // the copy in its own bundle, and only the panel has that -- so it may say
  // what it is comparing against, and the answer says which it was.
  //
  // Advisory, and only for what the owner is shown. When the provenance rule
  // is enforced here in A3 it has to compare against the published copy or
  // against nothing, never against a baseline the caller supplied.
  const published = await liveDocument(body.file, env);
  const offered = plainObject(body.baseline) ? body.baseline : null;
  const live = published ?? offered;

  // What the publish endpoint will actually insist on, worked out the same
  // way it works it out: against the published copy, or against nothing.
  // Without this the panel would not ask for a source on a first publish and
  // the Worker would refuse it, which is a worse experience than either rule
  // on its own.
  const sourceClaims = published === null
    ? collectClaims(body.file, body.document)
    : changedClaims(body.file, published, body.document);

  return response(
    {
      ...verdict,
      changes: live === null ? [] : differences(live, body.document),
      claims: live === null ? [] : changedClaims(body.file, live, body.document),
      sourceRequired: sourceClaims.length > 0,
      sourceClaims: sourceClaims.map((claim) => ({
        path: claim.path,
        label: claim.label,
        value: claim.value,
      })),
      // Nothing has been published, so every figure in the document is one
      // the Worker has never been given a source for.
      sourceReason: published === null ? 'first-publish' : 'changed',
      comparedWith:
        published !== null ? 'published' : offered !== null ? 'shipped' : 'nothing',
    },
    200,
    headers,
  );
}

/// The published document, or null when the site is using its own bundle.
async function liveDocument(file, env) {
  const store = contentStore(env);
  if (!store) return null;
  return store.get(contentKey(file), 'json');
}

/// The identifiers another document offers, so a reference can be checked.
///
/// Published content is the authority: it is what the site is actually
/// serving. Where nothing is published the site falls back to the copy in its
/// own bundle, which this Worker cannot read -- so the panel, which has both,
/// may declare what it loaded. That declaration is advisory and only ever
/// used to answer the panel's own question; a publish is checked against KV
/// alone. The worst a wrong declaration can do is quiet a warning about the
/// owner's own content, in a panel only he can open.
async function referenceSets(file, env, declared = null) {
  const wanted = referencedBy[file];
  if (!wanted) return null;
  const sets = {};
  for (const name of wanted) {
    const published = await liveDocument(name, env);
    if (published !== null) {
      sets[name] = collectIdentifiers(published) ?? [];
      continue;
    }
    const offered = declared?.[name];
    if (Array.isArray(offered) && offered.every((id) => typeof id === 'string')) {
      sets[name] = offered;
    }
  }
  return sets;
}

/// Which documents each document points at. The schema's `references` fields
/// are the authority for a field; this says where to go looking.
const referencedBy = {'career.json': ['apps.json']};

/// Every `id` in the first list of objects a document holds.
function collectIdentifiers(document) {
  if (!plainObject(document)) return null;
  for (const value of Object.values(document)) {
    if (!Array.isArray(value)) continue;
    const ids = value
      .filter((entry) => plainObject(entry) && typeof entry.id === 'string')
      .map((entry) => entry.id);
    if (ids.length > 0) return ids;
  }
  return [];
}

async function withdraw(file, env, now, headers) {
  if (!publishableFiles.has(file)) {
    return response({error: 'Not a publishable document'}, 400, headers);
  }
  const store = contentStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  await store.delete(contentKey(file));

  // Recorded, because withdrawing is a change to what the site shows and a
  // history with a hole in it is not a history. The revisions themselves stay
  // where they are, so this is still undoable.
  const revision = await nextRevision(file, env);
  await store.put(revisionKey(file, revision), JSON.stringify({
    revision,
    file,
    at: now.toISOString(),
    note: 'Withdrawn; the site went back to the copy in its bundle',
    claims: [],
    withdrawal: true,
  }));
  await store.put(revisionHeadKey(file), JSON.stringify({
    revision,
    at: now.toISOString(),
    note: 'Withdrawn',
    withdrawn: true,
  }));
  // Withdrawing is not deleting content: the bundled document is still there
  // and the site goes back to it.
  return response({withdrawn: file, revision}, 200, headers);
}

/// Refuses an admin request, or returns null to let it through.
///
/// Counts failures and stops answering after too many in an hour. The token is
/// long and random so guessing it is not a realistic attack, but an endpoint
/// that will answer an unlimited number of guesses is a different claim from
/// one that will not, and the second is cheap.
async function refuseUnauthorisedAdmin(request, env, now, headers) {
  const attemptKey = key(adminFailurePrefix, [
    isoDate(now),
    String(now.getUTCHours()),
  ]);
  const failures = Number((await env.ANALYTICS.get(attemptKey)) ?? 0);
  if (failures >= maximumFailedAttempts) {
    return response({error: 'Too many attempts'}, 429, headers);
  }
  if (!authorised(request, env.ADMIN_TOKEN)) {
    await env.ANALYTICS.put(attemptKey, String(failures + 1), {
      expirationTtl: 3600,
    });
    return response({error: 'Unauthorised'}, 401, headers);
  }
  return null;
}

/// Image types the upload endpoint will take.
///
/// A closed list, and the omissions are the point. SVG is markup and can carry
/// script, so accepting it turns this into stored XSS on the owner's own
/// domain. HTML and PDF are refused for the same reason. Everything here is a
/// raster format a decoder cannot be talked into executing.
const mediaTypes = new Map([
  ['image/png', 'png'],
  ['image/jpeg', 'jpg'],
  ['image/webp', 'webp'],
]);

/// The largest image the endpoint will store, in bytes.
///
/// KV holds values up to 25MiB. This is far below that on purpose: a
/// screenshot of an app is a few hundred kilobytes, and an endpoint that
/// accepts 25MiB is a file host with the owner's name on it.
const maximumMediaBytes = 4 * 1024 * 1024;

/// Dimensions outside which an image is refused.
///
/// The floor rejects tracking pixels and decode failures that report 1x1; the
/// ceiling rejects a decompression bomb before it is ever handed to a browser.
const minimumMediaEdge = 16;
const maximumMediaEdge = 8000;

const mediaPrefix = 'media|';

function mediaStore(env) {
  return env.CONTENT ?? null;
}

async function readMedia(id, env, origin) {
  if (!/^[0-9a-f]{32}$/.test(id)) {
    return new Response('Not found', {status: 404});
  }
  const store = mediaStore(env);
  if (!store) return new Response('Not found', {status: 404});

  const stored = await store.getWithMetadata(mediaPrefix + id, 'arrayBuffer');
  if (!stored || stored.value === null) {
    return new Response('Not found', {status: 404});
  }

  const headers = new Headers({
    'content-type': stored.metadata?.type ?? 'application/octet-stream',
    // The id is a hash of the bytes, so this URL can never mean anything else
    // and a year is safe. Replacing an image means a new id, which is also how
    // the panel avoids ever serving a stale one.
    'cache-control': 'public, max-age=31536000, immutable',
    'content-security-policy': "default-src 'none'; sandbox",
    'x-content-type-options': 'nosniff',
  });
  if (origin === env.SITE_ORIGIN) {
    headers.set('access-control-allow-origin', origin);
    headers.set('vary', 'Origin');
  }
  return new Response(stored.value, {status: 200, headers});
}

async function listMedia(env, headers) {
  const store = mediaStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  const listing = await store.list({prefix: mediaPrefix});
  return response(
    {
      media: listing.keys.map((entry) => ({
        id: entry.name.slice(mediaPrefix.length),
        // Inferred for anything stored before the library existed, rather
        // than left undefined for the panel to guess at.
        kind: (entry.metadata?.type ?? '').startsWith('audio/') ? 'audio' : 'image',
        ...(entry.metadata ?? {}),
        url: `/v1/media/${entry.name.slice(mediaPrefix.length)}`,
      })),
    },
    200,
    headers,
  );
}

async function uploadMedia(request, env, headers) {
  const store = mediaStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }

  const declaredType = (request.headers.get('content-type') ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  if (!mediaTypes.has(declaredType)) {
    return response({error: 'Unsupported image type'}, 415, headers);
  }

  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maximumMediaBytes) {
    return response({error: 'Image too large'}, 413, headers);
  }
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength > maximumMediaBytes) {
    return response({error: 'Image too large'}, 413, headers);
  }
  if (bytes.byteLength === 0) {
    return response({error: 'Image is empty'}, 400, headers);
  }

  // The declared type is a claim by the client. This reads the actual bytes,
  // so a script renamed to .png with an image content-type is refused on what
  // it is rather than on what it says it is.
  const measured = measureImage(bytes);
  if (!measured) {
    return response({error: 'Not a readable image'}, 400, headers);
  }
  if (measured.type !== declaredType) {
    return response({error: 'Image does not match its type'}, 400, headers);
  }
  if (
    measured.width < minimumMediaEdge ||
    measured.height < minimumMediaEdge ||
    measured.width > maximumMediaEdge ||
    measured.height > maximumMediaEdge
  ) {
    return response({error: 'Image dimensions are out of range'}, 400, headers);
  }

  // Content-addressed: the same image uploaded twice is one key, and the URL
  // cannot ever come to mean different bytes, which is what makes a one-year
  // cache honest.
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  const id = bytesToHex(new Uint8Array(digest)).slice(0, 32);

  await store.put(mediaPrefix + id, bytes, {
    metadata: {
      kind: 'image',
      type: measured.type,
      width: measured.width,
      height: measured.height,
      bytes: bytes.byteLength,
    },
  });
  return response(
    {
      id,
      url: `/v1/media/${id}`,
      width: measured.width,
      height: measured.height,
    },
    200,
    headers,
  );
}

/// Sound formats the recording endpoint will take.
///
/// Closed, like the image list, and for the same reason: each of these has a
/// header this Worker can read well enough to say what the bytes actually are.
/// A container that can carry a video track or a script is not on it.
const audioTypes = new Map([
  ['audio/mpeg', 'mp3'],
  ['audio/mp4', 'm4a'],
  ['audio/wav', 'wav'],
  ['audio/ogg', 'ogg'],
]);

/// The largest recording the endpoint will store.
///
/// The owner's name is 1.4 seconds and 12KB. This is three orders of magnitude
/// above that, and still small enough that the endpoint is not somewhere to
/// keep a podcast.
const maximumAudioBytes = 2 * 1024 * 1024;

async function uploadAudio(request, env, headers) {
  const store = mediaStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }

  const declaredType = (request.headers.get('content-type') ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  if (!audioTypes.has(declaredType)) {
    return response({error: 'Unsupported sound format'}, 415, headers);
  }

  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maximumAudioBytes) {
    return response({error: 'Recording too large'}, 413, headers);
  }
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength > maximumAudioBytes) {
    return response({error: 'Recording too large'}, 413, headers);
  }
  if (bytes.byteLength === 0) {
    return response({error: 'Recording is empty'}, 400, headers);
  }

  const measured = measureAudio(bytes);
  if (!measured) {
    return response({error: 'Not a readable recording'}, 400, headers);
  }
  // The same rule the image endpoint applies: the header says what this is,
  // not the caller. An .m4a renamed to .wav is refused on its bytes.
  if (measured.type !== declaredType) {
    return response({error: 'Recording does not match its type'}, 400, headers);
  }

  const digest = await crypto.subtle.digest('SHA-256', bytes);
  const id = bytesToHex(new Uint8Array(digest)).slice(0, 32);
  await store.put(mediaPrefix + id, bytes, {
    metadata: {
      kind: 'audio',
      type: measured.type,
      bytes: bytes.byteLength,
      // Absent where the container does not state it plainly. A length this
      // Worker cannot read is reported as unknown rather than estimated.
      ...(measured.seconds === null ? {} : {seconds: measured.seconds}),
    },
  });
  return response(
    {id, url: `/v1/media/${id}`, seconds: measured.seconds},
    200,
    headers,
  );
}

/// Reads a recording's real format, and its length where the header says so.
///
/// Parses only as far as the fields it needs. Nothing here decodes sound.
function measureAudio(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const ascii = (at, length) =>
    String.fromCharCode(...bytes.slice(at, at + length));

  // WAV: a RIFF container. The length is the data chunk over the byte rate,
  // both of which are stated in the header.
  if (bytes.byteLength > 44 && ascii(0, 4) === 'RIFF' && ascii(8, 4) === 'WAVE') {
    let at = 12;
    let byteRate = 0;
    while (at + 8 <= bytes.byteLength) {
      const chunk = ascii(at, 4);
      const size = view.getUint32(at + 4, true);
      // Inside the fmt chunk's own data, which starts eight bytes in: format,
      // channels, sample rate, then the byte rate at offset eight.
      if (chunk === 'fmt ' && at + 20 <= bytes.byteLength) {
        byteRate = view.getUint32(at + 16, true);
      }
      if (chunk === 'data') {
        return {
          type: 'audio/wav',
          seconds: byteRate > 0 ? Math.round((size / byteRate) * 100) / 100 : null,
        };
      }
      at += 8 + size + (size % 2);
    }
    return {type: 'audio/wav', seconds: null};
  }

  // OggS: the length lives in the last page's granule position, which means
  // reading the end of the file. Not worth it for a name recording.
  if (bytes.byteLength > 4 && ascii(0, 4) === 'OggS') {
    return {type: 'audio/ogg', seconds: null};
  }

  // MPEG-4: atoms, with the length in mvhd inside moov.
  if (bytes.byteLength > 12 && ascii(4, 4) === 'ftyp') {
    const brand = ascii(8, 4);
    if (!['M4A ', 'mp42', 'isom', 'M4B ', 'mp41'].includes(brand)) return null;
    return {type: 'audio/mp4', seconds: mpeg4Seconds(view, bytes, ascii)};
  }

  // MP3: either an ID3 tag or a bare frame sync. Its length needs every frame
  // header counted, so it is reported as unknown.
  if (bytes.byteLength > 4) {
    const tagged = ascii(0, 3) === 'ID3';
    const synced = bytes[0] === 0xff && (bytes[1] & 0xe0) === 0xe0;
    if (tagged || synced) return {type: 'audio/mpeg', seconds: null};
  }

  return null;
}

/// Walks MPEG-4 atoms to the movie header and reads its duration.
function mpeg4Seconds(view, bytes, ascii) {
  const findAtom = (name, from, until) => {
    let at = from;
    while (at + 8 <= until) {
      const size = view.getUint32(at);
      if (size < 8) return null;
      if (ascii(at + 4, 4) === name) return {at: at + 8, end: at + size};
      at += size;
    }
    return null;
  };
  const moov = findAtom('moov', 0, bytes.byteLength);
  if (!moov) return null;
  const mvhd = findAtom('mvhd', moov.at, Math.min(moov.end, bytes.byteLength));
  if (!mvhd || mvhd.at + 20 > bytes.byteLength) return null;

  const version = bytes[mvhd.at];
  // Version 1 widened the timestamps to 64 bits, which moves both fields.
  const timescale = version === 1
    ? view.getUint32(mvhd.at + 20)
    : view.getUint32(mvhd.at + 12);
  const duration = version === 1
    ? Number(view.getBigUint64(mvhd.at + 24))
    : view.getUint32(mvhd.at + 16);
  if (!timescale) return null;
  return Math.round((duration / timescale) * 100) / 100;
}

async function removeMedia(id, env, headers) {
  if (!/^[0-9a-f]{32}$/.test(id)) {
    return response({error: 'Not found'}, 404, headers);
  }
  const store = mediaStore(env);
  if (!store) {
    return response({error: 'Content store is not configured'}, 503, headers);
  }
  await store.delete(mediaPrefix + id);
  return response({removed: id}, 200, headers);
}

/// Reads an image's real format and dimensions from its own bytes.
///
/// Returns null for anything it cannot read, which is the answer for every
/// format not on the allowlist as well as for a truncated or fabricated
/// header. It parses only enough of each container to reach the size fields;
/// nothing here decodes pixels.
function measureImage(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

  // PNG: an 8-byte signature, then IHDR, whose first two fields are the size.
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (
    bytes.byteLength > 24 &&
    pngSignature.every((byte, index) => bytes[index] === byte)
  ) {
    return {
      type: 'image/png',
      width: view.getUint32(16),
      height: view.getUint32(20),
    };
  }

  // JPEG: a chain of segments; the size lives in whichever start-of-frame
  // marker this file happens to use, so the chain has to be walked.
  if (bytes.byteLength > 4 && bytes[0] === 0xff && bytes[1] === 0xd8) {
    let at = 2;
    while (at + 9 < bytes.byteLength) {
      if (bytes[at] !== 0xff) {
        at++;
        continue;
      }
      const marker = bytes[at + 1];
      // Start of frame, baseline through progressive, excluding the four
      // markers in that range that are not frames.
      const isFrame =
        marker >= 0xc0 &&
        marker <= 0xcf &&
        marker !== 0xc4 &&
        marker !== 0xc8 &&
        marker !== 0xcc;
      if (isFrame) {
        return {
          type: 'image/jpeg',
          height: view.getUint16(at + 5),
          width: view.getUint16(at + 7),
        };
      }
      if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
        at += 2;
        continue;
      }
      at += 2 + view.getUint16(at + 2);
    }
    return null;
  }

  // WebP: a RIFF container with three possible chunk layouts.
  if (
    bytes.byteLength > 30 &&
    String.fromCharCode(...bytes.slice(0, 4)) === 'RIFF' &&
    String.fromCharCode(...bytes.slice(8, 12)) === 'WEBP'
  ) {
    const chunk = String.fromCharCode(...bytes.slice(12, 16));
    if (chunk === 'VP8 ') {
      return {
        type: 'image/webp',
        width: view.getUint16(26, true) & 0x3fff,
        height: view.getUint16(28, true) & 0x3fff,
      };
    }
    if (chunk === 'VP8L') {
      const packed = view.getUint32(21, true);
      return {
        type: 'image/webp',
        width: (packed & 0x3fff) + 1,
        height: ((packed >> 14) & 0x3fff) + 1,
      };
    }
    if (chunk === 'VP8X') {
      const size = (start) =>
        (bytes[start] | (bytes[start + 1] << 8) | (bytes[start + 2] << 16)) + 1;
      return {type: 'image/webp', width: size(24), height: size(27)};
    }
    return null;
  }

  return null;
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

/// Hosts whose images this relay will fetch.
///
/// An allowlist rather than "any https URL". The `src` arrives from a query
/// string, so without one this endpoint is an open proxy that anyone could
/// point at any host, from the owner's Cloudflare account.
const COVER_HOSTS = new Set([
  'cdn-images-1.medium.com',
  'miro.medium.com',
]);

const COVER_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/avif',
]);

const COVER_MAX_BYTES = 2_000_000;
const COVER_TTL_SECONDS = 86_400;

/// Streams one article cover through this origin.
///
/// The feed is already relayed so that nothing about the viewer reaches
/// Medium. Hotlinking the covers straight from Medium's CDN would undo exactly
/// that: every visitor to /writing would issue six third-party requests
/// carrying their IP and referrer, which is the data flow this site's whole
/// argument says it does not have. So the images come through here too.
export async function relayCover(src, headers, fetchImpl = fetch) {
  if (!src) return response({error: 'Missing src'}, 400, headers);

  let target;
  try {
    target = new URL(src);
  } catch {
    return response({error: 'Invalid src'}, 400, headers);
  }
  if (target.protocol !== 'https:' || !COVER_HOSTS.has(target.hostname)) {
    return response({error: 'Host not allowed'}, 403, headers);
  }

  let result;
  try {
    result = await fetchImpl(target.toString(), {headers: {accept: 'image/*'}});
    if (!result.ok) throw new Error(`Cover responded ${result.status}`);
  } catch {
    return response({error: 'Cover unavailable'}, 502, headers);
  }

  const type = (result.headers.get('content-type') ?? '').split(';')[0].trim();
  if (!COVER_TYPES.has(type)) {
    return response({error: 'Not an image'}, 415, headers);
  }
  const declared = Number(result.headers.get('content-length') ?? 0);
  if (declared > COVER_MAX_BYTES) {
    return response({error: 'Cover too large'}, 413, headers);
  }

  const coverHeaders = new Headers(headers);
  coverHeaders.set('content-type', type);
  coverHeaders.set('cache-control', `public, max-age=${COVER_TTL_SECONDS}`);
  // Nothing about the upstream response is passed through beyond the bytes and
  // their type: no cookies, no ETag tied to Medium, no upstream cache tags.
  return new Response(result.body, {status: 200, headers: coverHeaders});
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
