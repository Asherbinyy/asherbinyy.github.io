/**
 * The fake key/value store and request builders the admin tests share.
 *
 * `index.test.js` keeps its own copy: it exercises the analytics side too and
 * needs a store that records writes and their options. This is the smaller
 * thing the content, media and revision tests want.
 */

import {readFile} from 'node:fs/promises';

export const siteOrigin = 'https://asherbinyy.github.io';
export const adminToken = 'b'.repeat(48);

export class MemoryKv {
  values = new Map();

  async get(name, type) {
    const held = this.values.get(name);
    if (held === undefined) return null;
    return type === 'json' ? JSON.parse(held.value) : held.value;
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

export function environment(overrides = {}) {
  return {
    ANALYTICS: new MemoryKv(),
    CONTENT: new MemoryKv(),
    ADMIN_TOKEN: adminToken,
    SITE_ORIGIN: siteOrigin,
    SITE_ID: 'asherbinyy.github.io',
    ...overrides,
  };
}

/// An authenticated admin request. `headers` adds to the defaults.
export function admin(path, options = {}) {
  const {method = 'GET', body, token = adminToken, headers = {}} = options;
  const sent = {'content-type': 'application/json', ...headers};
  if (token) sent.authorization = `Bearer ${token}`;
  return new Request(`https://worker.example${path}`, {
    method,
    headers: sent,
    body: body === undefined
      ? undefined
      : (typeof body === 'string' ? body : JSON.stringify(body)),
  });
}

/// A read from the site, which is origin-gated.
export function fromSite(path) {
  return new Request(`https://worker.example${path}`, {
    headers: {origin: siteOrigin},
  });
}

/// One of the sanitized documents from `worker/contracts/fixtures/`.
export async function fixture(file) {
  return JSON.parse(
    await readFile(new URL(`../contracts/fixtures/${file}`, import.meta.url), 'utf8'),
  );
}
