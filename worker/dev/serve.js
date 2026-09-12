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

const env = {
  ANALYTICS: new MemoryKv(),
  CONTENT: new MemoryKv(),
  ADMIN_TOKEN: token,
  CONSOLE_TOKEN: 'local-console-token-' + 'y'.repeat(24),
  SITE_ORIGIN: origin,
  SITE_ID: `localhost:${port}`,
  BUNDLE_BASE: `${origin}/assets/assets/content`,
};

const fixtures = new URL('../contracts/fixtures/', import.meta.url);

async function serveFixture(name) {
  if (!/^[a-z]+\.json$/.test(name)) return null;
  try {
    return await readFile(new URL(name, fixtures), 'utf8');
  } catch {
    return null;
  }
}

const server = createServer(async (incoming, outgoing) => {
  const url = new URL(incoming.url, origin);

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
