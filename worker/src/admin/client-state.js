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
  file: SCHEMA.documents[0].file,
  path: [],
  lang: 'en',
  docs: new Map(),
  issues: new Map(),
  checking: 0,
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
  if (response.status === 401) throw new Error('The token was refused');
  if (response.status === 429) {
    throw new Error('Too many failed attempts; the endpoint is closed for the hour');
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

function scheduleCheck() {
  if (checkTimer !== null) clearTimeout(checkTimer);
  checkTimer = setTimeout(check, 400);
}

async function check() {
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  const ticket = ++state.checking;
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
  } catch (error) {
    if (ticket !== state.checking) return;
    say(error.message, 'bad');
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
