/**
 * Navigation, the editor panel, the outline and the buttons at the bottom.
 *
 * The layout is the one the owner asked for: sections down the left, the
 * thing being edited in the middle, and a panel on the right. The right-hand
 * panel is **not** the site. It says so, in the panel, because the contract
 * in `20-APP-ADMIN-CONTRACT.md` is explicit that a differently-styled admin
 * mock-up must not be presented as a live preview. It renders the draft as an
 * outline so there is something honest to look at and something for the real
 * preview adapter to replace when Codex lands it.
 */

export const clientApp = `
// --- navigation ------------------------------------------------------------

function go(file, path) {
  state.file = file;
  state.path = path || [];
  const hash = '#' + file + (state.path.length ? '/' + state.path.join('/') : '');
  if (location.hash !== hash) history.replaceState(null, '', hash);
  render();
  el('editorPane').scrollTop = 0;
  check();
}

function readHash() {
  const raw = decodeURIComponent(location.hash.slice(1));
  if (!raw) return null;
  const parts = raw.split('/');
  const file = parts[0];
  if (!schemaFor(file)) return null;
  const path = parts.slice(1).map((step) => (/^\\d+$/.test(step) ? Number(step) : step));
  return {file: file, path: path};
}

// --- rendering -------------------------------------------------------------

/// Redraws the panel, putting the caret back where the owner left it.
///
/// Everything is rebuilt on each change because the alternative is a
/// diffing layer, and this is one form for one person. The caret is restored
/// by hand because a validation result arriving mid-sentence must not throw
/// the owner out of the box he is typing in.
function render() {
  const active = document.activeElement;
  const id = active && active.id ? active.id : null;
  let start = null;
  let end = null;
  try {
    start = active ? active.selectionStart : null;
    end = active ? active.selectionEnd : null;
  } catch (error) {
    start = null;
  }

  renderRail();
  renderEditor();
  renderOutline();
  renderBar();

  if (id) {
    const back = document.getElementById(id);
    if (back && back !== document.activeElement) {
      back.focus();
      if (start !== null && back.setSelectionRange) {
        try {
          back.setSelectionRange(start, end);
        } catch (error) {
          // A number or email input refuses a selection range. Focus is enough.
        }
      }
    }
  }
}

function renderRail() {
  const rail = el('rail');
  rail.replaceChildren();
  rail.append(node('div', 'railHead', 'Content'));
  for (const document_ of SCHEMA.documents) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'section';
    button.setAttribute('aria-current', state.file === document_.file ? 'page' : 'false');
    button.append(node('span', 'name', document_.section));
    const pip = node('span', 'pip');
    pip.hidden = !dirty(document_.file);
    pip.title = 'Unsaved changes';
    if (!pip.hidden) button.setAttribute('aria-describedby', 'unsavedHint');
    button.append(pip);
    button.onclick = () => go(document_.file, []);
    rail.append(button);
  }
  const hint = node('span', null, 'has unsaved changes');
  hint.id = 'unsavedHint';
  hint.hidden = true;
  rail.append(hint);
}

/// The path from the document down to whatever is open, as links back.
function crumbLinks() {
  const links = chainFor(state.file, state.path);
  const document_ = schemaFor(state.file);
  return links.filter((link, index) => {
    if (index === 0) return true;
    // A document whose whole content is one list does not need a crumb saying
    // so: "Work > Applications > Tripster" reads as one step too many.
    if (link.node.kind === 'list' && document_.fields.length === 1) return false;
    return true;
  });
}

function renderEditor() {
  const pane = el('editor');
  pane.replaceChildren();
  const entry = current();
  if (!entry) return;
  const document_ = schemaFor(state.file);
  const links = crumbLinks();
  const here = links[links.length - 1];

  const crumbs = node('ol', 'crumbs');
  links.forEach((link, index) => {
    const item = document.createElement('li');
    if (index === links.length - 1) {
      const last = node('span', 'here', link.label);
      last.setAttribute('aria-current', 'true');
      item.append(last);
    } else {
      const button = document.createElement('button');
      button.type = 'button';
      button.textContent = link.label;
      button.onclick = () => go(state.file, link.path);
      item.append(button);
    }
    crumbs.append(item);
  });
  const wrapper = node('nav');
  wrapper.setAttribute('aria-label', 'Breadcrumb');
  wrapper.append(crumbs);
  pane.append(wrapper);

  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, here.label));
  if (here.root === true && document_.blurb) {
    titles.append(node('p', null, document_.blurb));
  }
  head.append(titles, languageTabs());
  pane.append(head);

  if (here.root === true && document_.warning) {
    pane.append(node('div', 'warn', document_.warning));
  }

  const chain = chainFor(state.file, state.path);
  const node_ = chain[chain.length - 1].node;
  const value = state.path.length === 0
    ? entry.draft
    : getIn(entry.draft, state.path);

  if (node_.kind === 'object') {
    for (const field of node_.fields) {
      pane.append(control(field, (value || {})[field.key], state.path.concat([field.key])));
    }
  } else {
    pane.append(control(node_, value, state.path));
  }
}

/// English or Arabic, stacked, switching every field at once.
function languageTabs() {
  const tabs = node('div', 'langTabs');
  tabs.setAttribute('role', 'tablist');
  tabs.setAttribute('aria-orientation', 'vertical');
  tabs.setAttribute('aria-label', 'Editing language');
  const languages = [
    {code: 'en', label: 'English'},
    {code: 'ar', label: 'Arabic'},
  ];
  for (const language of languages) {
    const button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('role', 'tab');
    button.id = 'lang-' + language.code;
    button.setAttribute('aria-selected', String(state.lang === language.code));
    button.tabIndex = state.lang === language.code ? 0 : -1;
    button.textContent = language.label;
    button.onclick = () => {
      state.lang = language.code;
      render();
    };
    button.onkeydown = (event) => {
      if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
      event.preventDefault();
      state.lang = state.lang === 'en' ? 'ar' : 'en';
      render();
      const moved = el('lang-' + state.lang);
      if (moved) moved.focus();
    };
    tabs.append(button);
  }
  return tabs;
}

/// The draft, read back as an outline.
///
/// Labelled as a draft outline and nothing else. It is not the site, it does
/// not use the site's components, and calling it a preview would be the exact
/// substitution the integration contract forbids.
function renderOutline() {
  const pane = el('outline');
  pane.replaceChildren();
  const entry = current();
  if (!entry) return;
  const document_ = schemaFor(state.file);
  const open = state.path.length > 0 ? state.path[0] : null;

  for (const field of document_.fields) {
    const value = entry.draft[field.key];
    const block = node('div', 'o' + (field.key === open ? ' on' : ''));
    block.append(node('span', 'k', field.label));
    const lines = outlineLines(field, value);
    if (lines.length === 0) {
      const line = node('span', 'v none', 'Not set');
      block.append(line);
    } else {
      for (const text of lines) {
        const line = node('span', 'v', text);
        // Each line decides its own direction from its own first letter. The
        // editing language does not: a biography with no Arabic is English
        // text, and laying it out right to left puts the full stop in front
        // of the sentence.
        line.dir = 'auto';
        block.append(line);
      }
    }
    pane.append(block);
  }
}

function outlineLines(field, value) {
  if (value === undefined || value === null) return [];
  if (field.kind === 'list') {
    if (!Array.isArray(value) || value.length === 0) return [];
    if (field.of.kind === 'object') {
      return value.map((item, index) => '- ' + titleOf(field.of, item, index));
    }
    return [value.map((item) => plainText(item)).join(', ')];
  }
  if (field.kind === 'object') {
    return field.fields
      .filter((child) => value[child.key] !== undefined && value[child.key] !== null)
      .map((child) => child.label + ': ' + plainText(value[child.key]));
  }
  if (field.kind === 'boolean') return [value === true ? 'Yes' : 'No'];
  const text = plainText(value);
  return text === '' ? [] : [text];
}

function renderBar() {
  const entry = current();
  const issues = state.issues.get(state.file);
  const changes = entry ? countChanges(entry) : 0;
  el('changeCount').textContent = changes === 0
    ? 'No changes on this page'
    : changes + (changes === 1 ? ' change' : ' changes') + ' not published';

  const problems = issues ? issues.errors.length : 0;
  const badge = el('problemCount');
  badge.hidden = problems === 0;
  badge.className = 'count bad';
  badge.textContent = problems + (problems === 1 ? ' problem' : ' problems');

  el('publish').disabled = changes === 0 || problems > 0;
  el('review').disabled = changes === 0;
  el('withdraw').disabled = entry ? entry.source !== 'published' : true;
  el('source').textContent = entry
    ? (entry.source === 'published' ? 'Showing your published copy' : 'Showing the copy shipped with the app')
    : '';
}

/// How many separate values differ from what the site shows.
function countChanges(entry) {
  if (JSON.stringify(entry.live) === JSON.stringify(entry.draft)) return 0;
  return countLeaves(entry.live, entry.draft);
}

function countLeaves(before, after) {
  if (JSON.stringify(before) === JSON.stringify(after)) return 0;
  const objects = before && after && typeof before === 'object' &&
    typeof after === 'object';
  if (!objects) return 1;
  const keys = new Set(Object.keys(before).concat(Object.keys(after)));
  let total = 0;
  for (const key of keys) total += countLeaves(before[key], after[key]);
  return total;
}

// --- the buttons at the bottom ---------------------------------------------

function openSheet(title, build) {
  const sheet = el('sheet');
  el('sheetTitle').textContent = title;
  const body = el('sheetBody');
  body.replaceChildren();
  build(body);
  sheet.showModal();
}

async function review() {
  const entry = current();
  say('Checking the draft...');
  try {
    const response = await api('/v1/admin/review', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({\n        file: state.file,\n        document: entry.draft,\n        references: knownReferences(state.file),\n      }),
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not review the draft');
    state.issues.set(state.file, {errors: body.errors, warnings: body.warnings});
    render();
    say('');
    openSheet('Review ' + schemaFor(state.file).section, (into) => {
      into.append(node(
        'p',
        'note',
        'Against what the site is showing now. Nothing here has been published.',
      ));
      if (body.changes.length === 0) into.append(node('p', null, 'Nothing has changed.'));
      for (const change of body.changes) {
        const block = node('div', 'group');
        block.append(node('h3', null, change.path));
        block.append(node('p', 'diff removed', '- ' + JSON.stringify(change.before)));
        block.append(node('p', 'diff added', '+ ' + JSON.stringify(change.after)));
        into.append(block);
      }
      if (body.claims.length > 0) {
        const block = node('div', 'warn');
        block.append(node(
          'p',
          null,
          'These are claims about you. Publishing them asks for a source:',
        ));
        for (const claim of body.claims) {
          block.append(node('p', null, claim.label + ': ' + JSON.stringify(claim.was) +
            ' becomes ' + JSON.stringify(claim.value)));
        }
        into.append(block);
      }
      for (const issue of body.errors) {
        into.append(node('p', 'issue', issue.path + ': ' + issue.message));
      }
      for (const issue of body.warnings) {
        into.append(node('p', 'issue warn', issue.path + ': ' + issue.message));
      }
    });
  } catch (error) {
    say(error.message, 'bad');
  }
}

async function publish() {
  const entry = current();
  say('Checking the draft...');
  let review_;
  try {
    const response = await api('/v1/admin/review', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({\n        file: state.file,\n        document: entry.draft,\n        references: knownReferences(state.file),\n      }),
    });
    review_ = await response.json();
    if (!response.ok) throw new Error(review_.error || 'Could not check the draft');
  } catch (error) {
    return say(error.message, 'bad');
  }
  state.issues.set(state.file, {errors: review_.errors, warnings: review_.warnings});
  render();
  if (review_.errors.length > 0) {
    return say('Fix the problems on this page before publishing', 'bad');
  }
  // Whether there is anything to do is the panel's own question: it holds
  // both the draft and the copy the site is showing, which on a first publish
  // is the bundle the Worker cannot read.
  if (countChanges(entry) === 0) return say('Nothing to publish');

  // A figure is a claim, and a claim needs a source. Asked for at the moment
  // of publishing, while the owner still knows why he changed it. The list
  // comes from the schema, so a figure written as text -- "5+", "50%
  // retention lift" -- is caught, which the old numeric check was not.
  let note = '';
  if (review_.claims.length > 0) {
    const asked = 'These claims changed:\\n\\n' +
      review_.claims
        .map((claim) => '  ' + claim.label + ': ' +
          JSON.stringify(claim.was) + ' -> ' + JSON.stringify(claim.value))
        .join('\\n') +
      '\\n\\nWhere does the new figure come from? A transcript, a payslip, a store listing.';
    note = (prompt(asked) || '').trim();
    if (!note) return say('A claim cannot be published without a source', 'bad');
  }

  say('Publishing ' + schemaFor(state.file).section + '...');
  try {
    const response = await api('/v1/admin/content/' + state.file, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        'x-change-note': encodeURIComponent(note),
      },
      body: JSON.stringify(entry.draft),
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'The publish was refused');
    entry.live = JSON.parse(JSON.stringify(entry.draft));
    entry.source = 'published';
    render();
    say('Published ' + schemaFor(state.file).section, 'good');
  } catch (error) {
    say(error.message, 'bad');
  }
}

async function withdraw() {
  const section = schemaFor(state.file).section;
  if (!confirm('Withdraw ' + section + '? The site goes back to the copy shipped with the app.')) {
    return;
  }
  say('Withdrawing...');
  try {
    const response = await api('/v1/admin/content/' + state.file, {method: 'DELETE'});
    if (!response.ok) throw new Error('The withdrawal was refused');
    state.docs.delete(state.file);
    await ensure(state.file);
    render();
    say('Withdrawn. The site uses the copy in its bundle.', 'good');
  } catch (error) {
    say(error.message, 'bad');
  }
}

// --- starting up -----------------------------------------------------------

async function unlock() {
  state.token = el('token').value.trim();
  if (!state.token) return;
  say('Checking...');
  try {
    const response = await api('/v1/admin/content');
    if (!response.ok) throw new Error('The token was refused');
    sessionStorage.setItem('portfolio.admin', state.token);
    document.body.classList.remove('locked');
    el('gate').hidden = true;
    el('frame').classList.add('on');
    say('Loading your content...');
    // Every document, not just the one being opened: the drafts have to exist
    // for the rail to show which pages have unsaved work, and a stop pointing
    // at an application cannot be checked against a document nobody loaded.
    await Promise.all(SCHEMA.documents.map((entry) => ensure(entry.file)));
    const wanted = readHash();
    if (wanted) {
      state.file = wanted.file;
      state.path = wanted.path;
    }
    render();
    say('');
    await check();
  } catch (error) {
    say(error.message, 'bad');
    el('token').focus();
  }
}

el('unlock').onclick = unlock;
el('token').onkeydown = (event) => {
  if (event.key === 'Enter') unlock();
};
el('review').onclick = review;
el('publish').onclick = publish;
el('withdraw').onclick = withdraw;
el('sheetClose').onclick = () => el('sheet').close();
el('previewToggle').onclick = () => {
  const showing = document.body.classList.toggle('showPreview');
  el('previewToggle').setAttribute('aria-pressed', String(showing));
};

window.addEventListener('beforeunload', (event) => {
  if (!anyDirty()) return;
  event.preventDefault();
  event.returnValue = '';
});

const remembered = sessionStorage.getItem('portfolio.admin');
if (remembered) {
  el('token').value = remembered;
  unlock();
} else {
  el('token').focus();
}
`;
