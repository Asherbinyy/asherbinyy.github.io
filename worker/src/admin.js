/**
 * The panel the owner edits the site from.
 *
 * `15-ADMIN-AND-MEDIA.md` §7.4. Plain HTML and one script, served as a string
 * from the Worker, because this is a form over a JSON document used by exactly
 * one person and a framework here would be a second frontend to keep alive.
 *
 * It reads the shipped document straight from the site's own bundle, which
 * GitHub Pages serves with an open CORS header, and overlays anything already
 * published. So the editor always starts from what the site is actually
 * showing rather than from an empty box.
 *
 * Built for a phone first. The owner asked to be able to add a project with a
 * screenshot from his phone without an agent, so every control is a full-width
 * tap target and nothing depends on hover.
 */

/// Where the shipped documents live. Flutter nests its asset directory inside
/// its own asset root, which is why this path says `assets` twice.
const bundleBase = 'https://asherbinyy.github.io/assets/assets/content';

export function adminPage(siteOrigin) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="robots" content="noindex, nofollow">
<title>Nocturne — content</title>
<style>
  :root {
    --void: #121826;
    --surface: #1A2233;
    --raised: #232D40;
    --line: #33405A;
    --text: #EDF1F8;
    --muted: #97A3BA;
    --gold: #E3A93F;
    --alert: #D2694A;
    --ok: #45B8B2;
    color-scheme: dark;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--void);
    color: var(--text);
    font: 15px/1.5 ui-sans-serif, -apple-system, "Segoe UI", Roboto, sans-serif;
    padding: 0 0 96px;
  }
  header {
    position: sticky; top: 0; z-index: 5;
    background: var(--void);
    border-bottom: 1px solid var(--line);
    padding: 12px 16px;
    display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
  }
  h1 { font-size: 15px; margin: 0; font-weight: 600; letter-spacing: .02em; }
  main { padding: 16px; max-width: 760px; margin: 0 auto; }
  button {
    font: inherit; color: var(--text); background: var(--raised);
    border: 1px solid var(--line); border-radius: 8px;
    padding: 10px 14px; min-height: 44px; cursor: pointer;
  }
  button:hover { border-color: var(--gold); }
  button.primary { background: var(--gold); color: #17130A; border-color: var(--gold); font-weight: 600; }
  button.danger { color: var(--alert); }
  button.small { min-height: 36px; padding: 6px 10px; font-size: 13px; }
  input, textarea, select {
    font: inherit; width: 100%; color: var(--text);
    background: var(--surface); border: 1px solid var(--line);
    border-radius: 8px; padding: 10px 12px; min-height: 44px;
  }
  textarea { min-height: 88px; resize: vertical; }
  label { display: block; margin: 0 0 4px; color: var(--muted); font-size: 12px;
    text-transform: uppercase; letter-spacing: .08em; }
  .field { margin: 0 0 14px; }
  .tabs { display: flex; gap: 6px; overflow-x: auto; padding: 12px 16px 0; }
  .tabs button { white-space: nowrap; }
  .tabs button[aria-current="true"] { border-color: var(--gold); color: var(--gold); }
  .card {
    border: 1px solid var(--line); border-radius: 10px;
    padding: 14px; margin: 0 0 14px; background: var(--surface);
  }
  .card > .head {
    display: flex; gap: 8px; align-items: center;
    margin: 0 0 12px; flex-wrap: wrap;
  }
  .card > .head strong { flex: 1; min-width: 120px; }
  .warn {
    border-left: 3px solid var(--alert); background: rgba(210,105,74,.09);
    padding: 10px 12px; margin: 0 0 16px; border-radius: 0 8px 8px 0;
    font-size: 13px; color: var(--text);
  }
  .note { color: var(--muted); font-size: 13px; }
  .group {
    color: var(--gold); font-size: 12px; font-weight: 600;
    text-transform: uppercase; letter-spacing: .1em;
    margin: 18px 0 8px; padding-top: 12px; border-top: 1px solid var(--line);
  }
  .sub { margin: 0 0 6px; }
  .inline { display: flex; gap: 6px; margin: 0 0 6px; align-items: center; }
  .inline input { flex: 1; }
  .lang {
    display: block; color: var(--muted); font-size: 11px;
    letter-spacing: .06em; margin: 0 0 3px;
  }
  .bar {
    position: fixed; left: 0; right: 0; bottom: 0; z-index: 6;
    background: var(--surface); border-top: 1px solid var(--line);
    padding: 10px 16px calc(10px + env(safe-area-inset-bottom));
    display: flex; gap: 8px; align-items: center;
  }
  .bar .grow { flex: 1; }
  .diff { font: 13px/1.55 ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: pre-wrap; word-break: break-word; }
  .diff .added { color: var(--ok); }
  .diff .removed { color: var(--alert); }
  .thumb { max-width: 100%; border-radius: 8px; border: 1px solid var(--line); margin-top: 8px; }
  .hidden { display: none !important; }
  .status { font-size: 13px; color: var(--muted); }
  .status.bad { color: var(--alert); }
  .status.good { color: var(--ok); }
</style>
</head>
<body>
<header>
  <h1>Nocturne content</h1>
  <span class="grow" style="flex:1"></span>
  <span id="status" class="status"></span>
</header>

<section id="gate" style="padding:24px 16px;max-width:420px;margin:0 auto">
  <div class="field">
    <label for="token">Admin token</label>
    <input id="token" type="password" autocomplete="current-password"
           placeholder="The value of ADMIN_TOKEN">
  </div>
  <button class="primary" id="unlock" style="width:100%">Unlock</button>
  <p class="note">Held for this tab only, never written to disk.</p>
</section>

<div id="panel" class="hidden">
  <nav class="tabs" id="tabs"></nav>
  <main>
    <div id="warning" class="warn hidden"></div>
    <div id="editor"></div>
  </main>
  <div class="bar">
    <button id="diff">Review</button>
    <span class="grow"></span>
    <button id="withdraw" class="danger">Withdraw</button>
    <button id="publish" class="primary">Publish</button>
  </div>
</div>

<script type="module">
const SITE = ${JSON.stringify(siteOrigin)};
const BUNDLE = ${JSON.stringify(bundleBase)};
const FILES = ['profile.json', 'apps.json', 'career.json', 'education.json', 'interests.json'];

// The two documents a recruiter cross-checks against a CV. Editing them is
// allowed, but not without being told what they are.
const SENSITIVE = {
  'career.json': 'This is the work history a recruiter checks against your CV. Dates and employers here are claims about you.',
  'education.json': 'These are marks and qualifications. A number changed here is a claim, and publishing needs a source.',
};

let token = '';
let file = FILES[0];
let live = null;      // what the site shows right now
let draft = null;     // what is being edited

const el = (id) => document.getElementById(id);
const status = (text, kind = '') => {
  const node = el('status');
  node.textContent = text;
  node.className = 'status ' + kind;
};

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {authorization: 'Bearer ' + token, ...(options.headers ?? {})},
  });
  if (response.status === 401) throw new Error('Token refused');
  if (response.status === 429) throw new Error('Too many attempts; wait an hour');
  return response;
}

/// What the site is showing: the published document if there is one, else the
/// shipped bundle. Both are fetched, because the panel has to be able to show
/// the difference between them.
async function loadDocument(name) {
  const shipped = await fetch(BUNDLE + '/' + name).then((r) => r.json());
  // No Origin header set here: it is a forbidden header name, the browser
  // sets it itself, and writing one would only look like it was doing
  // something.
  const response = await fetch(SITE_CONTENT + '/' + name).catch(() => null);
  if (response && response.ok) {
    return {shipped, published: await response.json()};
  }
  return {shipped, published: null};
}
const SITE_CONTENT = '/v1/content';

// --- rendering -------------------------------------------------------------

/// Renders any JSON value as editable controls.
///
/// Shape-driven rather than schema-driven: the documents already describe
/// themselves, and a schema here would be a second copy of the one in
/// content_parser.dart to keep in step.
function renderValue(value, path, onChange) {
  if (Array.isArray(value)) return renderList(value, path, onChange);
  if (value !== null && typeof value === 'object') {
    return renderObject(value, path, onChange);
  }
  return renderScalar(value, path, onChange);
}

function renderScalar(value, path, onChange) {
  const wrap = document.createElement('div');
  wrap.className = 'field';
  const name = path[path.length - 1];
  const label = document.createElement('label');
  label.textContent = String(name);
  wrap.append(label);

  if (typeof value === 'boolean') {
    const box = document.createElement('input');
    box.type = 'checkbox';
    box.checked = value;
    box.style.width = 'auto';
    box.style.minHeight = '24px';
    box.onchange = () => onChange(path, box.checked);
    wrap.append(box);
    return wrap;
  }

  const long = typeof value === 'string' && value.length > 70;
  const input = document.createElement(long ? 'textarea' : 'input');
  if (!long) input.type = typeof value === 'number' ? 'number' : 'text';
  input.value = value === null ? '' : String(value);
  input.oninput = () => {
    if (typeof value === 'number') {
      const next = input.value === '' ? null : Number(input.value);
      onChange(path, Number.isNaN(next) ? value : next);
    } else {
      onChange(path, input.value);
    }
  };
  wrap.append(input);

  // Anything that looks like it points at an image gets an uploader and a
  // preview, which is the whole of "add a project with a screenshot".
  if (typeof value === 'string' && /image|cover|shot|art|photo|poster/i.test(String(name))) {
    wrap.append(imageControls(input, onChange, path));
  }
  return wrap;
}

function imageControls(input, onChange, path) {
  const holder = document.createElement('div');
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.accept = 'image/png,image/jpeg,image/webp';
  picker.style.marginTop = '8px';

  const preview = document.createElement('img');
  preview.className = 'thumb';
  const show = (src) => {
    if (!src) { preview.removeAttribute('src'); return; }
    preview.src = src;
  };
  show(input.value);

  picker.onchange = async () => {
    const chosen = picker.files && picker.files[0];
    if (!chosen) return;
    status('Uploading ' + chosen.name + '…');
    try {
      const response = await api('/v1/admin/media', {
        method: 'POST',
        headers: {'content-type': chosen.type},
        body: chosen,
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error ?? 'Upload refused');
      input.value = body.url;
      onChange(path, body.url);
      show(body.url);
      status('Uploaded ' + body.width + '×' + body.height, 'good');
    } catch (error) {
      status(error.message, 'bad');
    }
  };
  holder.append(picker, preview);
  return holder;
}

/// Whether this object is one piece of text in two languages.
function isLocalised(value) {
  const keys = Object.keys(value);
  return keys.length > 0 && keys.every((key) => key === 'en' || key === 'ar');
}

function renderObject(value, path, onChange) {
  const wrap = document.createElement('div');
  const name = path[path.length - 1];

  // A localised string is one idea in two languages, so it is labelled with
  // the field it belongs to rather than with "en" and "ar". Without this every
  // input on the profile form reads EN, AR, EN, AR and there is no way to tell
  // the name from the positioning statement.
  if (isLocalised(value)) {
    const group = document.createElement('div');
    group.className = 'field';
    const label = document.createElement('label');
    label.textContent = name === undefined ? 'text' : String(name);
    group.append(label);
    for (const key of ['en', 'ar']) {
      if (!(key in value)) continue;
      const line = document.createElement('div');
      line.className = 'sub';
      const tag = document.createElement('span');
      tag.className = 'lang';
      tag.textContent = key === 'en' ? 'English' : 'Arabic';
      const input = document.createElement(
        String(value[key] ?? '').length > 70 ? 'textarea' : 'input',
      );
      input.value = value[key] ?? '';
      if (key === 'ar') input.dir = 'rtl';
      input.oninput = () => onChange([...path, key], input.value);
      line.append(tag, input);
      group.append(line);
    }
    return group;
  }

  // Any other nested object gets a heading, so the shape of the document is
  // visible rather than being a flat run of inputs. An array index is not a
  // heading: the card it sits in already carries the entry's name, and
  // printing "0" above the fields is noise.
  if (name !== undefined && typeof name !== 'number') {
    const heading = document.createElement('div');
    heading.className = 'group';
    heading.textContent = String(name);
    wrap.append(heading);
  }
  for (const key of Object.keys(value)) {
    wrap.append(renderValue(value[key], [...path, key], onChange));
  }
  return wrap;
}

function renderList(items, path, onChange) {
  const wrap = document.createElement('div');
  const label = document.createElement('label');
  label.textContent = String(path[path.length - 1]) + ' — ' + items.length;
  wrap.append(label);

  // A list of short strings is a list of short strings. Giving each one a card
  // with reorder buttons and a nested field called "0" buries three characters
  // under forty pixels of chrome.
  const scalars = items.every(
    (item) => item === null || typeof item !== 'object',
  );
  if (scalars) {
    items.forEach((item, index) => {
      const line = document.createElement('div');
      line.className = 'inline';
      const input = document.createElement('input');
      input.value = item === null ? '' : String(item);
      input.oninput = () => {
        const next = [...items];
        next[index] = input.value;
        onChange(path, next);
      };
      const remove = document.createElement('button');
      remove.className = 'small danger';
      remove.type = 'button';
      remove.textContent = '×';
      remove.onclick = () => onChange(path, items.filter((_, at) => at !== index));
      line.append(input, remove);
      wrap.append(line);
    });
    const add = document.createElement('button');
    add.type = 'button';
    add.className = 'small';
    add.textContent = 'Add';
    add.onclick = () => onChange(path, [...items, '']);
    wrap.append(add);
    return wrap;
  }

  items.forEach((item, index) => {
    const card = document.createElement('div');
    card.className = 'card';
    const head = document.createElement('div');
    head.className = 'head';

    const title = document.createElement('strong');
    title.textContent = summarise(item, index);
    head.append(title);

    const move = (to) => () => {
      if (to < 0 || to >= items.length) return;
      const next = [...items];
      const [moved] = next.splice(index, 1);
      next.splice(to, 0, moved);
      onChange(path, next);
    };
    for (const [text, target] of [['↑', index - 1], ['↓', index + 1]]) {
      const button = document.createElement('button');
      button.className = 'small';
      button.type = 'button';
      button.textContent = text;
      button.onclick = move(target);
      head.append(button);
    }
    const remove = document.createElement('button');
    remove.className = 'small danger';
    remove.type = 'button';
    remove.textContent = 'Remove';
    remove.onclick = () => {
      if (!confirm('Remove "' + summarise(item, index) + '"?')) return;
      onChange(path, items.filter((_, at) => at !== index));
    };
    head.append(remove);

    card.append(head, renderValue(item, [...path, index], onChange));
    wrap.append(card);
  });

  if (items.length > 0) {
    const add = document.createElement('button');
    add.type = 'button';
    add.textContent = 'Add';
    // Shaped from an existing entry and emptied, so a new one has every field
    // the parser expects rather than whichever ones got typed.
    add.onclick = () => onChange(path, [...items, blankLike(items[0])]);
    wrap.append(add);
  }
  return wrap;
}

function blankLike(sample) {
  if (Array.isArray(sample)) return [];
  if (sample !== null && typeof sample === 'object') {
    return Object.fromEntries(
      Object.entries(sample).map(([key, value]) => [key, blankLike(value)]),
    );
  }
  if (typeof sample === 'number') return 0;
  if (typeof sample === 'boolean') return false;
  return '';
}

function summarise(item, index) {
  if (item === null || typeof item !== 'object') return String(item);
  for (const key of ['name', 'title', 'company', 'city', 'institution', 'id', 'label']) {
    const value = item[key];
    if (typeof value === 'string' && value) return value;
    if (value && typeof value === 'object' && typeof value.en === 'string') {
      return value.en;
    }
  }
  return 'Entry ' + (index + 1);
}

// --- editing ---------------------------------------------------------------

function setIn(root, path, value) {
  if (path.length === 0) return value;
  const [head, ...rest] = path;
  const copy = Array.isArray(root) ? [...root] : {...root};
  copy[head] = rest.length === 0 ? value : setIn(copy[head], rest, value);
  return copy;
}

function draw() {
  el('editor').replaceChildren(
    renderValue(draft, [], (path, value) => {
      draft = setIn(draft, path, value);
      draw();
    }),
  );
  const warning = el('warning');
  if (SENSITIVE[file]) {
    warning.textContent = SENSITIVE[file];
    warning.classList.remove('hidden');
  } else {
    warning.classList.add('hidden');
  }
}

// --- diffing ---------------------------------------------------------------

/// Every leaf that differs, as a list of paths. Used both for the review sheet
/// and to decide whether a source note is required.
function differences(before, after, path = []) {
  if (JSON.stringify(before) === JSON.stringify(after)) return [];
  const both = before !== null && after !== null &&
    typeof before === 'object' && typeof after === 'object';
  if (!both) return [{path: path.join('.'), before, after}];

  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  const out = [];
  for (const key of keys) {
    out.push(...differences(before?.[key], after?.[key], [...path, key]));
  }
  return out;
}

function changedNumbers(changes) {
  return changes.filter(
    (change) => typeof change.after === 'number' || typeof change.before === 'number',
  );
}

function review() {
  const changes = differences(live, draft);
  if (changes.length === 0) {
    status('Nothing changed', '');
    return null;
  }
  const lines = changes.map(
    (change) =>
      change.path + '\\n' +
      '  - ' + JSON.stringify(change.before) + '\\n' +
      '  + ' + JSON.stringify(change.after),
  );
  alert('Against what the site shows now:\\n\\n' + lines.join('\\n\\n'));
  return changes;
}

// --- publishing ------------------------------------------------------------

async function publish() {
  const changes = differences(live, draft);
  if (changes.length === 0) {
    status('Nothing to publish', '');
    return;
  }

  // Section 7.5: a number is a claim, and a claim needs a source. Asked for
  // at the moment of publishing, when the owner still knows why he changed it,
  // and recorded by the Worker rather than pushed into the document.
  let note = '';
  const numbers = changedNumbers(changes);
  if (numbers.length > 0) {
    const asked =
      'These figures changed:\\n\\n' +
      numbers.map((n) => '  ' + n.path + ': ' + n.before + ' → ' + n.after).join('\\n') +
      '\\n\\nWhere does the new figure come from? A transcript, a payslip, a store listing.';
    note = (prompt(asked) ?? '').trim();
    if (!note) {
      status('A figure cannot be published without a source', 'bad');
      return;
    }
  }

  status('Publishing…');
  try {
    const response = await api('/v1/admin/content/' + file, {
      method: 'PUT',
      headers: {'content-type': 'application/json', 'x-change-note': encodeURIComponent(note)},
      body: JSON.stringify(draft),
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error ?? 'Refused');
    live = JSON.parse(JSON.stringify(draft));
    status('Published ' + file, 'good');
  } catch (error) {
    status(error.message, 'bad');
  }
}

async function withdraw() {
  if (!confirm('Withdraw ' + file + '? The site goes back to its shipped copy.')) return;
  status('Withdrawing…');
  try {
    const response = await api('/v1/admin/content/' + file, {method: 'DELETE'});
    if (!response.ok) throw new Error('Refused');
    await open(file);
    status('Withdrawn; the site uses its bundle', 'good');
  } catch (error) {
    status(error.message, 'bad');
  }
}

// --- wiring ----------------------------------------------------------------

async function open(name) {
  file = name;
  // Reflected in the address so a reload on a phone comes back to the document
  // being edited rather than to the first one.
  if (location.hash.slice(1) !== name) history.replaceState(null, '', '#' + name);
  status('Loading ' + name + '…');
  try {
    const {shipped, published} = await loadDocument(name);
    live = published ?? shipped;
    draft = JSON.parse(JSON.stringify(live));
    draw();
    status(published ? 'Published copy' : 'Shipped copy', '');
  } catch (error) {
    status('Could not load ' + name, 'bad');
  }
  for (const button of el('tabs').children) {
    button.setAttribute('aria-current', String(button.dataset.file === name));
  }
}

function buildTabs() {
  const tabs = el('tabs');
  tabs.replaceChildren();
  for (const name of FILES) {
    const button = document.createElement('button');
    button.type = 'button';
    button.dataset.file = name;
    button.textContent = name.replace('.json', '');
    button.onclick = () => open(name);
    tabs.append(button);
  }
}

el('unlock').onclick = async () => {
  token = el('token').value.trim();
  if (!token) return;
  status('Checking…');
  try {
    const response = await api('/v1/admin/content');
    if (!response.ok) throw new Error('Token refused');
    sessionStorage.setItem('nocturne.admin', token);
    el('gate').classList.add('hidden');
    el('panel').classList.remove('hidden');
    buildTabs();
    await open(file);
  } catch (error) {
    status(error.message, 'bad');
  }
};
el('token').onkeydown = (event) => {
  if (event.key === 'Enter') el('unlock').click();
};
el('diff').onclick = review;
el('publish').onclick = publish;
el('withdraw').onclick = withdraw;

const wanted = decodeURIComponent(location.hash.slice(1));
if (FILES.includes(wanted)) file = wanted;

const remembered = sessionStorage.getItem('nocturne.admin');
if (remembered) {
  el('token').value = remembered;
  el('unlock').click();
}
</script>
</body>
</html>`;
}
