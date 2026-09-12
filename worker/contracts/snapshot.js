/**
 * The immutable artifact a public build is made from.
 *
 * Codex answered R1 in `docs/23-ADMIN-INTEGRATION-REPLY.md`: Astro, semantic
 * HTML, build-and-release. The builder takes `PORTFOLIO_SNAPSHOT`, a path to a
 * JSON file of exactly this shape, and refuses to build if the revision inside
 * it does not match a digest it recomputes itself.
 *
 * So the two sides have to agree on the digest to the byte. The canonical form
 * is defined by `site/src/lib/content.mjs`: objects have their keys sorted
 * recursively, arrays keep their order, scalars encode as ordinary JSON. This
 * file is the Worker's implementation of the same thing, and
 * `worker/test/snapshot.test.js` pins it to a digest produced by Codex's
 * reference over the documents currently in `assets/content/`. If either side
 * drifts, that test fails rather than a build failing later with a mismatch
 * nobody can place.
 *
 * The digest is over the documents only. It deliberately does not include the
 * revision numbers, the change notes or anything else this Worker knows: two
 * publishes that leave the content identical describe the same public release,
 * and giving them different digests would mean rebuilding the site to produce
 * the same bytes.
 */

import {documentsByFile, editableFiles} from './content-schema.js';
import {validateDocument} from './validate.js';

/// The snapshot format Codex's builder accepts. Bumping this is a contract
/// change on both sides at once.
export const snapshotSchemaVersion = 1;

/// Canonical JSON: object keys sorted, array order kept, ordinary scalars.
///
/// Matches `stableJson` in `site/src/lib/content.mjs`. Do not "improve" it --
/// any change here changes every revision identifier in existence.
export function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

/// SHA-256 of the canonical form, as lower-case hex.
///
/// Async because a Worker has WebCrypto rather than `node:crypto`. The bytes
/// hashed are identical.
export async function digest(documents) {
  const encoded = new TextEncoder().encode(stableJson(documents));
  const hashed = await crypto.subtle.digest('SHA-256', encoded);
  return Array.from(new Uint8Array(hashed), (byte) =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
}

/// Builds the artifact, or says exactly why it cannot.
///
/// Every document is validated against the same schema the publish endpoint
/// uses. A snapshot that would fail the builder's own checks is not worth
/// handing to a build, and a build that fails halfway is harder to explain
/// than a refusal here.
export async function buildSnapshot(documents, {references = null} = {}) {
  const problems = [];
  for (const file of editableFiles) {
    if (!documents[file]) {
      problems.push({file, message: `${documentsByFile.get(file).section} is missing`});
      continue;
    }
    const verdict = validateDocument(file, documents[file], {references});
    for (const issue of verdict.errors) {
      problems.push({file, path: issue.path, message: issue.message});
    }
  }

  const extra = Object.keys(documents).filter(
    (file) => !editableFiles.includes(file),
  );
  for (const file of extra) {
    problems.push({file, message: 'Not a document the site is built from'});
  }
  if (problems.length > 0) return {problems, snapshot: null};

  // Rebuilt key by key in the canonical order rather than passed through, so
  // nothing that happened to be on the incoming object rides along into the
  // artifact.
  const included = {};
  for (const file of editableFiles) included[file] = documents[file];

  return {
    problems: [],
    snapshot: {
      schemaVersion: snapshotSchemaVersion,
      revision: await digest(included),
      documents: included,
    },
  };
}

/// What the public HTML is currently serving, read from its own release file.
///
/// `/release.json` is written by Codex's build and carries the digest of the
/// documents it was built from. Comparing it to the digest of what is
/// published here is the only honest way to answer "is the site showing this
/// yet", and it is why the panel does not say "published" until it matches.
export function compareRelease(expected, release) {
  if (release === null) {
    return {
      state: 'unreleased',
      expected,
      live: null,
      // Not a failure. The Astro slice is not the production host yet, so
      // there is nothing serving a release file to read.
      because: 'No release file is being served yet, so nothing can confirm the site was rebuilt.',
    };
  }
  if (typeof release.revision !== 'string') {
    return {
      state: 'unreadable',
      expected,
      live: null,
      because: 'The release file did not carry a revision.',
    };
  }
  if (release.revision === expected) {
    return {
      state: 'live',
      expected,
      live: release.revision,
      because: 'The site was built from exactly this content.',
    };
  }
  return {
    state: 'behind',
    expected,
    live: release.revision,
    because: 'The site is serving an older build. Publishing changed what the app reads; the HTML follows when a release runs.',
  };
}
