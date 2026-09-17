import assert from 'node:assert/strict';
import test from 'node:test';
import {readFileSync} from 'node:fs';

import {
  APPEARANCE_VERSION,
  SUPPORTED,
  resolveAppearance,
  supportsAppearance,
} from '../contracts/appearance.js';

/// Holds the Worker's allowlist to the same fixture the app is held to.
const fixture = JSON.parse(
  readFileSync(
    new URL('../contracts/fixtures/appearance-v1.json', import.meta.url),
    'utf8',
  ),
);

test('the allowlist is the one the fixture records', () => {
  assert.equal(APPEARANCE_VERSION, fixture.version);
  assert.deepEqual(SUPPORTED, fixture.supported);
});

test('every id resolves the way the fixture says', () => {
  for (const row of fixture.resolutions) {
    const result = resolveAppearance(row.id);
    assert.equal(result.state, row.state, `id ${JSON.stringify(row.id)}`);
    if (row.state === 'unsupported') {
      // The id is carried, not discarded: "unsupported appearance" is a shrug,
      // "unsupported appearance: papyrus-v2" is actionable.
      assert.equal(result.id, String(row.id));
    }
  }
});

test('an id is matched exactly, not loosely', () => {
  // Case and whitespace are not forgiven. A stored id is a key, and a key that
  // matches approximately is a key that will one day match the wrong thing.
  assert.equal(supportsAppearance('nocturne'), true);
  assert.equal(supportsAppearance('Nocturne'), false);
  assert.equal(supportsAppearance(' nocturne'), false);
  assert.equal(supportsAppearance(42), false);
  assert.equal(supportsAppearance(null), false);
});
