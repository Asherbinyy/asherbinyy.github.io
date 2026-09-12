import assert from 'node:assert/strict';
import { loadSnapshot, metadata, publicPages } from '../src/lib/content.mjs';

const origin = new URL(process.argv[2] ?? 'http://127.0.0.1:4321');
const snapshot = loadSnapshot();
const pages = publicPages(snapshot);
let checked = 0;
for (const page of pages) {
  const paths = new Set([page.path, page.path === '/' ? '/' : page.path.slice(0, -1)]);
  for (const path of paths) {
    const response = await fetch(new URL(path, origin), { signal: AbortSignal.timeout(10000) });
    assert.equal(response.status, 200, `Public document: ${path}`);
    assert.ok(response.headers.get('content-type')?.includes('text/html'), `HTML response: ${path}`);
    const html = await response.text();
    assert.ok(html.includes('<main'), `Readable body: ${path}`);
    assert.ok(html.includes(`href="${metadata(page, snapshot).canonical}"`), `Canonical: ${path}`);
    assert.ok(html.includes(`content="${snapshot.revision}"`), `Revision: ${path}`);
    checked++;
  }
}
for (const path of ['/work/does-not-exist/', '/ar/work/does-not-exist/', '/does-not-exist']) {
  const response = await fetch(new URL(path, origin), { signal: AbortSignal.timeout(10000) });
  assert.equal(response.status, 404, `Missing document: ${path}`);
}
const manifest = await fetch(new URL('/release.json', origin));
assert.equal(manifest.status, 200);
assert.equal((await manifest.json()).revision, snapshot.revision);
console.log(`Verified ${checked} direct URL forms, 3 missing-page responses and the served release revision at ${origin.origin}.`);
