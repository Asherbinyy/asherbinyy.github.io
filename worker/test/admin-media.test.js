import assert from 'node:assert/strict';
import test from 'node:test';

import {handleRequest} from '../src/index.js';

const siteOrigin = 'https://asherbinyy.github.io';
const adminToken = 'b'.repeat(48);

class MemoryKv {
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
        .map(([name, held]) => ({name, metadata: held.metadata})),
      list_complete: true,
    };
  }
}

const environment = () => ({
  ANALYTICS: new MemoryKv(),
  CONTENT: new MemoryKv(),
  ADMIN_TOKEN: adminToken,
  SITE_ORIGIN: siteOrigin,
  SITE_ID: 'asherbinyy.github.io',
});

function upload(path, type, body, token = adminToken) {
  return new Request(`https://worker.example${path}`, {
    method: 'POST',
    headers: token
      ? {authorization: `Bearer ${token}`, 'content-type': type}
      : {'content-type': type},
    body,
  });
}

// --- byte builders ---------------------------------------------------------

/// A real RIFF/WAVE header with [seconds] of silence behind it.
function wavBytes(seconds = 1.5, sampleRate = 8000, bits = 16, channels = 1) {
  const byteRate = (sampleRate * bits * channels) / 8;
  const dataSize = Math.round(byteRate * seconds);
  const bytes = new Uint8Array(44 + dataSize);
  const view = new DataView(bytes.buffer);
  const ascii = (at, text) => {
    for (let index = 0; index < text.length; index += 1) {
      bytes[at + index] = text.charCodeAt(index);
    }
  };
  ascii(0, 'RIFF');
  view.setUint32(4, 36 + dataSize, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, byteRate, true);
  view.setUint16(32, (bits * channels) / 8, true);
  view.setUint16(34, bits, true);
  ascii(36, 'data');
  view.setUint32(40, dataSize, true);
  return bytes;
}

/// An MPEG-4 container carrying nothing but the movie header, which is where
/// the length is stated.
function m4aBytes(seconds = 1.4, timescale = 1000) {
  const bytes = new Uint8Array(16 + 8 + 32);
  const view = new DataView(bytes.buffer);
  const ascii = (at, text) => {
    for (let index = 0; index < text.length; index += 1) {
      bytes[at + index] = text.charCodeAt(index);
    }
  };
  view.setUint32(0, 16);
  ascii(4, 'ftyp');
  ascii(8, 'M4A ');
  ascii(12, '   ');

  view.setUint32(16, 40);
  ascii(20, 'moov');
  view.setUint32(24, 32);
  ascii(28, 'mvhd');
  view.setUint32(32, 0); // version 0, no flags
  view.setUint32(36, 0); // created
  view.setUint32(40, 0); // modified
  view.setUint32(44, timescale);
  view.setUint32(48, Math.round(seconds * timescale));
  return bytes;
}

function mp3Bytes() {
  const bytes = new Uint8Array(512);
  // "ID3", version 2.4.
  bytes.set([0x49, 0x44, 0x33, 0x04, 0x00, 0x00], 0);
  return bytes;
}

function pngBytes(width = 64, height = 64) {
  const bytes = new Uint8Array(64);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10], 0);
  const view = new DataView(bytes.buffer);
  view.setUint32(16, width);
  view.setUint32(20, height);
  return bytes;
}

// --- what the endpoint takes -----------------------------------------------

test('a recording is stored and its length read from its header', async () => {
  const env = environment();
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', wavBytes(1.5)),
    env,
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.seconds, 1.5);
  assert.match(body.url, /^\/v1\/media\/[0-9a-f]{32}$/);
});

test('an MPEG-4 recording states its own length', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', m4aBytes(1.4)),
    environment(),
  );
  assert.equal(response.status, 200);
  assert.equal((await response.json()).seconds, 1.4);
});

test('a length the container does not state is reported as unknown', async () => {
  // Not estimated from the byte count. A wrong duration beside a play button
  // is worse than no duration.
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mpeg', mp3Bytes()),
    environment(),
  );
  assert.equal(response.status, 200);
  assert.equal((await response.json()).seconds, null);
});

test('the same recording twice is one stored file', async () => {
  const env = environment();
  const first = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', wavBytes(1)),
    env,
  );
  const second = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', wavBytes(1)),
    env,
  );
  assert.equal((await first.json()).id, (await second.json()).id);
});

// --- what it refuses -------------------------------------------------------

test('sound cannot be pushed through the image endpoint', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media', 'audio/wav', wavBytes(1)),
    environment(),
  );
  assert.equal(response.status, 415);
});

test('an image cannot be pushed through the recording endpoint', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'image/png', pngBytes()),
    environment(),
  );
  assert.equal(response.status, 415);
});

test('a recording that is not what it says it is, is refused', async () => {
  // The header is read, so a WAV declared as an MPEG-4 is caught on its bytes
  // rather than on the caller's word.
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', wavBytes(1)),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('something that is not a recording at all is refused', async () => {
  const text = new TextEncoder().encode('not audio, just some text');
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mpeg', text),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('an MPEG-4 file that is not audio is refused on its brand', async () => {
  const video = m4aBytes(1);
  for (const [index, character] of [...'mp4v'].entries()) {
    video[8 + index] = character.charCodeAt(0);
  }
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', video),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('an empty recording is refused', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', new Uint8Array(0)),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('a recording larger than the limit is refused', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', wavBytes(400, 44100, 16, 2)),
    environment(),
  );
  assert.equal(response.status, 413);
});

test('uploading a recording needs the admin token', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/wav', wavBytes(1), null),
    environment(),
  );
  assert.equal(response.status, 401);
});

// --- the library -----------------------------------------------------------

test('the library says which of its entries are recordings', async () => {
  const env = environment();
  await handleRequest(upload('/v1/admin/media/audio', 'audio/wav', wavBytes(1)), env);
  await handleRequest(upload('/v1/admin/media', 'image/png', pngBytes(80, 60)), env);

  const listed = await handleRequest(
    new Request('https://worker.example/v1/admin/media', {
      headers: {authorization: `Bearer ${adminToken}`},
    }),
    env,
  );
  const {media} = await listed.json();
  assert.equal(media.length, 2);
  assert.deepEqual(media.map((entry) => entry.kind).sort(), ['audio', 'image']);
  const sound = media.find((entry) => entry.kind === 'audio');
  assert.equal(sound.seconds, 1);
  assert.ok(sound.bytes > 0);
});

test('a stored recording is served with its own type', async () => {
  const env = environment();
  const stored = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', m4aBytes(1.4)),
    env,
  );
  const {id} = await stored.json();
  const served = await handleRequest(
    new Request(`https://worker.example/v1/media/${id}`),
    env,
  );
  assert.equal(served.status, 200);
  assert.equal(served.headers.get('content-type'), 'audio/mp4');
  // The same sandbox and nosniff the images get: this is a public URL on the
  // owner's own domain.
  assert.match(served.headers.get('content-security-policy'), /sandbox/);
  assert.equal(served.headers.get('x-content-type-options'), 'nosniff');
});

// --- AR-8: a truncated file is a validation error, not a crash -------------

/// An MPEG-4 whose movie header is cut short.
///
/// [version] 1 widened the timestamps, so its header runs twelve bytes longer
/// than version 0. Checking one length for both walked a DataView off the end
/// of the buffer and threw, which reached the caller as a 500 for what is
/// really "that file is broken".
function truncatedM4a(version, keep) {
  const full = m4aBytes(1.4);
  const bytes = full.slice(0, keep);
  if (bytes.length > 32) bytes[32] = version;
  return bytes;
}

test('a truncated version-1 recording is refused, not a crash', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', truncatedM4a(1, 52)),
    environment(),
  );
  assert.equal(response.status, 400);
  assert.match((await response.json()).error, /readable/i);
});

test('a truncated version-0 recording is refused too', async () => {
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', truncatedM4a(0, 40)),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('every truncation of a valid recording answers 400 or 200, never 500', async () => {
  // Walked byte by byte rather than at one chosen length: the point is that no
  // cut produces an unhandled error.
  const env = environment();
  const full = m4aBytes(1.4);
  for (let keep = 1; keep <= full.length; keep += 1) {
    const response = await handleRequest(
      upload('/v1/admin/media/audio', 'audio/mp4', full.slice(0, keep)),
      env,
    );
    assert.ok(
      response.status === 400 || response.status === 200,
      `${keep} bytes answered ${response.status}`,
    );
  }
});

test('a truncated image is refused rather than throwing', async () => {
  const env = environment();
  const full = pngBytes(64, 64);
  for (let keep = 1; keep <= full.length; keep += 1) {
    const response = await handleRequest(
      upload('/v1/admin/media', 'image/png', full.slice(0, keep)),
      env,
    );
    assert.ok(
      response.status === 400 || response.status === 200,
      `${keep} bytes answered ${response.status}`,
    );
  }
});

test('an mvhd claiming to be longer than the file is refused', async () => {
  const bytes = m4aBytes(1.4);
  // Version 1, but the file only holds a version-0 header.
  bytes[32] = 1;
  const response = await handleRequest(
    upload('/v1/admin/media/audio', 'audio/mp4', bytes),
    environment(),
  );
  assert.equal(response.status, 400);
});
