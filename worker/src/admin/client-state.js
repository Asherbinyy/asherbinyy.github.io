/**
 * Draft state, the network, and the walk between a schema and a document.
 *
 * Served to the browser as part of the panel's one inline module. It is a
 * string here rather than a file because the panel's content-security-policy
 * allows inline script and nothing else, and loosening that for a page that
 * holds a token which can rewrite the site is a poor trade for tidiness.
 *
 * Two things in here are the point of the whole phase:
 *
 * 1. `docs` holds one entry per document, so switching section keeps the
 *    other four drafts exactly as they were. The panel this replaces had a
 *    single `draft` variable that `open()` overwrote (A-F2), which is how an
 *    afternoon's edits disappeared by clicking a tab.
 * 2. Controls are built from the schema, not from the document's existing
 *    keys, so a field the owner has never filled in is still there to fill in
 *    (A-F1). Emptying one removes the key again, so an untouched optional
 *    field never reaches the site as an empty string.
 *
 * No template literals anywhere in the client modules: they are embedded in
 * one, and escaping every backtick would be worse than concatenating.
 */

export const clientState = `
const state = {
  token: '',
  view: 'document',
  file: SCHEMA.documents[0].file,
  path: [],
  lang: 'en',
  docs: new Map(),
  issues: new Map(),
  checking: 0,
  media: null,
  mediaError: '',
  account: null,
  expires: null,
  insights: null,
  insightsError: '',
  rightPane: 'preview',
  release: null,
  releaseError: '',
  range: {
    id: '28',
    from: new Date(Date.now() - 27 * 86400000).toISOString().slice(0, 10),
    to: new Date().toISOString().slice(0, 10),
  },
};

const el = (id) => document.getElementById(id);

function say(text, kind) {
  const node = el('status');
  node.textContent = text;
  node.className = 'status ' + (kind || '');
}

function schemaFor(file) {
  return SCHEMA.documents.find((entry) => entry.file === file);
}

async function api(path, options) {
  const settings = options || {};
  const response = await fetch(path, Object.assign({}, settings, {
    headers: Object.assign(
      {authorization: 'Bearer ' + state.token},
      settings.headers || {},
    ),
  }));
  if (response.status === 401) {
    // A session that ran out mid-edit is not a reason to throw the drafts
    // away. Ask for the password over the top of the panel and leave
    // everything else exactly where it is.
    askAgain();
    throw new Error('Your session ended; sign in again to carry on');
  }
  if (response.status === 429) {
    throw new Error('Too many wrong attempts; the endpoint is closed for the hour');
  }
  return response;
}

/// What the site is showing, and what the owner has published over it.
///
/// Both are fetched so the panel can tell the difference between the two,
/// which is what makes "Withdraw" meaningful.
async function fetchDocument(name) {
  const shipped = await fetch(BUNDLE + '/' + name).then((r) => r.json());
  const response = await fetch('/v1/content/' + name).catch(() => null);
  if (response && response.ok) {
    return {shipped: shipped, published: await response.json()};
  }
  return {shipped: shipped, published: null};
}

/// Loads a document once. A second visit gets the draft already in progress.
async function ensure(name) {
  if (state.docs.has(name)) return state.docs.get(name);
  const loaded = await fetchDocument(name);
  const live = loaded.published || loaded.shipped;
  const entry = {
    live: live,
    draft: JSON.parse(JSON.stringify(live)),
    source: loaded.published ? 'published' : 'shipped',
  };
  state.docs.set(name, entry);
  return entry;
}

function current() {
  return state.docs.get(state.file);
}

function dirty(name) {
  const entry = state.docs.get(name);
  if (!entry) return false;
  return JSON.stringify(entry.live) !== JSON.stringify(entry.draft);
}

function anyDirty() {
  return SCHEMA.documents.some((entry) => dirty(entry.file));
}

// --- reading and writing a path --------------------------------------------

function getIn(root, path) {
  let at = root;
  for (const step of path) {
    if (at === null || at === undefined) return undefined;
    at = at[step];
  }
  return at;
}

/// Whether a value counts as the owner having left the field alone.
///
/// An empty box and an absent key mean the same thing to him, and they have
/// to mean the same thing to the document, or every field he tabbed through
/// ships as an empty string.
function blank(value) {
  if (value === undefined || value === null || value === '') return true;
  if (Array.isArray(value)) return value.length === 0;
  if (typeof value === 'object') {
    return Object.keys(value).every((key) => blank(value[key]));
  }
  return false;
}

function setIn(root, path, value) {
  if (path.length === 0) return value;
  const head = path[0];
  const rest = path.slice(1);
  const copy = Array.isArray(root) ? root.slice() : Object.assign({}, root || {});
  if (rest.length === 0) {
    if (value === undefined) {
      if (Array.isArray(copy)) copy.splice(head, 1);
      else delete copy[head];
    } else {
      copy[head] = value;
    }
    return copy;
  }
  const child = copy[head] === undefined
    ? (typeof rest[0] === 'number' ? [] : {})
    : copy[head];
  copy[head] = setIn(child, rest, value);
  return copy;
}

/// Writes a value into the current draft, removing the key when it is empty.
function write(path, value, keep) {
  const entry = current();
  const next = blank(value) && keep !== true ? undefined : value;
  entry.draft = setIn(entry.draft, path, next);
  scheduleCheck();
}

/// A value for a newly added entry.
///
/// Required fields get an empty value of the right type so the shape is
/// right; optional ones are left out entirely, because the editor draws them
/// from the schema whether or not the document has them.
function blankFor(field) {
  switch (field.kind) {
    case 'localized':
    case 'localizedParagraph':
      return {en: ''};
    case 'number':
      return typeof field.min === 'number' ? field.min : 0;
    case 'boolean':
      return false;
    case 'choice':
      return field.options[0].value;
    case 'choiceList':
      return [];
    case 'coords':
      return [0, 0];
    case 'list':
      return [];
    case 'map':
      return {};
    case 'object': {
      const made = {};
      for (const child of field.fields) {
        if (child.required === true) made[child.key] = blankFor(child);
      }
      return made;
    }
    default:
      return '';
  }
}

// --- walking the schema ----------------------------------------------------

/// The chain of schema nodes from the document root down to [path].
///
/// Each link carries the label to show in the breadcrumb and the path that
/// returns to it, which is all the navigation needs.
function chainFor(file, path) {
  const document = schemaFor(file);
  const root = {kind: 'object', fields: document.fields, label: document.section};
  const links = [{label: document.section, node: root, path: [], root: true}];
  let node = root;
  const walked = [];
  for (const step of path) {
    walked.push(step);
    if (node.kind === 'object') {
      const field = node.fields.find((entry) => entry.key === step);
      if (!field) break;
      node = field;
      links.push({label: field.label, node: field, path: walked.slice()});
      continue;
    }
    if (node.kind === 'list') {
      node = node.of;
      const value = getIn(current().draft, walked);
      links.push({
        label: titleOf(node, value, step),
        node: node,
        path: walked.slice(),
        item: true,
      });
      continue;
    }
    break;
  }
  return links;
}

/// Reads a localised or plain value as one line of text.
function plainText(value) {
  if (value === null || value === undefined) return '';
  if (typeof value === 'object' && !Array.isArray(value)) {
    const held = value[state.lang];
    if (typeof held === 'string' && held !== '') return held;
    if (typeof value.en === 'string') return value.en;
    return '';
  }
  return String(value);
}

/// What one entry in a list is called, for its row and its breadcrumb.
function titleOf(node, value, index) {
  if (node.kind !== 'object' || value === null || typeof value !== 'object') {
    return plainText(value) || 'Entry ' + (index + 1);
  }
  const named = node.titleFrom ? plainText(value[node.titleFrom]) : '';
  return named || 'Entry ' + (index + 1);
}

function subtitleOf(node, value) {
  if (node.kind !== 'object' || !node.subtitleFrom) return '';
  if (value === null || typeof value !== 'object') return '';
  return plainText(value[node.subtitleFrom]);
}

// --- validation ------------------------------------------------------------

/// Asks the Worker whether the draft would be accepted.
///
/// The panel has no validator of its own on purpose. The one rule that has to
/// hold is that the panel never calls a document publishable when the Worker
/// would refuse it, and the only way to guarantee that is to ask the thing
/// that decides.
let checkTimer = null;
let outstanding = 0;

/// Marks the panel as having a check in flight.
///
/// Read off the body by the verification runs, so a scenario can wait for the
/// answer instead of sleeping for a guessed number of milliseconds. A test
/// that passes because the sleep was long enough is a test that will fail on a
/// slower machine for a reason nobody can reproduce.
function busy(delta) {
  outstanding += delta;
  if (outstanding > 0) document.body.dataset.checking = '1';
  else delete document.body.dataset.checking;
}

function scheduleCheck() {
  if (checkTimer !== null) clearTimeout(checkTimer);
  else busy(1);
  checkTimer = setTimeout(() => {
    checkTimer = null;
    busy(-1);
    check();
  }, 400);
}

async function check() {
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  const ticket = ++state.checking;
  busy(1);
  try {
    const response = await api('/v1/admin/validate', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        file: file,
        document: entry.draft,
        references: knownReferences(file),
      }),
    });
    const body = await response.json();
    if (ticket !== state.checking) return;
    if (!response.ok) throw new Error(body.error || 'Could not check the draft');
    state.issues.set(file, body);
    render();
    // The contract says a validated draft, so this is the moment it is known
    // to be one.
    if (state.rightPane === 'preview') sendDraft();
  } catch (error) {
    if (ticket !== state.checking) return;
    say(error.message, 'bad');
  } finally {
    busy(-1);
  }
}

/// The identifiers this panel can see in the documents it has loaded.
///
/// Sent with a check so a stop pointing at an application can be verified
/// even when that document is still the copy shipped with the app, which the
/// Worker has no way to read.
function knownReferences(file) {
  const wanted = {'career.json': ['apps.json']}[file];
  if (!wanted) return undefined;
  const sets = {};
  for (const name of wanted) {
    if (!state.docs.has(name)) continue;
    sets[name] = referencableEntries(name).map((entry) => entry.value);
  }
  return sets;
}

// --- stored media ----------------------------------------------------------

/// Everything the owner has uploaded, newest information first.
async function loadMedia() {
  try {
    const response = await api('/v1/admin/media');
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not read the library');
    state.media = body.media;
    state.mediaError = '';
  } catch (error) {
    state.media = state.media || [];
    state.mediaError = error.message;
  }
}

/// Sends one file, reporting how far it has got.
///
/// XMLHttpRequest rather than fetch, for the one thing it still does better:
/// it reports upload progress. A picture from a phone on a train takes long
/// enough that a control with no progress looks broken, and the owner's
/// answer to a control that looks broken is to press it again.
function sendFile(file, kind, onProgress) {
  return new Promise((resolve, reject) => {
    const path = kind === 'audio' ? '/v1/admin/media/audio' : '/v1/admin/media';
    const request = new XMLHttpRequest();
    request.open('POST', path);
    request.setRequestHeader('authorization', 'Bearer ' + state.token);
    request.setRequestHeader('content-type', file.type);
    request.upload.onprogress = (event) => {
      if (!event.lengthComputable) return;
      onProgress(event.loaded / event.total);
    };
    request.onload = () => {
      let body = {};
      try {
        body = JSON.parse(request.responseText);
      } catch (error) {
        body = {};
      }
      if (request.status === 401) return reject(new Error('The token was refused'));
      if (request.status >= 400) {
        return reject(new Error(body.error || 'The upload was refused'));
      }
      state.media = null;
      resolve(body);
    };
    request.onerror = () => reject(new Error('The upload could not be sent'));
    request.onabort = () => reject(new Error('The upload was cancelled'));
    request.send(file);
  });
}

/// Where a stored file is referred to, across every document loaded.
///
/// Deleting an image that a page is still pointing at leaves a broken
/// reference the owner will not find until someone tells him, so the library
/// says who is using a file before offering to remove it.
function usesOf(url) {
  const found = [];
  for (const document_ of SCHEMA.documents) {
    const entry = state.docs.get(document_.file);
    if (!entry) continue;
    walkFor(entry.draft, url, [], (path) => {
      found.push({file: document_.file, section: document_.section, path: path});
    });
  }
  return found;
}

function walkFor(value, wanted, path, found) {
  if (value === wanted) return found(path.join('.'));
  if (Array.isArray(value)) {
    value.forEach((entry, index) => walkFor(entry, wanted, path.concat([index]), found));
    return;
  }
  if (value !== null && typeof value === 'object') {
    for (const key of Object.keys(value)) {
      walkFor(value[key], wanted, path.concat([key]), found);
    }
  }
}

function issuesAt(pathText) {
  const held = state.issues.get(state.file);
  if (!held) return [];
  const errors = held.errors.filter((issue) => issue.path === pathText);
  const warnings = held.warnings.filter((issue) => issue.path === pathText);
  return errors
    .map((issue) => ({kind: 'error', message: issue.message}))
    .concat(warnings.map((issue) => ({kind: 'warn', message: issue.message})));
}

/// Whether anything at or below [pathText] is wrong, for a row's marker.
function troubleBelow(pathText) {
  const held = state.issues.get(state.file);
  if (!held) return 0;
  return held.errors.filter(
    (issue) => issue.path === pathText || issue.path.indexOf(pathText + '.') === 0,
  ).length;
}
`;
