import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

import {documents, editableFiles} from '../contracts/content-schema.js';
import {
  changedClaims,
  collectClaims,
  differences,
  validateDocument,
} from '../contracts/validate.js';

async function read(where, file) {
  return JSON.parse(
    await readFile(new URL(`${where}/${file}`, import.meta.url), 'utf8'),
  );
}

const bundled = (file) => read('../../assets/content', file);
const fixture = (file) => read('../contracts/fixtures', file);

async function referencesFrom(load) {
  const apps = await load('apps.json');
  return {'apps.json': apps.apps.map((entry) => entry.id)};
}

// --- the schema has to describe the documents that already exist -----------

test('every document the owner ships is valid against the schema', async () => {
  // The point of this one. The schema is a second description of a shape the
  // Dart models already define, and a second description drifts. If it ever
  // disagrees with what the app actually parses, the publish endpoint starts
  // refusing the owner's own content, and this fails first.
  const references = await referencesFrom(bundled);
  for (const file of editableFiles) {
    const verdict = validateDocument(file, await bundled(file), {references});
    assert.deepEqual(
      verdict.errors,
      [],
      `${file} should have no schema errors`,
    );
  }
});

test('every fixture is valid against the schema', async () => {
  const references = await referencesFrom(fixture);
  for (const file of editableFiles) {
    const verdict = validateDocument(file, await fixture(file), {references});
    assert.deepEqual(verdict.errors, [], `${file} fixture`);
  }
});

test('a document nobody edits is refused rather than guessed at', () => {
  const verdict = validateDocument('secrets.json', {});
  assert.equal(verdict.errors.length, 1);
});

// --- the rules -------------------------------------------------------------

test('a missing required field is an error and an absent optional one is not', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    contact: {email: 'a@b.co'},
  });
  const paths = verdict.errors.map((issue) => issue.path);
  assert.ok(paths.includes('positioning'));
  assert.ok(!paths.includes('biography'));
});

test('an absent optional link written as null is not an error', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co', calendly: null, github: null},
  });
  assert.deepEqual(verdict.errors, []);
});

test('a field the site has no reader for is refused', () => {
  // Not a warning. A key the app discards is content the owner believes he
  // published, and "saved" for something invisible is the defect this closes.
  const verdict = validateDocument('interests.json', {
    interests: [],
    favouriteColour: 'gold',
  });
  assert.equal(verdict.errors.length, 1);
  assert.equal(verdict.errors[0].path, 'favouriteColour');
});

test('a missing Arabic translation warns and never fails', () => {
  const verdict = validateDocument('interests.json', {
    interests: [{id: 'chess', label: {en: 'Chess'}}],
  });
  assert.deepEqual(verdict.errors, []);
  assert.equal(verdict.warnings.length, 1);
  assert.equal(verdict.warnings[0].path, 'interests.0.label');
});

test('a localised value with no English is an error', () => {
  const verdict = validateDocument('interests.json', {
    interests: [{id: 'chess', label: {ar: 'شطرنج'}}],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'interests.0.label'));
});

test('a link that is not a complete address is refused', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co', github: 'github.com/example'},
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'contact.github'));
});

test('two entries cannot share an identifier', () => {
  const verdict = validateDocument('interests.json', {
    interests: [
      {id: 'chess', label: {en: 'Chess'}},
      {id: 'chess', label: {en: 'Also chess'}},
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'interests.1.id'));
});

test('an identifier that is not a slug is refused', () => {
  const verdict = validateDocument('interests.json', {
    interests: [{id: 'Chess Club', label: {en: 'Chess'}}],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'interests.0.id'));
});

test('a value outside a stated range is refused', () => {
  const verdict = validateDocument('education.json', {
    entries: [
      {
        institution: {en: 'A'},
        award: {en: 'B'},
        start: '2024-09',
        end: '2025-09',
        modules: [{name: {en: 'M'}, mark: 140}],
      },
    ],
  });
  assert.ok(
    verdict.errors.some((issue) => issue.path === 'entries.0.modules.0.mark'),
  );
});

test('a date has to be a year and a month', () => {
  const verdict = validateDocument('education.json', {
    entries: [
      {institution: {en: 'A'}, award: {en: 'B'}, start: 'last autumn', end: '2025-09'},
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'entries.0.start'));
});

test('a choice outside the ones the app understands is refused', () => {
  const verdict = validateDocument('apps.json', {
    apps: [
      {id: 'a', name: 'A', platforms: ['ios'], store: {}, domain: 'Aerospace'},
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'apps.0.domain'));
});

test('a store the app has no listing model for is refused', () => {
  const verdict = validateDocument('apps.json', {
    apps: [
      {
        id: 'a',
        name: 'A',
        platforms: ['ios'],
        store: {windows: 'https://example.com/app'},
        domain: 'Travel',
      },
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'apps.0.store.windows'));
});

test('an image field will not take anything but stored media or a bundle path', () => {
  const verdict = validateDocument('interests.json', {
    interests: [
      {id: 'a', label: {en: 'A'}, logo: 'https://example.com/crest.png'},
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'interests.0.logo'));
});

test('coordinates outside the world are refused', () => {
  const verdict = validateDocument('career.json', {
    roles: [
      {
        id: 'a',
        kind: 'role',
        country: 'GB',
        city: 'Nowhere',
        coords: [800, 0],
        start: '2020-01',
      },
    ],
  });
  assert.ok(verdict.errors.some((issue) => issue.path.startsWith('roles.0.coords')));
});

// --- references ------------------------------------------------------------

test('a stop pointing at an application that does not exist is refused', () => {
  const stop = {
    roles: [
      {
        id: 'a',
        kind: 'role',
        country: 'GB',
        city: 'Testchester',
        coords: [53, -2],
        start: '2020-01',
        appIds: ['gone'],
      },
    ],
  };
  const verdict = validateDocument('career.json', stop, {
    references: {'apps.json': ['example-one']},
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'roles.0.appIds.0'));
});

test('a reference nobody can check is reported as unchecked, not as broken', () => {
  const verdict = validateDocument('career.json', {
    roles: [
      {
        id: 'a',
        kind: 'role',
        country: 'GB',
        city: 'Testchester',
        coords: [53, -2],
        start: '2020-01',
        appIds: ['maybe'],
      },
    ],
  });
  assert.deepEqual(verdict.errors, []);
  assert.equal(verdict.warnings.length, 1);
});

// --- claims ----------------------------------------------------------------

test('a figure written as text is a claim', async () => {
  // The rule the old panel got wrong: it asked for a source when a JSON
  // number changed, and every figure on this site that matters is a string.
  const claims = collectClaims('apps.json', await bundled('apps.json'));
  const values = claims.map((claim) => claim.value);
  assert.ok(values.includes('50% retention lift'));
  assert.ok(values.every((value) => typeof value === 'string'));
});

test('a figure in the profile is a claim even though it reads as a word', async () => {
  const claims = collectClaims('profile.json', await bundled('profile.json'));
  assert.deepEqual(
    claims.map((claim) => claim.path),
    ['stats.0.value', 'stats.1.value'],
  );
});

test('only the claims that moved need a source', async () => {
  const before = await fixture('profile.json');
  const after = JSON.parse(JSON.stringify(before));
  after.stats[0].value = '5+';
  after.location = {en: 'Elsewhere'};
  const moved = changedClaims('profile.json', before, after);
  assert.equal(moved.length, 1);
  assert.equal(moved[0].path, 'stats.0.value');
  assert.equal(moved[0].was, '4+');
});

test('a claim added where there was none counts as changed', async () => {
  const before = await fixture('apps.json');
  const after = JSON.parse(JSON.stringify(before));
  after.apps[1].metric = '10,000 downloads';
  const moved = changedClaims('apps.json', before, after);
  assert.equal(moved.length, 1);
  assert.equal(moved[0].was, null);
});

// --- differences -----------------------------------------------------------

test('a difference is reported per value, not per document', async () => {
  const before = await fixture('interests.json');
  const after = JSON.parse(JSON.stringify(before));
  after.interests[0].label.en = 'Hiking';
  after.interests[2].label.ar = 'شطرنج';
  const changes = differences(before, after);
  assert.deepEqual(
    changes.map((change) => change.path),
    ['interests.0.label.en', 'interests.2.label.ar'],
  );
});

test('a removed entry is a difference', async () => {
  const before = await fixture('interests.json');
  const after = JSON.parse(JSON.stringify(before));
  after.interests.pop();
  const changes = differences(before, after);
  assert.equal(changes.length, 1);
  assert.equal(changes[0].after, null);
});

test('an unchanged document has no differences', async () => {
  const before = await fixture('career.json');
  assert.deepEqual(differences(before, JSON.parse(JSON.stringify(before))), []);
});

// --- the shape of the schema itself ----------------------------------------

test('every document declares a section name and a file', () => {
  for (const document of documents) {
    assert.ok(document.section, `${document.file} needs a section name`);
    assert.match(document.file, /\.json$/);
  }
});

test('every field an editor has to draw declares a label and a kind', () => {
  const seen = (field, where) => {
    assert.ok(field.kind, `${where} needs a kind`);
    if (field.key !== undefined) {
      assert.ok(field.label, `${where}.${field.key} needs a label`);
    }
    if (field.kind === 'object') {
      for (const child of field.fields) seen(child, `${where}.${field.key}`);
    }
    if (field.kind === 'list') seen(field.of, `${where}.${field.key}[]`);
    if (field.kind === 'choice' || field.kind === 'choiceList') {
      assert.ok(field.options.length > 0, `${where}.${field.key} needs options`);
    }
  };
  for (const document of documents) {
    for (const field of document.fields) seen(field, document.file);
  }
});

// --- the fields Codex accepted in the A1 integration reply -----------------

test('a link needs an identifier, a label and a real address', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co'},
    links: [{id: 'medium', label: {en: 'Medium'}, url: 'medium.com/@a'}],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'links.0.url'));
});

test('the old contact block keeps working beside the new links', () => {
  // Additive, per the reply. Nothing is migrated until the consumer exists.
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co', github: 'https://github.com/a'},
    links: [{id: 'medium', label: {en: 'Medium'}, url: 'https://medium.com/@a'}],
  });
  assert.deepEqual(verdict.errors, []);
});

test('a gallery picture needs a file and a video needs an address', () => {
  const base = {
    id: 'a', name: 'A', platforms: ['ios'], store: {}, domain: 'Travel',
  };
  const missingFile = validateDocument('apps.json', {
    apps: [{...base, media: [{id: 'one', kind: 'image', alt: {en: 'A screen'}}]}],
  });
  assert.ok(missingFile.errors.some((issue) => issue.path === 'apps.0.media.0.image'));

  const missingUrl = validateDocument('apps.json', {
    apps: [{...base, media: [{id: 'one', kind: 'video', alt: {en: 'A clip'}}]}],
  });
  assert.ok(missingUrl.errors.some((issue) => issue.path === 'apps.0.media.0.url'));
});

test('a gallery entry cannot be both a picture and a video', () => {
  const verdict = validateDocument('apps.json', {
    apps: [{
      id: 'a', name: 'A', platforms: ['ios'], store: {}, domain: 'Travel',
      media: [{
        id: 'one',
        kind: 'image',
        image: 'assets/media/portrait.jpg',
        url: 'https://example.com/v',
        alt: {en: 'A screen'},
      }],
    }],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'apps.0.media.0.url'));
});

test('a gallery entry has to say what it shows', () => {
  // Alt text is the one thing a gallery cannot ship without: it is what
  // anyone who cannot see the picture gets instead of it.
  const verdict = validateDocument('apps.json', {
    apps: [{
      id: 'a', name: 'A', platforms: ['ios'], store: {}, domain: 'Travel',
      media: [{id: 'one', kind: 'image', image: 'assets/media/portrait.jpg'}],
    }],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'apps.0.media.0.alt'));
});

test('a complete gallery entry is accepted', () => {
  const verdict = validateDocument('apps.json', {
    apps: [{
      id: 'a', name: 'A', platforms: ['ios'], store: {}, domain: 'Travel',
      media: [
        {
          id: 'one',
          kind: 'image',
          image: '/v1/media/' + 'a'.repeat(32),
          alt: {en: 'The booking screen'},
        },
        {
          id: 'two',
          kind: 'video',
          url: 'https://example.com/clip',
          alt: {en: 'A walkthrough'},
        },
      ],
    }],
  });
  assert.deepEqual(verdict.errors, []);
});

test('two gallery entries cannot share an identifier', () => {
  const verdict = validateDocument('interests.json', {
    interests: [{
      id: 'a',
      label: {en: 'A'},
      gallery: [
        {id: 'one', kind: 'image', image: 'assets/media/a.jpg', alt: {en: 'x'}},
        {id: 'one', kind: 'image', image: 'assets/media/b.jpg', alt: {en: 'y'}},
      ],
    }],
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'interests.0.gallery.1.id'));
});

test('the name recording takes a sound file, not a picture', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co'},
    nameAudio: {src: 'https://example.com/name.mp3'},
  });
  assert.ok(verdict.errors.some((issue) => issue.path === 'nameAudio.src'));
});

test('the recording length is optional, because it comes from the file', () => {
  const verdict = validateDocument('profile.json', {
    name: {en: 'A'},
    positioning: {en: 'B'},
    contact: {email: 'a@b.co'},
    nameAudio: {src: '/v1/media/' + 'b'.repeat(32)},
  });
  assert.deepEqual(verdict.errors, []);
});

test('every field agreed but not yet rendered says so', () => {
  // The editor draws this as "not on the site yet". A field that quietly
  // looked live would be the defect A1 closed, reopened.
  const pending = [];
  const walk = (field, where) => {
    if (field.consumer === 'pending') pending.push(where + '.' + field.key);
    if (field.kind === 'object') field.fields.forEach((c) => walk(c, where));
    if (field.kind === 'list') walk(field.of, where);
  };
  for (const document of documents) {
    for (const field of document.fields) walk(field, document.file);
  }
  assert.deepEqual(pending.sort(), [
    'apps.json.media',
    'interests.json.gallery',
    'profile.json.links',
    'profile.json.nameAudio',
  ]);
});
