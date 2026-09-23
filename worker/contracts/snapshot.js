/**
 * The immutable artifact a public build is made from.
 *
 * A build takes `PORTFOLIO_SNAPSHOT`, a path to a JSON file of exactly this
 * shape, and refuses to build if the revision inside it does not match a
 * digest it recomputes itself.
 *
 * Nothing here knows or cares which renderer consumes it. The artifact is a
 * set of documents and a digest over them. The owner has settled on Flutter
 * as the only interactive UI; this contract did not have to change for that,
 * and would not have to change again.
 *
 * So whoever builds the site and whoever produces the artifact have to agree
 * on the digest to the byte. The canonical form is: object keys sorted
 * recursively, array order kept, scalars encoded as ordinary JSON.
 *
 * That definition, not any particular implementation, is the contract. The
 * first one to exist was in the separate frontend, which the owner rejected
 * and which has been removed; the renderer is Flutter and its generator will
 * be a third implementation. `worker/test/snapshot.test.js` pins a frozen
 * synthetic document set to a literal digest and checks the canonical form
 * against literal expected strings, so a drift fails there rather than as a
 * build refusing an artifact for reasons nobody can place.
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
/// Do not "improve" it: any change here changes every revision identifier in
/// existence, and every consumer that recomputes one.
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
export async function buildSnapshot(documents) {
  // Derived from the documents being released, never from a hint the caller
  // supplied (AR-7). A release validated against somebody's list of
  // identifiers is validated against nothing: a career stop could point at an
  // application that is not in the snapshot, and the build would produce a
  // page linking to something that does not exist.
  const references = referencesWithin(documents);

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

/// Every identifier the documents in this release actually contain.
///
/// Only the resolved documents are consulted. Anything a caller offered is
/// ignored, which is the point: a snapshot is the last check before a build,
/// and it has every document in front of it, so there is nothing it needs to
/// be told.
function referencesWithin(documents) {
  const found = {};
  for (const [file, document] of Object.entries(documents)) {
    if (document === null || typeof document !== 'object') continue;
    for (const value of Object.values(document)) {
      if (!Array.isArray(value)) continue;
      const ids = value
        .filter((entry) => entry !== null && typeof entry === 'object')
        .map((entry) => entry.id)
        .filter((id) => typeof id === 'string');
      if (ids.length > 0) {
        found[file] = ids;
        break;
      }
    }
    if (!found[file]) found[file] = [];
  }
  return found;
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
      // Not a failure. Nothing is serving a release file from the production
      // host yet, so there is nothing to read.
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
