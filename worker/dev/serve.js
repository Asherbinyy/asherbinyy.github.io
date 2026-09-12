/**
 * Runs the Worker on this machine, against fixtures, with a throwaway token.
 *
 * The panel cannot be reviewed by reading its source. It has to be opened,
 * typed into, and navigated away from while a draft is half finished, and
 * doing that against production would mean editing the owner's live content
 * with his real credential to find out whether a button works.
 *
 * So: an in-memory store, the sanitized fixtures from `worker/contracts/`, and
 * a token that exists for the life of the process. Nothing here reaches
 * Cloudflare, and nothing here is a deployment.
 *
 *   node worker/dev/serve.js [port]
 */

import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';

import {handleRequest} from '../src/index.js';
import {ContentStore} from '../src/store.js';
import {durableNamespace} from './durable-double.js';

const port = Number(process.argv[2] ?? 8788);
const origin = `http://localhost:${port}`;

/// Obviously not a real secret, and 48 characters so it passes the length
/// check the Worker applies to a token before it will compare one at all.
const token = 'local-development-token-' + 'x'.repeat(24);

/// A key/value store that lives as long as the process does.
class MemoryKv {
  values = new Map();

  async get(name, type) {
    const held = this.values.get(name);
    if (held === undefined) return null;
    if (type === 'json') return JSON.parse(held.value);
    if (type === 'arrayBuffer') return held.value;
    return held.value;
  }

  async getWithMetadata(name) {
    const held = this.values.get(name);
    if (held === undefined) return {value: null, metadata: null};
    return {value: held.value, metadata: held.metadata ?? null};
  }

  async put(name, value, options = {}) {
    this.values.set(name, {value, metadata: options.metadata});
  }

  async delete(name) {
    this.values.delete(name);
  }

  async list({prefix = ''} = {}) {
    return {
      keys: [...this.values.entries()]
        .filter(([name]) => name.startsWith(prefix))
        .sort(([a], [b]) => (a < b ? -1 : 1))
        .map(([name, held]) => ({name, metadata: held.metadata})),
      list_complete: true,
    };
  }
}

/// Where the panel is served from, as the preview fixture sees it.
///
/// The panel runs on `localhost` and the preview on `127.0.0.1`. Same machine,
/// same port, and -- as far as the browser is concerned -- two different
/// origins. So the origin checks on both sides are exercised for real rather
/// than passing because everything happens to be same-origin.
const panelOrigin = `http://localhost:${port}`;
const previewOrigin = `http://127.0.0.1:${port}`;

/// The same object the deployed Worker would bind, standing in locally, so the
/// browser runs exercise the transactional path rather than the fallback.
const contentStore = durableNamespace(ContentStore);

const env = {
  ANALYTICS: new MemoryKv(),
  CONTENT: new MemoryKv(),
  CONTENT_STORE: contentStore,
  ADMIN_TOKEN: token,
  CONSOLE_TOKEN: 'local-console-token-' + 'y'.repeat(24),
  SITE_ORIGIN: origin,
  SITE_ID: `localhost:${port}`,
  BUNDLE_BASE: `${origin}/assets/assets/content`,
  PREVIEW_ORIGIN: previewOrigin,
  RELEASE_URL: `${origin}/release.json`,
};

const fixtures = new URL('../contracts/fixtures/', import.meta.url);

/// A stand-in for the public preview adapter, speaking protocol v1.
///
/// Codex has not built the real one. This exists so the editor's half can be
/// driven end to end -- handshake, draft, select, rendered, stale
/// acknowledgements -- instead of being declared finished on the strength of
/// having been written.
function previewFixture(session) {
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="robots" content="noindex, nofollow">
<title>Preview fixture</title>
<style>
  body { font: 14px/1.5 system-ui, sans-serif; background: #fff; color: #111;
    margin: 0; padding: 16px; }
  [data-content-path] { padding: 4px 6px; border-radius: 4px; }
  [data-content-path].chosen { outline: 3px solid #E3A93F; background: #FFF6E3; }
  h1 { font-size: 20px; margin: 0 0 12px; }
</style></head>
<body>
<h1 id="heading">Preview fixture</h1>
<div id="rendered"></div>
<script>
const SESSION = ${JSON.stringify(session)};
const PARENT = ${JSON.stringify(panelOrigin)};
const send = (type, payload) => parent.postMessage(
  {channel: 'portfolio-preview', version: 1, sessionId: SESSION, type, payload},
  PARENT,
);

/// Renders every leaf of the draft with the attributes the real components
/// have agreed to carry.
function draw(file, document_, locale) {
  const into = document.getElementById('rendered');
  into.replaceChildren();
  const ids = [];
  const walk = (value, path) => {
    if (value !== null && typeof value === 'object') {
      for (const key of Object.keys(value)) walk(value[key], path.concat([key]));
      return;
    }
    const at = path.join('.');
    const line = document.createElement('p');
    line.dataset.contentFile = file;
    line.dataset.contentPath = at;
    line.textContent = at + ': ' + String(value);
    into.append(line);
    ids.push(file + ':' + at);
  };
  walk(document_, []);
  document.getElementById('heading').textContent = file + ' (' + locale + ')';
  return ids;
}

addEventListener('message', (event) => {
  if (event.origin !== PARENT) return;
  const message = event.data;
  if (!message || message.channel !== 'portfolio-preview') return;
  if (message.version !== 1 || message.sessionId !== SESSION) return;

  if (message.type === 'draft') {
    const ids = draw(
      message.payload.file, message.payload.document, message.payload.locale,
    );
    send('rendered', {requestId: message.payload.requestId, componentIds: ids, errors: []});
    report({
      file: message.payload.file,
      locale: message.payload.locale,
      componentIds: ids,
      text: document.body.innerText,
      raw: JSON.stringify(message),
    });
    return;
  }
  if (message.type === 'select') {
    for (const node of document.querySelectorAll('.chosen')) {
      node.classList.remove('chosen');
    }
    const wanted = String(message.payload.componentId || '');
    const path = wanted.slice(wanted.indexOf(':') + 1);
    // Closest rendered parent, as the reply describes: a leaf that is not
    // drawn on its own highlights whatever contains it.
    let found = document.querySelector('[data-content-path="' + path + '"]');
    // A path that names a group rather than a value: this fixture only draws
    // leaves, so the nearest thing it has is the first one inside the group.
    // The real components render the group itself and will match directly.
    if (!found && path) {
      found = [...document.querySelectorAll('[data-content-path]')]
        .find((node) => node.dataset.contentPath.startsWith(path + '.')) || null;
    }
    if (!found && path) {
      const parts = path.split('.');
      while (parts.length > 0 && !found) {
        parts.pop();
        found = document.querySelector('[data-content-path="' + parts.join('.') + '"]');
      }
    }
    if (found) {
      found.classList.add('chosen');
      found.scrollIntoView({block: 'center'});
    }
    report({chosen: found ? found.dataset.contentPath : null, asked: wanted});
  }
});

/// Tells the harness what just happened.
///
/// The panel and this page are deliberately different origins, so a test
/// driving the panel cannot read into this document -- which is the point.
/// This is how the harness observes it instead, and it is not part of the
/// protocol.
let reported = {};
function report(fields) {
  reported = Object.assign({}, reported, fields);
  fetch(PARENT + '/__preview-log', {
    method: 'POST',
    headers: {'content-type': 'text/plain'},
    body: JSON.stringify(reported),
  }).catch(() => {});
}

// The other side waits for this before sending anything.
send('ready', {schemaVersions: [1], components: []});
</script>
</body></html>`;
}

async function serveFixture(name) {
  if (!/^[a-z]+\.json$/.test(name)) return null;
  try {
    return await readFile(new URL(name, fixtures), 'utf8');
  } catch {
    return null;
  }
}

/// The last thing the preview fixture reported. Harness only.
let previewLog = {};

const server = createServer(async (incoming, outgoing) => {
  const url = new URL(incoming.url, origin);

  // What the preview fixture says it did. Harness only.
  if (url.pathname === '/__preview-log') {
    if (incoming.method === 'OPTIONS') {
      outgoing.writeHead(204, {
        'access-control-allow-origin': '*',
        'access-control-allow-headers': 'content-type',
      }).end();
      return;
    }
    if (incoming.method === 'POST') {
      const body = [];
      for await (const chunk of incoming) body.push(chunk);
      previewLog = JSON.parse(Buffer.concat(body).toString());
      outgoing.writeHead(200, {'access-control-allow-origin': '*'}).end('{}');
      return;
    }
    outgoing.writeHead(200, {
      'content-type': 'application/json',
      'access-control-allow-origin': '*',
    });
    outgoing.end(JSON.stringify(previewLog));
    return;
  }

  // The preview adapter stand-in, on the other origin.
  if (url.pathname === '/' && incoming.method === 'GET') {
    outgoing.writeHead(200, {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
      'x-robots-tag': 'noindex, nofollow',
    });
    outgoing.end(previewFixture(url.searchParams.get('session') ?? ''));
    return;
  }

  // What the public build writes. Absent unless RELEASE_REVISION is set, so
  // the "nothing is serving a release yet" state is the default here too.
  if (url.pathname === '/release.json' && incoming.method === 'GET') {
    if (!process.env.RELEASE_REVISION) {
      outgoing.writeHead(404).end('Not found');
      return;
    }
    outgoing.writeHead(200, {'content-type': 'application/json'});
    outgoing.end(JSON.stringify({
      schemaVersion: 1,
      revision: process.env.RELEASE_REVISION,
      pages: ['/'],
    }));
    return;
  }

  // Stands in for the site's own bundle, which is on GitHub Pages in
  // production. The panel reads it to show what the site would fall back to.
  if (url.pathname.startsWith('/assets/assets/content/')) {
    const body = await serveFixture(url.pathname.split('/').pop());
    if (body === null) {
      outgoing.writeHead(404).end('Not found');
      return;
    }
    outgoing.writeHead(200, {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
    });
    outgoing.end(body);
    return;
  }

  // Puts a counter straight into the store, so the dashboard can be exercised
  // against data without turning collection on anywhere.
  //
  // This lives in the harness and **only** in the harness. There is no such
  // route in `worker/src/index.js` and there must never be one: an endpoint
  // that writes analytics counters on request is an endpoint that can make the
  // owner's own numbers say anything.
  if (url.pathname === '/__seed' && incoming.method === 'POST') {
    if (incoming.headers.authorization !== 'Bearer ' + token) {
      outgoing.writeHead(401).end('no');
      return;
    }
    const body = [];
    for await (const chunk of incoming) body.push(chunk);
    const {key, value} = JSON.parse(Buffer.concat(body).toString());
    await env.ANALYTICS.put(key, String(value));
    outgoing.writeHead(200, {'content-type': 'application/json'});
    outgoing.end('{"seeded":true}');
    return;
  }

  // Holds a write open, so a browser run can navigate away, reorder something
  // or keep typing while one is still in flight. Harness only, and driven by
  // the environment so the panel itself is unchanged.
  const slow = url.pathname.startsWith('/v1/admin/media')
    ? Number(process.env.UPLOAD_DELAY ?? 0)
    : url.pathname.startsWith('/v1/admin/content/') && incoming.method === 'PUT'
      ? Number(process.env.PUBLISH_DELAY ?? 0)
      : 0;
  if (slow > 0) await new Promise((done) => setTimeout(done, slow));

  const chunks = [];
  for await (const chunk of incoming) chunks.push(chunk);
  const body = chunks.length > 0 ? Buffer.concat(chunks) : undefined;

  const request = new Request(origin + incoming.url, {
    method: incoming.method,
    headers: incoming.headers,
    body,
  });

  try {
    const response = await handleRequest(request, env);
    const headers = {};
    response.headers.forEach((value, key) => {
      headers[key] = value;
    });
    outgoing.writeHead(response.status, headers);
    outgoing.end(Buffer.from(await response.arrayBuffer()));
  } catch (error) {
    outgoing.writeHead(500, {'content-type': 'text/plain'});
    outgoing.end(String(error && error.stack ? error.stack : error));
  }
});

server.listen(port, () => {
  process.stdout.write(`admin harness on ${origin}/admin\ntoken ${token}\n`);
});
